enum BaiduSpeechBuildType {
  asr,
  wakeUp,
}

enum BaiduSpeechStatusType {
  /// 语音识别中
  flushData,

  /// 语音识别完毕
  statusFinish,

  /// 音量变化
  volumeChanged,

  /// 识别/唤醒失败
  statusError,

  /// 唤醒成功
  statusTriggered,
}
