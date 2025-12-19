#include "include/jm_baidu_stt_plugin/jm_baidu_stt_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "jm_baidu_stt_plugin.h"

void JmBaiduSttPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  jm_baidu_stt_plugin::JmBaiduSttPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
