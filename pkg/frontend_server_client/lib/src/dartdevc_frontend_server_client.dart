// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'dartdevc_bootstrap_amd.dart';
import 'frontend_server_client.dart';
import 'shared.dart';

/// Wraps a [FrontendServerClient] with opinionated web specific functionality,
/// and provides some typical defaults.
///
/// Loads into memory the [CompileResult]s from each [compile] call, and
/// provides access to the up to date sources and source maps.
///
/// Also has the ability to create a bootstrap file for the current entrypoint.
class DartDevcFrontendServerClient implements FrontendServerClient {
  final FrontendServerClient _frontendServerClient;

  final _assets = <String, Uint8List>{};
  final String _entrypoint;

  /// The last compile, or `null` once it has been accepted or rejected.
  CompileResult? _lastResult;

  /// URIs invalidated since the last accepted compile.
  final _invalidatedUris = <Uri>{};

  /// JS module paths updated by the last accepted compile.
  var _updatedJsModules = const <String>[];

  /// The bootstrap js contents, provided in [_assets] at
  /// the path `${_entrypointModule}.js`.
  ///
  /// This is `null` if the module format is not supported for bootstrapping.
  final String? _bootstrapJs;

  /// The generated main module js contents, provided in [_assets] at
  /// the path `${_entrypointModule}.bootstrap.js`.
  ///
  /// This is `null` if the module format is not supported for bootstrapping.
  final String? _mainModuleJs;

  DartDevcFrontendServerClient._(
    this._frontendServerClient,
    this._entrypoint,
    String moduleFormat,
  ) : _bootstrapJs = moduleFormat == 'amd'
          ? generateAmdBootstrapScript(
              requireUrl: 'require.js',
              mapperUrl: 'dart_stack_trace_mapper.js',
              entrypoint: _entrypoint,
            )
          : null,
      _mainModuleJs = moduleFormat == 'amd'
          ? generateAmdMainModule(entrypoint: _entrypoint)
          : null {
    _resetAssets();
  }

  static Future<DartDevcFrontendServerClient> start(
    String entrypoint,
    String outputDillPath, {
    String dartdevcModuleFormat = 'amd',
    bool canaryFeatures = false,
    bool debug = false,
    List<String>? enabledExperiments,
    bool enableHttpUris = false,
    List<String> fileSystemRoots = const [], // For `fileSystemScheme` uris,
    String fileSystemScheme =
        'org-dartlang-root', // Custom scheme for virtual `fileSystemRoots`.
    String? frontendServerPath, // Defaults to the snapshot in the sdk.
    String? librariesSpec,
    String packagesJson = '.dart_tool/package_config.json',
    String? platformKernel, // Defaults to the dartdevc platform from the sdk.
    String? sdkRoot, // Defaults to the current SDK root.
    bool verbose = false,
    bool printIncrementalDependencies = true,
    List<String> additionalArgs = const [],
  }) async {
    final usesDdcLibraryBundle =
        dartdevcModuleFormat == 'ddc' && canaryFeatures;
    final feServer = await FrontendServerClient.start(
      entrypoint,
      outputDillPath,
      platformKernel ?? _dartdevcPlatformKernel(sdkRoot),
      dartdevcModuleFormat: dartdevcModuleFormat,
      debug: debug,
      enabledExperiments: enabledExperiments,
      enableHttpUris: enableHttpUris,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: fileSystemScheme,
      frontendServerPath: frontendServerPath,
      librariesSpec: librariesSpec,
      packagesJson: packagesJson,
      sdkRoot: sdkRoot,
      target: 'dartdevc',
      verbose: verbose,
      printIncrementalDependencies: printIncrementalDependencies,
      additionalArgs: [
        if (canaryFeatures) '--dartdevc-canary',
        if (usesDdcLibraryBundle) ...[
          '--no-js-strongly-connected-components',
          '--experimental-emit-debug-metadata',
        ],
        ...additionalArgs,
      ],
    );
    return DartDevcFrontendServerClient._(
      feServer,
      Uri.parse(entrypoint).path,
      dartdevcModuleFormat,
    );
  }

  /// Returns the current bytes for the asset at [path].
  ///
  /// The [path] should be exactly as it appears in the
  /// [CompileResult.jsManifestOutput] file. Its source map is at
  /// `<path>.map`, and its debug metadata, if emitted, is at
  /// `<path>.metadata`.
  ///
  /// **Note**: Assets are not updated until `accept` is called after a
  /// successful compile. They are not updated if `reject` is called.
  ///
  /// Returns `null` if no asset exists at [path].
  Uint8List? assetBytes(String path) => _assets[path];

  /// The contents of a JS file capable of bootstrapping the current app.
  ///
  /// TODO: implement
  String bootstrapJs() => throw UnimplementedError();

  /// Merged debug metadata, with one JSON object per line.
  ///
  /// Empty if the frontend server doesn't pass:
  /// `--experimental-emit-debug-metadata`
  String get mergedMetadata => [
    for (final MapEntry(:key, :value) in _assets.entries)
      if (key.endsWith('.metadata')) utf8.decode(value),
  ].join('\n');

