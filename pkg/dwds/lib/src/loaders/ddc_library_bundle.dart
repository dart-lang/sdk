// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dwds/src/debugging/dart_runtime_debugger.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/loaders/ddc.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/readers/asset_reader.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:shelf/shelf.dart';

// TODO(srujzs): This is mostly a copy of `DdcStrategy`. Some of the
// functionality in here may not make sense with the library bundle format yet.
class DdcLibraryBundleStrategy extends LoadStrategy {
  @override
  final ReloadConfiguration reloadConfiguration;

  /// Returns a map of module name to corresponding server path (excluding .js)
  /// for the provided Dart application entrypoint.
  ///
  /// For example:
  ///
  ///   web/main -> main.ddc
  ///   packages/path/path -> packages/path/path.ddc
  ///
  final Future<Map<String, String>> Function(MetadataProvider metadataProvider)
  _moduleProvider;

  /// Returns a map of module name to corresponding digest value.
  ///
  /// For example:
  ///
  ///   web/main -> 8363b363f74b41cac955024ab8b94a3f
  ///   packages/path/path -> d348c2a4647e998011fe305f74f22961
  ///
  final Future<Map<String, String>> Function(MetadataProvider metadataProvider)
  // ignore: unused_field
  _digestsProvider;

  /// Returns the module for the corresponding server path.
  ///
  /// For example:
  ///
  /// /packages/path/path.ddc.js -> packages/path/path
  ///
  final Future<String?> Function(
    MetadataProvider metadataProvider,
    String sourcePath,
  )
  _moduleForServerPath;

  /// Returns a map from module id to module info.
  ///
  /// For example:
  ///
  ///   web/main -> {main.ddc.full.dill, main.ddc.dill}
  ///
  final Future<Map<String, ModuleInfo>> Function(
    MetadataProvider metadataProvider,
  )
  _moduleInfoForProvider;

  /// Returns the server path for the provided module.
  ///
  /// For example:
  ///
  ///   web/main -> main.ddc.js
  ///
  final Future<String?> Function(
    MetadataProvider metadataProvider,
    String module,
  )
  _serverPathForModule;

  /// Returns the source map path for the provided module.
  ///
  /// For example:
  ///
  ///   web/main -> main.ddc.js.map
  ///
  final Future<String?> Function(
    MetadataProvider metadataProvider,
    String module,
  )
  _sourceMapPathForModule;

  /// Returns the server path for the app uri.
  ///
  /// For example:
  ///
  ///   org-dartlang-app://web/main.dart -> main.dart
  ///
  /// Will return `null` if the provided uri is not
  /// an app URI.
  final String? Function(String appUri) _serverPathForAppUri;

  /// Returns the relative path in google3, determined by the `absolutePath`.
  ///
  /// Returns `null` if not a google3 app.
  final String? Function(String absolutePath) _g3RelativePath;

  final BuildSettings _buildSettings;

  /// The [Uri] of the file that contains a JSONified list of maps which follows
  /// the following format:
  ///
  /// ```json
  /// [
  ///   {
  ///     "src": "<base_uri>/<file_name>",
  ///     "module": "<module_name>",
  ///     "libraries": ["<lib1>", "<lib2>"],
  ///   },
  /// ]
  /// ```
  ///
  /// `src`: A string that corresponds to the file path containing a DDC library
  /// bundle.
  /// `module`: The name of the library bundle in `src`.
  /// `libraries`: An array of strings containing the libraries that were
  /// compiled in `src`.
  ///
  /// This is needed for hot reloads and restarts in order to tell the module
  /// loader what files need to be loaded and what libraries need to be
  /// reloaded. The contents of the file this [Uri] points to should be updated
  /// whenever a hot reload or hot restart is executed.
  final Uri? reloadedSourcesUri;

  /// When enabled, injects the script loader into the bootstrapper from
  /// within DWDS. This is used throughout Flutter Web but may be disabled
  /// for specific workflows where the script loader is managed separately.
  final bool injectScriptLoad;

