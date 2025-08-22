// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/utilities/string_extensions.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:path/path.dart' as path;

class PluginsPage extends DiagnosticPageWithNav {
  @override
  AnalysisServer server;

  PluginsPage(DiagnosticsSite site, this.server)
    : super(site, 'plugins', 'Plugins', description: 'Plugins in use.');

  @override
  Future<void> generateContent(Map<String, String> params) async {
    h3('Analysis plugins');
    var analysisPlugins = server.pluginManager.plugins;

    if (analysisPlugins.isEmpty) {
      blankslate('No known analysis plugins.');
    } else {
      analysisPlugins.sort(
        (first, second) => first.pluginId.compareTo(second.pluginId),
      );
      for (var plugin in analysisPlugins) {
        var id = plugin.pluginId;
        var data = plugin.data;
        var responseTimes = PluginManager.pluginResponseTimes[plugin] ?? {};

        var components = path.split(id);
        var length = components.length;
        var name = switch (length) {
          0 => 'unknown plugin',
          > 2 => components[length - 3],
          _ => components[length - 1],
        };
        h4(name);

        _emitTable([
          ['Bootstrap package path:', id],
          ['Execution path:', plugin.executionPath.wordBreakOnSlashes],
          ['Packages file path', plugin.packagesPath.wordBreakOnSlashes],
        ]);

        if (data.name == null) {
          if (plugin.exception != null) {
            p('Not running due to:');
            pre(() {
              buf.write(plugin.exception);
            });
          } else {
            p(
              'Not running for unknown reason (no exception was caught while '
              'starting).',
            );
          }
        } else {
          p('Name: ${data.name}');
          p('Version: ${data.version}');
          p('Associated contexts:');
          var contexts = plugin.contextRoots;
          if (contexts.isEmpty) {
            blankslate('none');
          } else {
            ul(contexts.toList(), (ContextRoot root) {
              buf.writeln(root.root);
            });
          }
          p('Performance:');
          var entries = responseTimes.entries.toList();
          entries.sort((first, second) => first.key.compareTo(second.key));
          for (var entry in entries) {
            var requestName = entry.key;
            var data = entry.value;
            // TODO(brianwilkerson): Consider displaying these times as a graph,
            //  similar to the one in CompletionPage.generateContent.
            var buffer = StringBuffer();
            buffer.write(requestName);
            buffer.write(' ');
            buffer.write(data.toAnalyticsString());
            p(buffer.toString());
          }
        }
      }
    }
  }

  void _emitTable(List<List<String>> data) {
    buf.writeln('<table>');
    for (var row in data) {
      buf.writeln('<tr>');
      for (var value in row) {
        buf.writeln('<td>$value</td>');
      }
      buf.writeln('</tr>');
    }

    buf.writeln('</table>');
  }
}