  /// `reloaded_sources.json` entries for the JS modules updated by the last
  /// accepted compile.
  ///
  /// Format: `{"src": <path>, "module": <name>, "libraries": [<uri>]}`
  List<Map<String, Object>> get reloadedSources => [
    for (final path in _updatedJsModules)
      if (_assets['$path.metadata'] case final metadata?)
        _reloadedSourceEntry(path, metadata),
  ];

  /// Updates [_assets] with [result], and returns the paths of the updated JS
  /// modules.
  List<String> _updateAssets(CompileResult result) {
    if (result.dillOutput == null) {
      return const [];
    }
    final manifest =
        jsonDecode(File(result.jsManifestOutput!).readAsStringSync())
            as Map<String, dynamic>;
    final sourceBytes = File(result.jsSourcesOutput!).readAsBytesSync();
    final sourceMapBytes = File(result.jsSourceMapsOutput!).readAsBytesSync();
    Uint8List? metadataBytes;

    for (final entry in manifest.entries) {
      final offsets = entry.value as Map<String, dynamic>;
      final sourceOffsets = offsets['code'] as List;
      _assets[entry.key] = sourceBytes.sublist(
        sourceOffsets[0] as int,
        sourceOffsets[1] as int,
      );
      final sourceMapOffsets = offsets['sourcemap'] as List;
      _assets['${entry.key}.map'] = sourceMapBytes.sublist(
        sourceMapOffsets[0] as int,
        sourceMapOffsets[1] as int,
      );
      final metadataOffsets = offsets['metadata'] as List?;
      if (metadataOffsets != null) {
        metadataBytes ??= File(result.jsMetadataOutput!).readAsBytesSync();
        _assets['${entry.key}.metadata'] = metadataBytes.sublist(
          metadataOffsets[0] as int,
          metadataOffsets[1] as int,
        );
      }
    }
    return manifest.keys.toList();
  }

  /// The `reloaded_sources.json` entry for the JS module at [path] with the
  /// debug [metadata].
  static Map<String, Object> _reloadedSourceEntry(
    String path,
    Uint8List metadata,
  ) {
    final json = jsonDecode(utf8.decode(metadata)) as Map<String, dynamic>;
    return {
      'src': path,
      'module': json['name'] as String,
      'libraries': [
        for (final library in json['libraries'] as List)
          (library as Map<String, dynamic>)['importUri'] as String,
      ],
    };
  }

  @override
  Future<CompileResult> compile([List<Uri>? invalidatedUris]) async {
    _invalidatedUris.addAll(invalidatedUris ?? const []);
    return _lastResult = await _frontendServerClient.compile(
      _invalidatedUris.toList(),
    );
  }

  @override
  Future<CompileResult> recompileRestart(List<Uri> invalidatedUris) async {
    _invalidatedUris.addAll(invalidatedUris);
    return _lastResult = await _frontendServerClient.recompileRestart(
      _invalidatedUris.toList(),
    );
  }

  @override
  Future<CompileResult> compileExpression({
    required String expression,
    required List<String> definitions,
    required bool isStatic,
    required String klass,
    required String libraryUri,
    required List<String> typeDefinitions,
  }) => throw UnsupportedError(
    'Use `compileExpressionToJs` for dartdevc based clients',
  );

  @override
  Future<CompileResult> compileExpressionToJs({
    required String expression,
    required int column,
    required Map<String, String> jsFrameValues,
    required Map<String, String> jsModules,
    required String libraryUri,
    required int line,
    required String moduleName,
    String? scriptUri,
  }) => _frontendServerClient.compileExpressionToJs(
    expression: expression,
    column: column,
    jsFrameValues: jsFrameValues,
    jsModules: jsModules,
    libraryUri: libraryUri,
    line: line,
    moduleName: moduleName,
    scriptUri: scriptUri,
  );

  @override
  void accept() {
    _frontendServerClient.accept();
    if (_lastResult != null) _updatedJsModules = _updateAssets(_lastResult!);
    _invalidatedUris.clear();
    _lastResult = null;
  }

  @override
  Future<void> reject() async {
    await _frontendServerClient.reject();
    _lastResult = null;
  }

  @override
  void reset() {
    _frontendServerClient.reset();
    _invalidatedUris.clear();
    _resetAssets();
  }

  @override
  bool kill({ProcessSignal processSignal = ProcessSignal.sigterm}) =>
      _frontendServerClient.kill();

  @override
  Future<int> shutdown() => _frontendServerClient.shutdown();

  /// Clears any previously compiled assets and adds the bootstrap modules as
  /// assets if available.
  void _resetAssets() {
    _assets.clear();
    final bootstrapJs = _bootstrapJs;
    if (bootstrapJs != null) {
      _assets['$_entrypoint.js'] = Uint8List.fromList(utf8.encode(bootstrapJs));
    }
    final mainModuleJs = _mainModuleJs;
    if (mainModuleJs != null) {
      _assets['$_entrypoint.bootstrap.js'] = Uint8List.fromList(
        utf8.encode(mainModuleJs),
      );
    }
  }
}

String _dartdevcPlatformKernel(String? sdkRoot) => p
    .toUri(p.join(sdkRoot ?? sdkDir, 'lib', '_internal', 'ddc_outline.dill'))
    .toString();