  DdcLibraryBundleStrategy(
    this.reloadConfiguration,
    this._moduleProvider,
    this._digestsProvider,
    this._moduleForServerPath,
    this._serverPathForModule,
    this._sourceMapPathForModule,
    this._serverPathForAppUri,
    this._moduleInfoForProvider,
    AssetReader assetReader,
    this._buildSettings,
    this._g3RelativePath, {
    String? packageConfigPath,
    this.reloadedSourcesUri,
    this.injectScriptLoad = true,
  }) : super(assetReader, packageConfigPath: packageConfigPath);

  @override
  Handler get handler => (request) async {
    // TODO(markzipan): Implement a hot restarter that uses digests for
    // the DDC module system.
    return Response.notFound(request.url.toString());
  };

  @override
  String get id => 'ddc-library-bundle';

  // DDC doesn't have a 'ddc-library-bundle' format flag. Instead, it treats the
  // combination of the DDC module format and canary mode as the DDC library
  // bundle format, so we just pass 'ddc' here.
  @override
  String get moduleFormat => 'ddc';

  @override
  String get loadLibrariesModule => 'ddc_module_loader.ddk.js';

  // TODO(srujzs): Refactor code that uses this to avoid loading individual
  // libraries, as that's no longer supported in the new module format.
  @override
  String get loadModuleSnippet =>
      "function() { throw new Error('LoadStrategy.loadModuleSnippet is used. "
      "This is currently unsupported in the DDC library bundle format.'); }";

  @override
  late final DartRuntimeDebugger dartRuntimeDebugger = DartRuntimeDebugger(
    loadStrategy: this,
    useLibraryBundleExpression: true,
  );

  @override
  BuildSettings get buildSettings => _buildSettings;

  @override
  Future<String> bootstrapFor(String entrypoint) async =>
      await _ddcLoaderSetup(entrypoint);

  @override
  String loadClientSnippet(String clientScript) =>
      'window.\$dartLoader.forceLoadModule("$clientScript");\n';

  Future<String> _ddcLoaderSetup(String entrypoint) async {
    final metadataProvider = metadataProviderFor(entrypoint);
    final modulePaths = await _moduleProvider(metadataProvider);
    final scripts = <Map<String, String?>>[];
    modulePaths.forEach((name, path) {
      var id = name;
      if (id.startsWith('package:')) {
        id = id.replaceFirst('package:', 'packages/');
        // Remove trailing '.dart' from script ids.
        if (id.endsWith('.dart')) {
          id = id.substring(0, id.length - '.dart'.length);
        }
      }
      scripts.add(<String, String>{'src': '$path.js', 'id': id});
    });
    // Flutter always depends on the injected loader, but some canary-enabled
    // Frontend Server implementations load scripts via a separate pathway.
    final scriptLoader = buildSettings.isFlutterApp || injectScriptLoad
        ? '''
var scripts = ${const JsonEncoder.withIndent(" ").convert(scripts)};
window.\$dartLoader.loadConfig.loadScriptFn = function(loader) {
  loader.addScriptsToQueue(scripts, null);
  loader.loadEnqueuedModules();
};
window.\$dartLoader.loader.nextAttempt();
'''
        : '';
    return '$baseUrlScript\n$scriptLoader';
  }

  @override
  Future<String?> moduleForServerPath(String entrypoint, String serverPath) =>
      _moduleForServerPath(metadataProviderFor(entrypoint), serverPath);

  @override
  Future<Map<String, ModuleInfo>> moduleInfoForEntrypoint(String entrypoint) =>
      _moduleInfoForProvider(metadataProviderFor(entrypoint));

  @override
  Future<String?> serverPathForModule(String entrypoint, String module) =>
      _serverPathForModule(metadataProviderFor(entrypoint), module);

  @override
  Future<String?> sourceMapPathForModule(String entrypoint, String module) =>
      _sourceMapPathForModule(metadataProviderFor(entrypoint), module);

  @override
  String? serverPathForAppUri(String appUri) => _serverPathForAppUri(appUri);

  @override
  String? g3RelativePath(String absolutePath) => _g3RelativePath(absolutePath);
}
