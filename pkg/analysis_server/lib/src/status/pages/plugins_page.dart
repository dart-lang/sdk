// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/utilities/string_extensions.dart';

/// The page that displays information about _new_ (not legacy) analyzer
/// plugins.
class PluginsPage extends DiagnosticPageWithNav {
  @override
  AnalysisServer server;

  PluginsPage(DiagnosticsSite site, this.server)
    : super(site, 'plugins', 'Plugins', description: 'Plugins in use.');

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var pluginIsolates = server.pluginManager.newPluginIsolates;

    if (pluginIsolates.isEmpty) {
      blankslate('No known analysis plugins.');
      return;
    }

    pluginIsolates.sort(
      (first, second) => first.pluginId.compareTo(second.pluginId),
    );
    for (var isolate in pluginIsolates) {
      var id = isolate.pluginId;
      var data = isolate.data;

      p(
        'The following plugins are running from a single bootstrapped '
        'location:',
      );

      _emitTable([
        ['Bootstrap package path:', id],
        if (isolate.executionPath case var executionPath?)
          ['Execution path:', executionPath.wordBreakOnSlashes],
        if (isolate.packageConfigPath case var packageConfigPath?)
          ['Package config path', packageConfigPath.wordBreakOnSlashes],
      ]);

      if (data.name == null) {
        if (isolate.exception != null) {
          p('Not running due to:');
          pre(() {
            buf.write(isolate.exception);
          });
        } else {
          p(
            'Not running for unknown reason (no exception was caught while '
            'starting).',
          );
        }
        continue;
      }

      h3('Associated contexts:');
      var contexts = isolate.contextRoots;
      if (contexts.isEmpty) {
        blankslate('none');
      } else {
        ul(contexts.toList(), (root) {
          buf.writeln(root.root);
        });
      }

      var details = await isolate.requestDetails();
      if (details == null) {
        // Either the plugin is not alive, or the plugin did not respond in
        // time.
        // TODO(srawlins): Distinguish between the two.
        p('Plugin isolate did not respond with plugin details.');
      } else {
        for (var plugin in details.plugins) {
          h3(plugin.name);

          if (plugin.lintRules.isNotEmpty) {
            p('Lint rules:');
            ul(plugin.lintRules, (rule) {
              buf.writeln(rule);
            });
          }
          if (plugin.warningRules.isNotEmpty) {
            p('Warning rules:');
            ul(plugin.warningRules, (rule) {
              buf.writeln(rule);
            });
          }
          if (plugin.fixes.isNotEmpty) {
            p('Quick fixes:');
            ul(plugin.fixes, (fix) {
              var codes = fix.codes.join(', ');
              buf.writeln('${fix.id}: "${fix.message}" to fix $codes');
            });
          }
          if (plugin.assists.isNotEmpty) {
            p('Assists:');
            ul(plugin.assists, (assist) {
              buf.writeln('${assist.id}: "${assist.message}"');
            });
          }
        }
      }

      h3('Performance:');
      p('''
The server communicates with the plugins by sending requests. Each line
below provides aggregated information about one of the requests and begins with
the name of the request. The 'count' is the number of times the request was
sent. The percentiles are the 50th, 75th, 90th, 95th, and 100th percentiles of
the number of milliseconds it took to receiver a response.
''');
      var responseTimes = PluginManager.pluginResponseTimes[isolate] ?? {};
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
