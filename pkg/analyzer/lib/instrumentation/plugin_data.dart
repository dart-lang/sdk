// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Instrumentation data about a plugin.
class PluginData {
  /// The ID used to uniquely identify the plugin.
  final String pluginId;

  /// The name of the plugin, or `null` if the plugin is not running.
  final String? name;

  /// The version of the plugin, or `null` if the plugin is not running.
  final String? version;

  PluginData(this.pluginId, this.name, this.version);

  /// Adds the information about the plugin to the list of [fields] to be sent
  /// to the instrumentation server.
  void addToFields(List<String> fields) {
    fields.add(pluginId);
    fields.add(name ?? '');
    fields.add(version ?? '');
  }
}
