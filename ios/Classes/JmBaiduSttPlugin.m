//识别
#import "JmBaiduSttPlugin.h"
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"
//唤醒
#import "BDSWakeupDefines.h"
#import "BDSWakeupParameters.h"
#import <AVKit/AVKit.h>
#import <math.h>

@interface JmBaiduSttPlugin ()
        <
        BDSClientASRDelegate,
        BDSClientWakeupDelegate,
        FlutterStreamHandler
        >
@property(nonatomic, copy) FlutterEventSink eventSink;
@property(strong, nonatomic) BDSEventManager *wakeUpManager;
@property(strong, nonatomic) BDSEventManager *commandManager;
@property(nonatomic, assign) BOOL isWakeUping;
@property(nonatomic, assign) BOOL isWakeUpStarted;

// ASR 生命周期状态：用于避免快速 stop/start 导致 “engine is busy”
@property(nonatomic, assign) BOOL isAsrRunning;
@property(nonatomic, assign) BOOL isAsrStopping;
@property(nonatomic, assign) BOOL pendingAsrStart;
@property(nonatomic, strong) id pendingWakeWord;
@property(nonatomic, assign) NSInteger asrBusyRetryCount;

@property(nonatomic, strong) id routeChangeObserver;
@end

@implementation JmBaiduSttPlugin

- (NSString *)jm_resourcePathForName:(NSString *)name ofType:(NSString *)type {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    if (path.length > 0) {
        return path;
    }

    NSBundle *classBundle = [NSBundle bundleForClass:[self class]];
    path = [classBundle pathForResource:name ofType:type];
    if (path.length > 0) {
        return path;
    }

    NSArray < NSString * > *bundleNames = @[@"jm_baidu_stt_plugin", @"BDSClientResources",
                                            @"BDSClientEASRResources"];
    for (NSString *bundleName in bundleNames) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
        if (bundlePath.length == 0) {
            continue;
        }
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        if (!bundle) {
            continue;
        }
        path = [bundle pathForResource:name ofType:type];
        if (path.length > 0) {
            return path;
        }
    }

    return nil;
}

- (void)jm_startAsrIfPossible {
    if (!self.commandManager) {
        return;
    }
    if (self.isAsrRunning || self.isAsrStopping) {
        return;
    }

    // 若正在处理 busy 重试流程，则不要被新的 start 打断
    if (self.asrBusyRetryCount > 0) {
        self.pendingAsrStart = YES;
        return;
    }

    self.isAsrRunning = YES;

    id wakeWord = self.pendingWakeWord;
    if (wakeWord && ![wakeWord isKindOfClass:[NSNull class]]) {
        [self.commandManager setParameter:wakeWord forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
    }
    self.pendingWakeWord = nil;

    [self.commandManager sendCommand:BDS_ASR_CMD_START];
    NSLog(@"开始语音识别");
}

- (void)jm_markAsrIdleAndMaybeRestart {
    self.isAsrRunning = NO;
    self.isAsrStopping = NO;
    self.asrBusyRetryCount = 0;

    if (self.pendingAsrStart) {
        self.pendingAsrStart = NO;
        // 让底层引擎有时间完成状态切换，避免立刻 start 仍然 busy
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
                    [self jm_startAsrIfPossible];
                });
    }
}

- (void)jm_retryAsrStartAfterBusy {
    // 简单指数退避：0.3s, 0.6s, 1.2s, 2.4s
    NSTimeInterval delay = 0.3 * pow(2.0, MAX(0, self.asrBusyRetryCount - 1));
    delay = MIN(delay, 2.4);

    self.pendingAsrStart = YES;
    self.isAsrRunning = NO;
    self.isAsrStopping = YES;

    // 先 cancel 一把，让引擎尽快回到空闲态
    if (self.commandManager) {
        [self.commandManager sendCommand:BDS_ASR_CMD_CANCEL];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                self.isAsrStopping = NO;
                [self jm_startAsrIfPossible];
            });
}

