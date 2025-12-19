//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <jm_baidu_stt_plugin/jm_baidu_stt_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) jm_baidu_stt_plugin_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "JmBaiduSttPlugin");
  jm_baidu_stt_plugin_register_with_registrar(jm_baidu_stt_plugin_registrar);
}
