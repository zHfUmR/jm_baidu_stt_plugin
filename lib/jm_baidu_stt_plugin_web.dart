// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'jm_baidu_stt_plugin_platform_interface.dart';
import 'models/baidu_speech_types.dart';

/// A web implementation of the JmBaiduSttPluginPlatform of the JmBaiduSttPlugin plugin.
class JmBaiduSttPluginWeb extends JmBaiduSttPluginPlatform {
  /// Constructs a JmBaiduSttPluginWeb
  JmBaiduSttPluginWeb();

  static void registerWith(Registrar registrar) {
    JmBaiduSttPluginPlatform.instance = JmBaiduSttPluginWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Stream<dynamic>? onChange() => const Stream.empty();

  @override
  Future<void> create({
    required BaiduSpeechBuildType type,
    required String appId,
    required String appKey,
    required String appSecret,
  }) {
    throw UnimplementedError('JmBaiduSttPlugin is not supported on Web.');
  }

  @override
  Future<void> startRecognition({String? wakeUpWord}) {
    throw UnimplementedError('JmBaiduSttPlugin is not supported on Web.');
  }

  @override
  Future<void> stopRecognition() {
    throw UnimplementedError('JmBaiduSttPlugin is not supported on Web.');
  }

  @override
  Future<void> startMonitorWakeUp() {
    throw UnimplementedError('JmBaiduSttPlugin is not supported on Web.');
  }

  @override
  Future<void> stopMonitorWakeUp() {
    throw UnimplementedError('JmBaiduSttPlugin is not supported on Web.');
  }
}
