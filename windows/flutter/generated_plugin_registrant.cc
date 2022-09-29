//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_drop/desktop_drop_plugin.h>
#include <drag_and_drop_windows/drag_and_drop_windows_plugin.h>
#include <super_native_extensions/super_native_extensions_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DesktopDropPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DesktopDropPlugin"));
  DragAndDropWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DragAndDropWindowsPlugin"));
  SuperNativeExtensionsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SuperNativeExtensionsPluginCApi"));
}
