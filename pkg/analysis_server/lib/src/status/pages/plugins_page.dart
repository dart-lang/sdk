// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_isolate.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/utilities/string_extensions.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:path/path.dart' as path;

/// The page that displays information about _new_ (not legacy) analyzer
/// plugins.
class PluginsPage extends DiagnosticPageWithNav {
  @override
  AnalysisServer server;

  new(DiagnosticsSite site, this.server)
    : super(site, 'plugins', 'Plugins', description: 'Plugins in use.');

  @override
  Future<void> generateContent(Map<String, String> params) async {
    // Maps each plugin name to the list of configurations where that plugin is
    // configured.
    var allConfigs = <String, List<_ConfigurationOrigin>>{};
    for (var driver in server.driverMap.values) {
      var uniqueOptionsSet = driver.analysisOptionsMap.options.toSet();
      for (var options in uniqueOptionsSet) {
        if (options.file case var file?) {
          for (var config in options.pluginConfigurations) {
            var origin = _ConfigurationOrigin(
              optionsPath: file.path,
              config: config,
            );
            allConfigs.putIfAbsent(config.name, () => []).add(origin);
          }
        }
      }
    }

    _emitIncompatibleInfo();

    var pluginIsolates = server.pluginManager.newPluginIsolates;

    if (pluginIsolates.isEmpty) {
      if (allConfigs.isEmpty) {
        blankslate('No known analysis plugins.');
      } else {
        h3('Warning: no running isolates');
        p(
          'Plugins have been specified in the analysis options files listed '
          'below, but no plugin isolates are currently running. This may '
          'indicate a startup failure or that the plugin system is disabled.',
        );
        h3('Configured plugins');
        for (var MapEntry(key: pluginName, value: specs)
            in allConfigs.entries) {
          p('<strong>$pluginName</strong> specified in:');
          ul(specs, (spec) {
            buf.writeln('<code>${spec.optionsPath}</code>');
          });
        }
      }
      return;
    }

    pluginIsolates.sort(
      (first, second) => first.pluginId.compareTo(second.pluginId),
    );

    for (var isolate in pluginIsolates) {
      await _emitIsolateInfo(isolate);

      _emitPerformance(isolate);
    }
  }

  void _emitIncompatibleInfo() {
    var incompatibleSources = <String, List<String>>{};
    for (var driver in server.driverMap.values) {
      var contextPath = driver.analysisContext?.contextRoot.root.path ?? '';
      var uniqueOptionsSet = driver.analysisOptionsMap.options.toSet();
      var driverConfigs = <String, List<_ConfigurationOrigin>>{};
      for (var options in uniqueOptionsSet) {
        if (options.file case var file?) {
          for (var config in options.pluginConfigurations) {
            var origin = _ConfigurationOrigin(
              optionsPath: file.path,
              config: config,
            );
            driverConfigs.putIfAbsent(config.name, () => []).add(origin);
          }
        }
      }

      for (var MapEntry(key: pluginName, value: specs)
          in driverConfigs.entries) {
        if (specs.length < 2) continue;
        for (int i = 0; i < specs.length; i++) {
          for (int j = i + 1; j < specs.length; j++) {
            var spec1 = specs[i];
            var spec2 = specs[j];
            if (spec1.config.source != spec2.config.source) {
              var spec1Yaml = spec1.config.sourceYaml().trim();
              var spec2Yaml = spec2.config.sourceYaml().trim();
              incompatibleSources
                  .putIfAbsent(pluginName, () => [])
                  .add(
                    'In context <code>$contextPath</code>: '
                    '<code>${spec1.optionsPath}</code> specifies '
                    '<pre><code>$spec1Yaml</code></pre>'
                    'but <code>${spec2.optionsPath}</code> specifies '
                    '<pre><code>$spec2Yaml</code></pre>'
                    'The two plugin specifications must be identical.',
                  );
            }
          }
        }
      }
    }

    if (incompatibleSources.isNotEmpty) {
      h3('Incompatible plugin sources');
      p(
        'The following plugins are specified with incompatible sources (different '
        'version constraints, paths, or git configurations) in different analysis '
        'options files within the same context. This prevents them from being '
        'run in the same isolate, and forces the server to spawn multiple '
        'isolates.',
      );
      for (var MapEntry(key: pluginName, value: conflictList)
          in incompatibleSources.entries) {
        p('<strong>$pluginName</strong>:');
        ul(conflictList, (conflict) {
          buf.writeln(conflict);
        });
      }
    }
  }

  Future<void> _emitIsolateInfo(PluginIsolate isolate) async {
    p('The following plugins are running from a single bootstrapped location:');

    _emitTable([
      ['Bootstrap package path:', isolate.pluginId],
      if (isolate.executionPath case var executionPath?)
        ['Execution path:', executionPath.wordBreakOnSlashes],
      if (isolate.packageConfigPath case var packageConfigPath?)
        [
          'Package config path:',
          '${path.posix.dirname(packageConfigPath)}/'.wordBreakOnSlashes +
              formatContentsLink(
                packageConfigPath,
                file_paths.packageConfigJson,
              ),
        ],
    ]);

    var otherIsolates = <PluginIsolate>[];
    for (var contextRoot in isolate.contextRoots) {
      for (var otherIsolate in server.pluginManager.newPluginIsolates) {
        if (otherIsolate != isolate &&
            otherIsolate.contextRoots.contains(contextRoot)) {
          if (!otherIsolates.contains(otherIsolate)) {
            otherIsolates.add(otherIsolate);
          }
        }
      }
    }

    if (otherIsolates.isNotEmpty) {
      p(
        'Note: This isolate is analyzing a context that is also analyzed by '
        'other plugin isolates. Plugins are separated into different isolates '
        'to ensure that pub can consistently solve their version constraints.',
      );
      p('Other isolates analyzing the same context:');
      ul(otherIsolates, (other) {
        buf.writeln('<code>${other.pluginId}</code>');
      });
    }

    if (isolate.data.name == null) {
      // This indicates the isolate is not actually running.
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
      return;
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
      // Either the plugin is not alive, or the plugin did not respond in time.
      // TODO(srawlins): Distinguish between the two.
      p('Plugin isolate did not respond with plugin details.');
      return;
    }

    for (var plugin in details.plugins) {
      h3(plugin.name);

      var prints = isolate.pluginPrints[plugin.name];
      if (prints != null) {
        h3('Debug print output:');
        pre(() {
          var discardedPrintCount =
              isolate.discardedPluginPrintCount[plugin.name];
          if (discardedPrintCount != null && discardedPrintCount > 0) {
            buf.write('(... $discardedPrintCount previous messages)');
          }
          for (var print in prints) {
            var timestamp = DateTime.fromMillisecondsSinceEpoch(
              print.timestamp,
            );
            buf.write('$timestamp: ${print.message}\n');
          }
        });
      }

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

  void _emitPerformance(PluginIsolate isolate) {
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

/// Represents the location and configuration of a plugin specified in an
/// analysis options file, used for diagnostic reporting on the plugins page.
class _ConfigurationOrigin({
  required final String optionsPath,
  required final PluginConfiguration config,
});
