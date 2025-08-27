// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:analysis_server/src/plugin/plugin_isolate.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:path/path.dart' as path;

/// Data about the plugins associated with the context roots.
class PluginData {
  /// The number of times that plugin information has been recorded.
  int recordCount = 0;

  /// A table mapping the ids of running plugins to the number of context roots
  /// associated with each of the plugins.
  Map<String, PercentileCalculator> usageCounts = {};

  String get usageCountData {
    return json.encode({
      'recordCount': recordCount,
      'rootCounts': _encodeUsageCounts(),
    });
  }

  /// Records data about the plugins that are currently running, via info from
  /// [pluginManager].
  void recordPlugins(PluginManager pluginManager) {
    recordCount++;
    for (var isolate in pluginManager.pluginIsolates) {
      usageCounts
          .putIfAbsent(isolate.safePluginId, () => PercentileCalculator())
          .addValue(isolate.contextRoots.length);
    }
  }

  /// Returns an encoding of the [usageCounts].
  Map<String, Object> _encodeUsageCounts() => {
    for (var entry in usageCounts.entries) entry.key: entry.value.toJson(),
  };
}

extension PluginIsolateExtension on PluginIsolate {
  /// An ID for this plugin that doesn't contain any PII.
  ///
  /// If the plugin is installed in the pub cache and hosted on `pub.dev`, then
  /// the returned name will be the name and version of the containing package
  /// as listed on `pub.dev`. If not, then it might be an internal name so we
  /// default to 'unknown'.
  String get safePluginId {
    var components = path.split(pluginId);
    if (components.contains('.pub-cache')) {
      var index = components.lastIndexOf('analyzer_plugin');
      if (index > 2 &&
          components[index - 1] == 'tools' &&
          components[index - 3] == 'pub.dev') {
        return components[index - 2];
      }
    }
    return 'unknown';
  }
}