+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    JmBaiduSttPlugin *instance = [[JmBaiduSttPlugin alloc] init];
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"jm_baidu_stt_plugin"
                  binaryMessenger:[registrar messenger]];
    FlutterEventChannel *changingChannel = [FlutterEventChannel eventChannelWithName:@"jm_baidu_stt_plugin/event" binaryMessenger:[registrar messenger]];

    [changingChannel setStreamHandler:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.routeChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(
                NSNotification *_Nonnull note) {
            NSDictionary *interuptionDict = note.userInfo;
            NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
            switch (routeChangeReason) {
                case AVAudioSessionRouteChangeReasonCategoryChange: {
                    NSLog(@"[AVAudioSession sharedInstance].category = %@",
                          [AVAudioSession sharedInstance].category);
                    //让录音时视频等播放有声音
                    if ([[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
                        if (self.isWakeUping) { return; }
                        if ([self hasHeadset]) { return; }
                        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
                    } else {
                        if (self.isWakeUpStarted &&
                            [[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayback]) {
                            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
                        }
                    }
                }
                    break;
                case AVAudioSessionRouteChangeReasonNewDeviceAvailable: {
                    NSLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
                    //插入耳机时关闭扬声器播放
                    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
                }
                    break;
                case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
                    NSLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
                    //拔出耳机时的处理为开启扬声器播放
                    if ([[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
                        if (self.isWakeUping) { return; }
                        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
                    }
                }
                    break;

                default:
                    break;
            }
        }];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"create" isEqualToString:call.method]) {
        NSInteger type = [[call.arguments valueForKey:@"type"] integerValue];
        NSString *appId = [call.arguments valueForKey:@"appId"];
        NSString *appKey = [call.arguments valueForKey:@"appKey"];
        NSString *appSecret = [call.arguments valueForKey:@"appSecret"];
        if (type == 0) {
            //识别
            self.commandManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
            [self.commandManager setParameter:@[appKey, appSecret] forKey:BDS_ASR_API_SECRET_KEYS];
            [self.commandManager setParameter:appId forKey:BDS_ASR_OFFLINE_APP_CODE];

            // Debug logs (demo uses Trace for easier troubleshooting)
#if DEBUG
            [self.commandManager setParameter:@(EVRDebugLogLevelTrace) forKey:BDS_ASR_DEBUG_LOG_LEVEL];
#endif

            // 固定采样率为 16K
            [self.commandManager setParameter:@(EVoiceRecognitionRecordSampleRate16K) forKey:BDS_ASR_SAMPLE_RATE];

            // 识别语言（demo 默认普通话）
            NSNumber *language = [call.arguments valueForKey:@"language"];
            if (!language || [language isKindOfClass:[NSNull class]]) {
                language = @(EVoiceRecognitionLanguageChinese);
            }
            [self.commandManager setParameter:language forKey:BDS_ASR_LANGUAGE];

            // 产品 ID（demo 里必须配置，否则可能没有 results_recognition 返回）
            NSString *productId = [call.arguments valueForKey:@"productId"];
            if (!productId || [productId isKindOfClass:[NSNull class]] || productId.length == 0) {
                productId = @"1537";
            }
            [self.commandManager setParameter:productId forKey:BDS_ASR_PRODUCT_ID];

            // 在线超时（Error Domain=31 timeout）在弱网/受限网络下较常见。
            // demo 默认在线识别；并行模式（在线 + 离线）需要额外离线资源兜底。
            NSNumber *strategy = [call.arguments valueForKey:@"strategy"];
            if (!strategy || [strategy isKindOfClass:[NSNull class]]) {
                strategy = @(EVR_STRATEGY_ONLINE);
            }
            [self.commandManager setParameter:strategy forKey:BDS_ASR_STRATEGY];

            // 并行模式（在线 + 离线）才需要配置离线输入法引擎
            if ([strategy integerValue] == EVR_STRATEGY_BOTH) {
                NSNumber *offlineEngineType = [call.arguments valueForKey:@"offlineEngineType"];
                if (!offlineEngineType || [offlineEngineType isKindOfClass:[NSNull class]]) {
                    offlineEngineType = @(EVR_OFFLINE_ENGINE_INPUT);
                }
                [self.commandManager setParameter:offlineEngineType forKey:BDS_ASR_OFFLINE_ENGINE_TYPE];

                NSString *offlineDat = [call.arguments valueForKey:@"offlineDatPath"];
                if (!offlineDat || [offlineDat isKindOfClass:[NSNull class]] ||
                    offlineDat.length == 0) {
                    offlineDat = [self jm_resourcePathForName:@"bds_easr_input_model" ofType:@"dat"];
                }
                if (offlineDat.length > 0) {
                    [self.commandManager setParameter:offlineDat forKey:BDS_ASR_OFFLINE_ENGINE_DAT_FILE_PATH];
                } else {
                    NSLog(@"[jm_baidu_stt_plugin] Missing resource: bds_easr_input_model.dat (offline fallback disabled)");
                }

                NSString *offlineLicense = [self jm_resourcePathForName:@"bds_license" ofType:@"dat"];
                if (offlineLicense.length > 0) {
                    [self.commandManager setParameter:offlineLicense forKey:BDS_ASR_OFFLINE_LICENSE_FILE_PATH];
                } else {
                    NSLog(@"[jm_baidu_stt_plugin] Missing resource: bds_license.dat");
                }
            }

            // 在线识别默认走 HTTPS，避免某些网络/ATS 环境下 cleartext HTTP 连接超时。
            // 可从 Dart 侧传入 serverUrl/productId 覆盖。
            NSString *serverUrl = [call.arguments valueForKey:@"serverUrl"];
            if (!serverUrl || [serverUrl isKindOfClass:[NSNull class]] || serverUrl.length == 0) {
                serverUrl = @"https://vop.baidu.com/server_api";
            }
            [self.commandManager setParameter:serverUrl forKey:BDS_ASR_SERVER_URL];

            NSString *modelVAD_filepath = [self jm_resourcePathForName:@"bds_easr_basic_model" ofType:@"dat"];
            NSString *mfeDnn = [self jm_resourcePathForName:@"bds_easr_mfe_dnn" ofType:@"dat"];
            if (mfeDnn.length > 0) {
                [self.commandManager setParameter:mfeDnn forKey:BDS_ASR_MFE_DNN_DAT_FILE];
            } else {
                NSLog(@"[jm_baidu_stt_plugin] Missing resource: bds_easr_mfe_dnn.dat");
            }

            NSString *mfeCmvn = [self jm_resourcePathForName:@"bds_easr_mfe_cmvn" ofType:@"dat"];
            if (mfeCmvn.length > 0) {
                [self.commandManager setParameter:mfeCmvn forKey:BDS_ASR_MFE_CMVN_DAT_FILE];
            } else {
                NSLog(@"[jm_baidu_stt_plugin] Missing resource: bds_easr_mfe_cmvn.dat");
            }

            // 端点检测（二选一）
            // - demo 默认使用 DNN MFE（不打开 modelVAD）
            // - 需要 modelVAD 时再开启（并确保 bds_easr_basic_model.dat 可用）
            NSNumber *enableModelVAD = [call.arguments valueForKey:@"enableModelVAD"];
            BOOL shouldEnableModelVAD =
                    enableModelVAD && ![enableModelVAD isKindOfClass:[NSNull class]]
                    ? [enableModelVAD boolValue] : NO;
            if (shouldEnableModelVAD) {
                if (modelVAD_filepath.length > 0) {
                    [self.commandManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
                    [self.commandManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
                } else {
                    NSLog(@"[jm_baidu_stt_plugin] Missing resource: bds_easr_basic_model.dat (modelVAD disabled)");
                    [self.commandManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_MODEL_VAD];
                }
            } else {
                [self.commandManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_MODEL_VAD];
            }
            [self.commandManager setDelegate:self];

            if ([strategy integerValue] == EVR_STRATEGY_BOTH) {
                [self.commandManager sendCommand:BDS_ASR_CMD_LOAD_ENGINE];
            }
            NSLog(@"语音识别创建成功");
        } else if (type == 1) {
            //唤醒
            self.wakeUpManager = [BDSEventManager createEventManagerWithName:BDS_WAKEUP_NAME];
            //配置key
            [self.wakeUpManager setParameter:appId forKey:BDS_WAKEUP_APP_CODE];
            [self.wakeUpManager setParameter:@[appKey, appSecret] forKey:BDS_ASR_API_SECRET_KEYS];
            [self.wakeUpManager setParameter:appId forKey:BDS_ASR_OFFLINE_APP_CODE];

            NSString *offlineLicense = [self jm_resourcePathForName:@"bds_license" ofType:@"dat"];
            if (offlineLicense.length > 0) {
                [self.wakeUpManager setParameter:offlineLicense forKey:BDS_ASR_OFFLINE_LICENSE_FILE_PATH];
            }

            NSString *dat = [self jm_resourcePathForName:@"bds_easr_basic_model" ofType:@"dat"];
            NSString *wakeupWords = [self jm_resourcePathForName:@"bds_easr_wakeup_words" ofType:@"dat"];
            [self.wakeUpManager setParameter:dat forKey:BDS_WAKEUP_DAT_FILE_PATH];
            [self.wakeUpManager setParameter:wakeupWords forKey:BDS_WAKEUP_WORDS_FILE_PATH];
            [self.wakeUpManager setDelegate:self];
            NSLog(@"语音唤醒创建成功");
        }
        result(nil);
    } else if ([@"startRecognition" isEqualToString:call.method]) {
        if (!self.commandManager) {
            result([FlutterError errorWithCode:@"uninitialized"
                                       message:@"Call create(type: BaiduSpeechBuildType.asr) before startRecognition."
                                       details:nil]);
            return;
        }

        // 如果上一次 stop 还没结束，这里先记录“待启动”，等录音机关闭/结束回调后再启动。
        // 这样可规避 Error Domain=40: ASR: engine is busy.
        self.pendingWakeWord = call.arguments;

        // 与 demo 行为一致：每次 start 前重置一些状态，避免残留影响结果。
        [self.commandManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_LONG_SPEECH];
        [self.commandManager setParameter:@(NO) forKey:BDS_ASR_NEED_CACHE_AUDIO];
        if (!self.pendingWakeWord || [self.pendingWakeWord isKindOfClass:[NSNull class]]) {
            [self.commandManager setParameter:@"" forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
        }
        if (self.isAsrRunning || self.isAsrStopping) {
            self.pendingAsrStart = YES;
            result(nil);
            return;
        }

        [self jm_startAsrIfPossible];
        result(nil);

    } else if ([@"stopRecognition" isEqualToString:call.method]) {
        if (!self.commandManager) {
            result([FlutterError errorWithCode:@"uninitialized"
                                       message:@"Call create(type: BaiduSpeechBuildType.asr) before stopRecognition."
                                       details:nil]);
            return;
        }

        // 如果当前并未处于识别中，STOP 可能不会触发任何回调，导致后续 start 一直等待。
        // 这里用 CANCEL 主动把引擎拉回空闲态。
        if (!self.isAsrRunning) {
            [self.commandManager sendCommand:BDS_ASR_CMD_CANCEL];
            NSLog(@"关闭语音识别(取消)");
            [self jm_markAsrIdleAndMaybeRestart];
            result(nil);
            return;
        }

        self.isAsrStopping = YES;

        [self.commandManager sendCommand:BDS_ASR_CMD_STOP];
        NSLog(@"关闭语音识别");
        result(nil);

    } else if ([@"startMonitorWakeUp" isEqualToString:call.method]) {
        if (!self.wakeUpManager) {
            result([FlutterError errorWithCode:@"uninitialized"
                                       message:@"Call create(type: BaiduSpeechBuildType.wakeUp) before startMonitorWakeUp."
                                       details:nil]);
            return;
        }

        [self.wakeUpManager sendCommand:BDS_WP_CMD_LOAD_ENGINE];
        [self.wakeUpManager sendCommand:BDS_WP_CMD_START];
        self.isWakeUpStarted = YES;
        NSLog(@"开始语音唤醒");
        result(nil);

    } else if ([@"stopMonitorWakeUp" isEqualToString:call.method]) {
        if (!self.wakeUpManager) {
            result([FlutterError errorWithCode:@"uninitialized"
                                       message:@"Call create(type: BaiduSpeechBuildType.wakeUp) before stopMonitorWakeUp."
                                       details:nil]);
            return;
        }

        [self.wakeUpManager sendCommand:BDS_WP_CMD_STOP];
        [self.wakeUpManager sendCommand:BDS_WP_CMD_UNLOAD_ENGINE];
        self.isWakeUpStarted = NO;
        NSLog(@"关闭语音唤醒");
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - BDSClientWakeupDelegate

- (void)WakeupClientWorkStatus:(int)workStatus obj:(id)aObj {
    switch (workStatus) {
        case EWakeupEngineWorkStatusTriggered: {
            NSLog(@"唤醒 = %@", aObj);
            self.isWakeUping = YES;
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            [self configResultStatus:@"statusTriggered" type:1 data:aObj];
            break;
        }
        case EWakeupEngineWorkStatusError: {
            NSString *text = [NSString stringWithFormat:@"WAKEUP CALLBACK: encount error - %@.\n", (NSError *) aObj];
            NSLog(@"%@", text);
            NSError *error = (NSError *) aObj;
            self.isWakeUping = NO;
            self.isWakeUpStarted = NO;
            [self configResultStatus:@"statusError" type:1 data:error.localizedDescription];
            break;
        }

        default:
            break;
    }
}

#pragma mark - BDSClientASRDelegate

- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj {
    switch (workStatus) {
        case EVoiceRecognitionClientWorkStatusStartWorkIng: {
            self.isAsrRunning = YES;
            self.isAsrStopping = NO;
            self.asrBusyRetryCount = 0;
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData: {
            NSLog(@"====EVoiceRecognitionClientWorkStatusFlushData%@", @"CALLBACK: partial result");
            NSLog(@"EVoiceRecognitionClientWorkStatusFlushData------=====%@",
                  [NSString stringWithFormat:@"CALLBACK: final result - %@.\n\n", [self getDescriptionForDic:aObj]]);
            NSDictionary *result = (NSDictionary *) aObj;
            id results = result[@"results_recognition"];
            if (!results || [results isKindOfClass:[NSNull class]]) {
                results = result[@"result"]; // fallback
            }
            NSArray *voiceResultsArr = [results isKindOfClass:[NSArray class]] ? (NSArray *) results
                                                                               : nil;
            if (voiceResultsArr.count > 0) {
                [self configResultStatus:@"flushData" type:0 data:voiceResultsArr.firstObject];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: {
            NSLog(@"EVoiceRecognitionClientWorkStatusFinish------=====%@",
                  [NSString stringWithFormat:@"CALLBACK: final result - %@.\n\n", [self getDescriptionForDic:aObj]]);

            NSDictionary *result = (NSDictionary *) aObj;
            id results = result[@"results_recognition"];
            if (!results || [results isKindOfClass:[NSNull class]]) {
                results = result[@"result"]; // fallback
            }
            NSArray *voiceResultsArr = [results isKindOfClass:[NSArray class]] ? (NSArray *) results
                                                                               : nil;
            if (![self hasHeadset] && self.isWakeUping) {
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            }
            self.isWakeUping = NO;
            NSString *finalText = (voiceResultsArr.count > 0 &&
                                   [voiceResultsArr.firstObject isKindOfClass:[NSString class]])
                                  ? voiceResultsArr.firstObject : @"";
            [self configResultStatus:@"statusFinish" type:0 data:finalText];
            [self jm_markAsrIdleAndMaybeRestart];
            break;
        }
        case EVoiceRecognitionClientWorkStatusMeterLevel: {
            NSLog(@"当前音量回调------=====%ld", [aObj integerValue]);

            [self configResultStatus:@"volumeChanged" type:0 data:[NSString stringWithFormat:@"%@", aObj]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel: {
            NSLog(@"====EVoiceRecognitionClientWorkStatusCancel:%@",
                  @"CALLBACK: user press cancel.\n");
            [self jm_markAsrIdleAndMaybeRestart];
            break;
        }
        case EVoiceRecognitionClientWorkStatusRecorderEnd: {
            // 录音机已关闭：通常意味着 STOP/CANCEL 已完成，可以安全进行下一次 START。
            if (self.isAsrStopping) {
                [self jm_markAsrIdleAndMaybeRestart];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: {
            NSLog(@"====EVoiceRecognitionClientWorkStatusError%@",
                  [NSString stringWithFormat:@"CALLBACK: encount error - %@.\n", (NSError *) aObj]);

            NSError *error = (NSError *) aObj;
            if (![self hasHeadset] && self.isWakeUping) {
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            }
            self.isWakeUping = NO;

            // VAD: no speech / too short
            // 这类情况通常不是“异常”，而是端点检测认为用户未说话或说话太短。
            // 为了让 Flutter 侧复用现有“未识别到有效内容”逻辑，这里按空结果 finish 处理。
            if (error.code == EVRClientErrorCodeNoSpeech || error.code == EVRClientErrorCodeShort) {
                [self configResultStatus:@"statusFinish" type:0 data:@""];
                [self jm_markAsrIdleAndMaybeRestart];
                break;
            }

            // "engine is busy" 往往发生在快速 stop/start 或重复 start。
            // 这类错误属于瞬态：插件内部做取消+退避重试，避免上层 UI 直接进入 error 状态。
            if ([error.localizedDescription containsString:@"engine is busy"]) {
                self.asrBusyRetryCount += 1;
                if (self.asrBusyRetryCount <= 4) {
                    [self jm_retryAsrStartAfterBusy];
                    break;
                }
                // 超过重试次数再向上抛出
                self.asrBusyRetryCount = 0;
            }

            // 如果用户主动停止识别（isAsrStopping == YES），此时发生的HTTP timeout错误
            // 是因为STOP命令中断了正在进行的在线请求，属于正常行为，不应该作为错误上报。
            // Error Domain=31 Code=2031617 表示 "Local error while making HTTP request: timeout"
            NSString *errorDesc = error.localizedDescription ?: @"";
            NSString *errorDomain = error.domain ?: @"";
            BOOL isHttpTimeout = (error.code == 2031617 && ([errorDomain isEqualToString:@"31"] ||
                                                            [errorDomain containsString:@"31"])) ||
                                 ([errorDesc containsString:@"timeout"] &&
                                  ([errorDesc containsString:@"HTTP"] ||
                                   [errorDesc containsString:@"http"]));

            if (self.isAsrStopping && isHttpTimeout) {
                NSLog(@"用户主动停止导致的HTTP超时，静默处理，不向上层上报错误");
                [self jm_markAsrIdleAndMaybeRestart];
                break;
            }

            // KWS（关键词唤醒）未初始化错误：当传入了唤醒词但KWS模块未初始化时会出现此错误。
            // Error Domain=34 Code=2228229 表示 "[KWS] has not initialized."
            // 这通常发生在使用输入法模式的离线引擎时传入了唤醒词，但KWS模块未正确初始化。
            // 如果不需要唤醒词功能，可以静默处理此错误，继续使用普通识别功能。
            BOOL isKwsNotInitialized = (error.code == 2228229 &&
                                        ([errorDomain isEqualToString:@"34"] ||
                                         [errorDomain containsString:@"34"])) ||
                                       ([errorDesc containsString:@"KWS"] &&
                                        ([errorDesc containsString:@"not initialized"] ||
                                         [errorDesc containsString:@"has not initialized"]));

            if (isKwsNotInitialized) {
                NSLog(@"KWS未初始化错误（可能因传入了唤醒词但KWS模块未初始化），静默处理，继续使用普通识别功能");
                // 清除待处理的唤醒词，避免下次启动时再次触发此错误
                self.pendingWakeWord = nil;
                [self jm_markAsrIdleAndMaybeRestart];
                break;
            }
            [self configResultStatus:@"statusError" type:0 data:error.localizedDescription];
            [self jm_markAsrIdleAndMaybeRestart];
            break;
        }
        default:
            break;
    }
}

- (NSString *)getDescriptionForDic:(NSDictionary *)dic {
    if (dic) {
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic
                                                                              options:NSJSONWritingPrettyPrinted
                                                                                error:nil] encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (void)configResultStatus:(NSString *)status type:(NSInteger)type data:(id)data {
    NSDictionary *resultDic = @{@"status": status, @"data": data,
                                @"type": [NSString stringWithFormat:@"%ld", type]};
    if (self.eventSink) {
        self.eventSink(resultDic);
    }
}

#pragma mark - listen

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.eventSink = nil;
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    if (_eventSink == nil) {
        self.eventSink = events;
    }
    return nil;
}

#pragma mark - privite

/**
 *  判断是否有耳机
 */
- (BOOL)hasHeadset {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    AVAudioSessionRouteDescription *currentRoute = [audioSession currentRoute];

    for (AVAudioSessionPortDescription *output in currentRoute.outputs) {
        if ([[output portType] isEqualToString:AVAudioSessionPortHeadphones] ||
            [[output portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            return YES;
        }
    }
    return NO;
}

- (void)dealloc {
    if (self.routeChangeObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.routeChangeObserver];
        self.routeChangeObserver = nil;
    }
}

@end
