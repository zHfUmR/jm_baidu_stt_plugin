import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jm_baidu_stt_plugin/jm_baidu_stt_plugin.dart';
import 'package:jm_baidu_stt_plugin/jm_baidu_stt_plugin_method_channel.dart';
import 'package:jm_baidu_stt_plugin/jm_baidu_stt_plugin_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockJmBaiduSttPluginPlatform
    with MockPlatformInterfaceMixin
    implements JmBaiduSttPluginPlatform {
  final _controller = StreamController<dynamic>.broadcast();
  int createCallCount = 0;
  BaiduSpeechBuildType? lastType;
  String? lastAppId;
  String? lastAppKey;
  String? lastAppSecret;

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Stream<dynamic>? onChange() => _controller.stream;

  @override
  Future<void> create({
    required BaiduSpeechBuildType type,
    required String appId,
    required String appKey,
    required String appSecret,
  }) async {
    createCallCount++;
    lastType = type;
    lastAppId = appId;
    lastAppKey = appKey;
    lastAppSecret = appSecret;
  }

  @override
  Future<void> startRecognition({String? wakeUpWord}) async {}

  @override
  Future<void> stopRecognition() async {}

  @override
  Future<void> startMonitorWakeUp() async {}

  @override
  Future<void> stopMonitorWakeUp() async {}
}

void main() {
  final JmBaiduSttPluginPlatform initialPlatform =
      JmBaiduSttPluginPlatform.instance;

  test('$MethodChannelJmBaiduSttPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJmBaiduSttPlugin>());
  });

  test('create delegates to platform implementation', () async {
    final mockPlatform = MockJmBaiduSttPluginPlatform();
    JmBaiduSttPluginPlatform.instance = mockPlatform;
    JmBaiduSttPlugin.initSDK(
      appId: 'appId',
      appKey: 'appKey',
      appSecret: 'appSecret',
      onEvent: (_) {},
    );

    await JmBaiduSttPlugin.create(type: BaiduSpeechBuildType.asr);
    expect(mockPlatform.createCallCount, 1);
    expect(mockPlatform.lastType, BaiduSpeechBuildType.asr);
    expect(mockPlatform.lastAppId, 'appId');
    expect(mockPlatform.lastAppKey, 'appKey');
    expect(mockPlatform.lastAppSecret, 'appSecret');
  });
}
