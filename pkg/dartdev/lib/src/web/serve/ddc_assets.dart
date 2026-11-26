// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dartdev/src/web/serve/ddc_compiler.dart';
import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:path/path.dart' as p;

// URL paths of the scripts that start the app, next to the page that loads
// the bootstrap script. The bootstrap script's path depends on the entrypoint
// (`main.dart.js` for `web/main.dart`), see `DdcAssets.bootstrapPath`.
// TODO(https://github.com/dart-lang/sdk/issues/64865): Simplify this load
// chain (for example, no separate on-load-end script) with the DWDS rewrite.
const _mainModulePath = 'main_module.bootstrap.js';
const _onLoadEndPath = 'on_load_end_bootstrap.js';
const _moduleLoaderPath = 'ddc_module_loader.js';
const _stackTraceMapperPath = 'dart_stack_trace_mapper.js';
const _sdkPath = 'dart_sdk.js';

/// The `dart_sdk.js` that the SDK at [sdkRoot] ships for DDC's library bundle
/// format (compiled with `--canary`), with its source map next to it.
String _shippedSdkJsPath(String sdkRoot) =>
    p.join(sdkRoot, 'lib', 'dev_compiler', 'canary', 'sdk', 'dart_sdk.js');

/// The files a browser needs to run an app compiled by DDC: DDC's startup
/// scripts and the compiled modules, by URL path relative to the server root
/// (the `web/` directory), without a leading `/`.
///
/// The page (`web/index.html`) loads the bootstrap script, which loads, in
/// order:
/// 1. `ddc_module_loader.js` and `dart_stack_trace_mapper.js` (SDK files).
/// 2. `dart_sdk.js`: the Dart core libraries.
/// 3. `main_module.bootstrap.js`: lists the app's modules for the loader and,
///    once they're loaded, loads `on_load_end_bootstrap.js`, which runs
///    `main()`.
/// 4. The app's modules, compiled by [DdcCompiler].
class DdcAssets {
  /// The URL path of the script that `web/index.html` loads to start the app:
  /// the entrypoint's URL-encoded file name plus `.js`, such as `main.dart.js`.
  final String bootstrapPath;

  final DdcCompiler _compiler;

  /// Files that don't change while the app runs: the bootstrap scripts and
  /// the SDK scripts.
  final Map<String, Uint8List> _fixedFiles;

  DdcAssets._(this.bootstrapPath, this._compiler, this._fixedFiles);

  /// Loads the SDK scripts and generates the bootstrap scripts for the app
  /// that [compiler] compiles.
  ///
  /// [sdkJsPath] is the `dart_sdk.js` to serve, with its source map next to
  /// it. It defaults to the one [DdcCompiler.sdkRoot] ships. Pass another one,
  /// such as the build's `gen/utils/ddc/canary/sdk/ddc/dart_sdk.js`, to test
  /// DDC changes without rebuilding the SDK. It must be compiled with the same
  /// version of the Dart SDK and DDC, and with the same arguments, as the
  /// app's libraries.
  static Future<DdcAssets> load(
    DdcCompiler compiler, {
    // TODO(https://github.com/dart-lang/sdk/issues/64864): Add a hidden
    // `dart serve` option for this. Only tests pass it today.
    String? sdkJsPath,
  }) async {
    final sdk = await DdcLibraryBundleSdkAssets.load(
      sdkRoot: compiler.sdkRoot,
      sdkJsPath: sdkJsPath ?? _shippedSdkJsPath(compiler.sdkRoot),
    );
    final bootstrapPath = '${p.url.basename(compiler.entrypointUri)}.js';
    return DdcAssets._(bootstrapPath, compiler, {
      bootstrapPath: utf8.encode(
        generateDdcLibraryBundleBootstrapScript(
          ddcModuleLoaderUrl: _moduleLoaderPath,
          mapperUrl: _stackTraceMapperPath,
          sdkUrl: _sdkPath,
          mainModuleUrl: _mainModulePath,
        ),
      ),
      _onLoadEndPath: utf8.encode(generateDdcLibraryBundleOnLoadEndBootstrap()),
      _moduleLoaderPath: sdk.moduleLoader,
      _stackTraceMapperPath: sdk.stackTraceMapper,
      _sdkPath: sdk.sdkJs,
      '$_sdkPath.map': sdk.sdkJsMap,
    });
  }

  /// The file at the URL [path], or `null` if there is none.
  ///
  /// [path] is relative to the server root, without a leading `/`.
  Uint8List? lookupFileByPath(String path) {
    if (_fixedFiles[path] case final file?) return file;
    if (path == _mainModulePath) return _mainModule();
    return _compiler.compiledFile(path);
  }

  /// The main module, followed by the script that loads the app's modules.
  ///
  /// Generated on each request, because the list of modules changes when
  /// libraries are added or removed. When DWDS serves the app, it adds the
  /// module list itself.
  Uint8List _mainModule() {
    final mainModule = generateDdcLibraryBundleMainModule(
      entrypoint: _compiler.entrypointUri,
      onLoadEndBootstrap: _onLoadEndPath,
    );
    final scriptLoader = _scriptLoader(_compiler.mergedMetadata);
    return utf8.encode('$mainModule\n$scriptLoader');
  }
}

/// A script that tells DDC's module loader which of the app's modules to load.
///
/// The bootstrap scripts load `dart_sdk.js` and the main module, but not the
/// app's own modules (one JS file per library). This script lists them, from
/// [mergedMetadata] (see [DdcCompiler.mergedMetadata]), and starts loading
/// them. Once they're loaded, the main module runs `main()`.
///
/// Module URLs are relative to the directory serving the bootstrap script, so
/// they also work when the app is served under a base path.
// TODO(https://github.com/dart-lang/sdk/issues/64662): Remove this once
// `dart serve` uses DWDS, which adds its own copy to the main module.
String _scriptLoader(String mergedMetadata) {
  final scripts = [
    for (final line in const LineSplitter().convert(mergedMetadata))
      if (line.isNotEmpty)
        if (jsonDecode(line) case {
          'name': final String name,
          'moduleUri': final String moduleUri,
        })
          {'src': moduleUri.replaceFirst(RegExp('^/+'), ''), 'id': name},
  ];
  return '''
(function() {
  const scripts = ${jsonEncode(scripts)};
  window.\$dartLoader.loadConfig.loadScriptFn = function(loader) {
    loader.addScriptsToQueue(scripts, null);
    loader.loadEnqueuedModules();
  };
  window.\$dartLoader.loader.nextAttempt();
})();
''';
}
