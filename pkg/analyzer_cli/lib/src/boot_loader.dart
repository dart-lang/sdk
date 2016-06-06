// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.boot_loader;

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/plugin/plugin_configuration.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/src/yaml_node.dart';

const _analyzerPackageName = 'analyzer';

/// Return non-null if there is a validation issue with this plugin.
String validate(PluginInfo plugin) {
  var missing = <String>[];
  if (plugin.className == null) {
    missing.add('class name');
  }
  if (plugin.libraryUri == null) {
    missing.add('library uri');
  }
  if (missing.isEmpty) {
    // All good.
    return null;
  }
  return 'Plugin ${plugin.name} skipped, config missing: ${missing.join(", ")}';
}

List<PluginInfo> _validate(Iterable<PluginInfo> plugins) {
  List<PluginInfo> validated = <PluginInfo>[];
  plugins.forEach((PluginInfo plugin) {
    String validation = validate(plugin);
    if (validation != null) {
      errorSink.writeln(validation);
    } else {
      validated.add(plugin);
    }
  });
  return validated;
}

/// Source code assembler.
class Assembler {
  /// Plugins to configure.
  final Iterable<PluginInfo> plugins;

  /// Create an assembler for the given plugin [config].
  Assembler(this.plugins);

  /// A string enumerating required package `import`s.
  String get enumerateImports =>
      plugins.map((PluginInfo p) => "import '${p.libraryUri}';").join('\n');

  /// A string listing initialized plugin instances.
  String get pluginList =>
      plugins.map((PluginInfo p) => 'new ${p.className}()').join(', ');

  /// Create a file containing a `main()` suitable for loading in spawned
  /// isolate.
  String createMain() => _generateMain();

  String _generateMain() => """
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

import 'package:analyzer_cli/src/driver.dart';

$enumerateImports

void main(List<String> args) {
  var starter = new Driver();
  starter.userDefinedPlugins = [$pluginList];
  starter.start(args);
}
""";
}

/// Given environment information extracted from command-line `args`, creates a
/// a loadable analyzer "image".
class BootLoader {
  /// Emits an error message to [errorSink] if plugin config can't be read.
  static final ErrorHandler _pluginConfigErrorHandler = (Exception e) {
    String details;
    if (e is PluginConfigFormatException) {
      details = e.message;
      var node = e.yamlNode;
      if (node is YamlNode) {
        SourceLocation location = node.span.start;
        details += ' (line ${location.line}, column ${location.column})';
      }
    } else {
      details = e.toString();
    }

    errorSink.writeln('Plugin configuration skipped: $details');
  };

  /// Reads plugin config info from the analysis options file.
  PluginConfigOptionsProcessor _pluginOptionsProcessor =
      new PluginConfigOptionsProcessor(_pluginConfigErrorHandler);

  /// Create a loadable analyzer image configured with plugins derived from
  /// the given analyzer command-line `args`.
  Image createImage(List<String> args) {
    // Parse commandline options.
    CommandLineOptions options = CommandLineOptions.parse(args);

    // Process analysis options file (and notify all interested parties).
    _processAnalysisOptions(options);

    // TODO(pquitslund): Pass in .packages info
    return new Image(_pluginOptionsProcessor.config,
        args: args, packageRootPath: options.packageRootPath);
  }

  File _getOptionsFile(
      CommandLineOptions options, ResourceProvider resourceProvider) {
    String analysisOptionsFile = options.analysisOptionsFile;
    if (analysisOptionsFile != null) {
      return resourceProvider.getFile(analysisOptionsFile);
    }
    File file =
        resourceProvider.getFile(engine.AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    if (!file.exists) {
      file = resourceProvider
          .getFile(engine.AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    }
    return file;
  }

  void _processAnalysisOptions(CommandLineOptions commandLineOptions) {
    // Determine options file path.
    try {
      File file = _getOptionsFile(
          commandLineOptions, PhysicalResourceProvider.INSTANCE);
      AnalysisOptionsProvider analysisOptionsProvider =
          new AnalysisOptionsProvider();
      Map<String, YamlNode> options =
          analysisOptionsProvider.getOptionsFromFile(file);
      //TODO(pq): thread in proper context.
      var temporaryContext = new AnalysisContextImpl();
      _pluginOptionsProcessor.optionsProcessed(temporaryContext, options);
    } on Exception catch (e) {
      _pluginOptionsProcessor.onError(e);
    }
  }
}

/// A loadable "image" of a a configured analyzer instance.
class Image {
  /// (Optional) package root path.
  final String packageRootPath;

  /// (Optional) package map.
  final Map<String, Uri> packages;

  /// (Optional) args to be passed on to the loaded main.
  final List<String> args;

  /// Plugin configuration.
  final PluginConfig config;

  /// Create an image with the given [config] and optionally [packages],
  /// [packageRootPath], and command line [args].
  Image(this.config, {this.packages, this.packageRootPath, this.args});

  /// Load this image.
  ///
  /// Loading an image consists in assembling an analyzer `main()`, configured
  /// to include the appropriate analyzer plugins as specified in
  /// `.analyzer_options` which is then run in a spawned isolate.
  Future load() {
    List<PluginInfo> plugins = _validate(config.plugins);
    String mainSource = new Assembler(plugins).createMain();

    Completer completer = new Completer();
    ReceivePort exitListener = new ReceivePort();
    exitListener.listen((data) {
      completer.complete();
      exitListener.close();
    });

    Uri uri =
        Uri.parse('data:application/dart;charset=utf-8,${Uri.encodeComponent(
        mainSource)}');

    // TODO(pquitslund): update once .packages are supported.
    String packageRoot =
        packageRootPath != null ? packageRootPath : './packages';
    Uri packageUri = new Uri.file(packageRoot);

    Isolate.spawnUri(uri, args, null /* msg */,
        packageRoot: packageUri, onExit: exitListener.sendPort);

    return completer.future;
  }
}
