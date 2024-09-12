// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This class can generate various files to make up the shared plugin package.
class PluginPackageGenerator {
  /// The plugin configuration, a map of plugin names to each plugin's
  /// configuration.
  ///
  /// This typically stems from plugin configuration in an analysis options
  /// file.
  final Map<String, Object> _pluginConfiguration;

  PluginPackageGenerator(this._pluginConfiguration);

  /// Generates the Dart entrpoint file which is to be spawned in a Dart
  /// isolate by the analysis server.
  String generateEntrypoint() {
    var imports = [
      "'package:analysis_server_plugin/src/plugin_server.dart'",
      "'package:analyzer/file_system/physical_file_system.dart'",
      "'package:analyzer_plugin/starter.dart'",
      for (var name in _pluginConfiguration.keys)
        "'package:$name/main.dart' as $name",
    ];

    var buffer = StringBuffer("import 'dart:isolate';");
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
    for (var name in _pluginConfiguration.keys) {
      buffer.writeln('      $name.plugin,');
    }
    buffer.write('''
    ],
  );
  await startPlugin();
  ServerPluginStarter(wrangler).start(sendPort);
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
''');

    for (var MapEntry(key: name, value: configuration)
        in _pluginConfiguration.entries) {
      switch (configuration) {
        case String():
          buffer.writeln('  $name: $configuration');
        case Map<String, Object>():
          if (configuration case {'path': String pathValue}) {
            buffer.writeln('  $name:\n    path: $pathValue');
          } else if (configuration case {'git': String gitValue}) {
            buffer.writeln('  $name:\n    git: $gitValue');
          }
      }
    }

    return buffer.toString();
  }
}
