// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin2/analyzer_version.g.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';

/// This class can generate various files to make up the shared plugin package.
class PluginPackageGenerator {
  /// The plugin configuration, a map of plugin names to each plugin's
  /// configuration.
  ///
  /// This typically stems from plugin configuration in an analysis options
  /// file.
  final List<PluginConfiguration> _pluginConfigurations;

  PluginPackageGenerator(this._pluginConfigurations);

  /// Generates the Dart entrpoint file which is to be spawned in a Dart
  /// isolate by the analysis server.
  String generateEntrypoint() {
    var imports = [
      "'package:analysis_server_plugin/src/plugin_server.dart'",
      "'package:analyzer/file_system/physical_file_system.dart'",
      "'package:analyzer_plugin/src/channel/isolate_channel.dart'",
      for (var configuration in _pluginConfigurations)
        "'package:${configuration.name}/main.dart' as ${configuration.name}",
    ];

    var buffer = StringBuffer("import 'dart:isolate';\n");
    for (var import in imports..sort()) {
      buffer.writeln('import $import;');
    }

    buffer.write('''
Future<void> main(List<String> args, SendPort sendPort) async {
  var pluginServer = PluginServer(
    resourceProvider: PhysicalResourceProvider.INSTANCE,
    plugins: [
''');
    // TODO(srawlins): Format with the formatter, for readability.
    for (var configuration in _pluginConfigurations) {
      buffer.writeln('      ${configuration.name}.plugin,');
    }
    buffer.write('''
    ],
  );
  await pluginServer.initialize();
  var channel = PluginIsolateChannel(sendPort);
  pluginServer.start(channel);
}
''');

    return buffer.toString();
  }

  /// Generates a pubspec file which spells out where to retreive plugin package
  /// sources.
  String generatePubspec() {
    var buffer = StringBuffer();
    buffer.write('''
name: plugin_entrypoint
version: 0.0.1
dependencies:
  analyzer: '$analyzerVersion'
  analyzer_plugin: '$analyzerPluginVersion'
''');

    for (var configuration in _pluginConfigurations) {
      buffer.write(configuration.sourceYaml());
    }

    return buffer.toString();
  }
}
