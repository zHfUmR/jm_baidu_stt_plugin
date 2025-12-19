#ifndef FLUTTER_PLUGIN_JM_BAIDU_STT_PLUGIN_H_
#define FLUTTER_PLUGIN_JM_BAIDU_STT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace jm_baidu_stt_plugin {

class JmBaiduSttPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  JmBaiduSttPlugin();

  virtual ~JmBaiduSttPlugin();

  // Disallow copy and assign.
  JmBaiduSttPlugin(const JmBaiduSttPlugin&) = delete;
  JmBaiduSttPlugin& operator=(const JmBaiduSttPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace jm_baidu_stt_plugin

#endif  // FLUTTER_PLUGIN_JM_BAIDU_STT_PLUGIN_H_
