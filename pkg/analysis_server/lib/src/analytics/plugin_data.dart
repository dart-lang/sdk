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

  /// A table mapping the IDs of running "new" plugin isolates to various
  /// percentile-based analytics for each plugin.
  Map<String, PluginDataPerIsolate> counts = {};

  /// A table mapping the IDs of running legacy plugins to the percentile-based
  /// analytics regarding the number of context roots associated with each of
  /// the plugins.
  Map<String, PercentileCalculator> usageCounts = {};

  String get usageCountData {
    return json.encode({
      'recordCount': recordCount,
      'rootCounts': _encodeUsageCounts(),
    });
  }

  /// Records data about the plugins that are currently running, via info from
  /// [pluginManager].
  Future<void> recordPlugins(PluginManager pluginManager) async {
    recordCount++;
    for (var isolate in pluginManager.legacyPluginIsolates) {
      usageCounts
          .putIfAbsent(isolate.safePluginId, () => PercentileCalculator())
          .addValue(isolate.contextRoots.length);
    }

    // Record a data point for each context root with _no_ configured new
    // plugins.
    for (var contextRootPath in pluginManager.contextRootsWithNoPlugins) {
      String pluginEntrypointPath;
      try {
        // Plugin analytics are keyed to safe plugin IDs, which are derived from
        // the context root path.
        pluginEntrypointPath = pluginManager.pluginStateFolderPath(
          contextRootPath,
        );
      } on PluginException {
        // No valid state location on this file system; don't log this data.
        continue;
      }
      var safePluginId = pluginEntrypointPath.asSafePluginId;
      counts.putIfAbsent(
        safePluginId,
        () => PluginDataPerIsolate(pluginCount: 0),
      );
    }

    for (var isolate in pluginManager.newPluginIsolates) {
      var details = await isolate.requestDetails();
      if (details == null) continue;

      var pluginDataPerIsolate = counts.putIfAbsent(
        isolate.safePluginId,
        () => PluginDataPerIsolate(pluginCount: details.plugins.length),
      );

      for (var plugin in details.plugins) {
        pluginDataPerIsolate.lintRuleCounts.addValue(plugin.lintRules.length);
        pluginDataPerIsolate.warningRuleCounts.addValue(
          plugin.warningRules.length,
        );
        pluginDataPerIsolate.fixCounts.addValue(plugin.fixes.length);
        pluginDataPerIsolate.assistCounts.addValue(plugin.assists.length);
      }
    }
  }

  /// Returns an encoding of the [usageCounts].
  Map<String, Object> _encodeUsageCounts() => {
    for (var entry in usageCounts.entries) entry.key: entry.value.toJson(),
  };
}

/// Plugin data (for "new" plugins) for a given plugin isolate.
///
/// Only one plugin isolate runs for a given analysis context.
class PluginDataPerIsolate {
  /// The number of running plugins.
  final int pluginCount;

  /// The percentile-based analytics regarding the number of lint rules which
  /// are registered in each plugin.
  PercentileCalculator lintRuleCounts = PercentileCalculator();

  /// The percentile-based analytics regarding the number of warning rules which
  /// are registered in each plugin.
  PercentileCalculator warningRuleCounts = PercentileCalculator();

  /// The percentile-based analytics regarding the number of quick fixes which
  /// are registered in each plugin.
  PercentileCalculator fixCounts = PercentileCalculator();

  /// The percentile-based analytics regarding the number of quick assists which
  /// are registered in each plugin.
  PercentileCalculator assistCounts = PercentileCalculator();

  PluginDataPerIsolate({required this.pluginCount});
}

extension on String {
  String get asSafePluginId {
    var components = path.split(this);
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

extension PluginIsolateExtension on PluginIsolate {
  /// An ID for this plugin that doesn't contain any PII.
  ///
  /// If the plugin is installed in the pub cache and hosted on `pub.dev`, then
  /// the returned name will be the name and version of the containing package
  /// as listed on `pub.dev`. If not, then it might be an internal name so we
  /// default to 'unknown'.
  String get safePluginId => pluginId.asSafePluginId;
}
