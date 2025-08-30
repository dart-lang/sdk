// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/analysis_options.dart';

/// This class can generate various files to make up the shared plugin package.
class PluginPackageGenerator {
  /// The plugin configuration, a map of plugin names to each plugin's
  /// configuration.
  ///
  /// This typically stems from plugin configuration in an analysis options
  /// file.
  final List<PluginConfiguration> _configurations;

  final String? _dependencyOverrides;

  PluginPackageGenerator({
    required List<PluginConfiguration> configurations,
    String? dependencyOverrides,
  }) : _configurations = configurations,
       _dependencyOverrides = dependencyOverrides;

  /// Generates the Dart entrpoint file which is to be spawned in a Dart
  /// isolate by the analysis server.
  String generateEntrypoint() {
    var imports = [
      "'package:analysis_server_plugin/src/plugin_server.dart'",
      "'package:analyzer/file_system/physical_file_system.dart'",
      "'package:analyzer_plugin/src/channel/isolate_channel.dart'",
      for (var configuration in _configurations)
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
    for (var configuration in _configurations) {
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
environment:
  sdk: ^3.6.0
dependencies:
  # The version of the analysis_server_plugin package that matches the protocol
  # used by the active analysis_server.
  analysis_server_plugin: ^0.2.0
''');

    for (var configuration in _configurations) {
      buffer.write(configuration.sourceYaml());
    }

    if (_dependencyOverrides != null) {
      buffer.write('''
dependency_overrides:
$_dependencyOverrides
''');
    }

    return buffer.toString();
  }
}
