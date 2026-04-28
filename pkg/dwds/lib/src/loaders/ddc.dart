// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dwds/src/debugging/dart_runtime_debugger.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/readers/asset_reader.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

String removeJsExtension(String path) =>
    path.endsWith('.js') ? p.withoutExtension(path) : path;

String addJsExtension(String path) => '$path.js';

/// JavaScript snippet to determine the base URL of the current path.
const baseUrlScript = '''
var baseUrl = (function () {
  // Attempt to detect --precompiled mode for tests, and set the base url
  // appropriately, otherwise set it to '/'.
  var pathParts = location.pathname.split("/");
  if (pathParts[0] == "") {
    pathParts.shift();
  }
  if (pathParts.length > 1 && pathParts[1] == "test") {
    return "/" + pathParts.slice(0, 2).join("/") + "/";
  }
  // Attempt to detect base url using <base href> html tag
  // base href should start and end with "/"
  if (typeof document !== 'undefined') {
    var el = document.getElementsByTagName('base');
    if (el && el[0] && el[0].getAttribute("href") && el[0].getAttribute
    ("href").startsWith("/") && el[0].getAttribute("href").endsWith("/")){
      return el[0].getAttribute("href");
    }
  }
  // return default value
  return "/";
}());
''';

/// A load strategy for the DDC module system.
class DdcStrategy extends LoadStrategy {
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

  DdcStrategy(
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
    super.packageConfigPath,
  }) : super(assetReader);

  @override
  Handler get handler => (request) async {
    // TODO(markzipan): Implement a hot restarter that uses digests for
    // the DDC module system.
    return Response.notFound(request.url.toString());
  };

  @override
  String get id => 'ddc';

  @override
  String get moduleFormat => 'ddc';

  @override
  String get loadLibrariesModule => 'ddc_module_loader.ddk.js';

  @override
  String get loadModuleSnippet => 'dart_library.import';

  @override
  late final DartRuntimeDebugger dartRuntimeDebugger = DartRuntimeDebugger(
    loadStrategy: this,
    useLibraryBundleExpression: false,
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
      scripts.add(<String, String>{'src': '$path.js', 'id': name});
    });
    return '''
$baseUrlScript
var scripts = ${const JsonEncoder.withIndent(" ").convert(scripts)};
window.\$dartLoader.loadConfig.loadScriptFn = function(loader) {
  loader.addScriptsToQueue(scripts, null);
  loader.loadEnqueuedModules();
};
window.\$dartLoader.loader.nextAttempt();
''';
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
