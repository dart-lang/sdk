// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/loaders/ddc_library_bundle.dart';
import 'package:dwds/src/loaders/require.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/readers/asset_reader.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Provides a [RequireStrategy] suitable for use with `package:build_runner`.
class BuildRunnerRequireStrategyProvider with BuildRunnerStrategyProviderMixin {
  @override
  final _logger = Logger('BuildRunnerRequireStrategyProvider');

  @override
  final ReloadConfiguration _configuration;
  @override
  final AssetReader _assetReader;
  @override
  final BuildSettings _buildSettings;
  @override
  final String? _packageConfigPath;

  late final RequireStrategy _requireStrategy = RequireStrategy(
    _configuration,
    _moduleProvider,
    _digestsProvider,
    _moduleForServerPath,
    _serverPathForModule,
    _sourceMapPathForModule,
    _serverPathForAppUri,
    _moduleInfoForProvider,
    _assetReader,
    _buildSettings,
    packageConfigPath: _packageConfigPath,
  );

  BuildRunnerRequireStrategyProvider(
    this._configuration,
    this._assetReader,
    this._buildSettings, {
    this._packageConfigPath,
  });

  RequireStrategy get strategy => _requireStrategy;
}

/// Provides a [DdcLibraryBundleStrategy] suitable for use with
/// `package:build_runner`.
class BuildRunnerDdcLibraryBundleStrategyProvider
    with BuildRunnerStrategyProviderMixin {
  @override
  final _logger = Logger('BuildRunnerDdcLibraryBundleStrategyProvider');

  @override
  final ReloadConfiguration _configuration;
  @override
  final AssetReader _assetReader;
  @override
  final BuildSettings _buildSettings;
  @override
  final String? _packageConfigPath;

  late final DdcLibraryBundleStrategy _strategy = DdcLibraryBundleStrategy(
    _configuration,
    _moduleProvider,
    _digestsProvider,
    _moduleForServerPath,
    _serverPathForModule,
    _sourceMapPathForModule,
    _serverPathForAppUri,
    _moduleInfoForProvider,
    _assetReader,
    _buildSettings,
    (path) => null, // g3RelativePath
    packageConfigPath: _packageConfigPath,
    injectScriptLoad: injectScriptLoad,
    reloadedSourcesUri: _reloadedSourcesUri,
  );

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
  final Uri? _reloadedSourcesUri;

  /// When enabled, injects the script loader into the bootstrapper from
  /// within DWDS. This is used throughout Flutter Web but may be disabled
  /// for specific workflows where the script loader is managed separately.
  final bool injectScriptLoad;

  BuildRunnerDdcLibraryBundleStrategyProvider(
    this._configuration,
    this._assetReader,
    this._buildSettings, {
    this._packageConfigPath,
    this._reloadedSourcesUri,
    this.injectScriptLoad = false,
  });

  DdcLibraryBundleStrategy get strategy => _strategy;
}

mixin BuildRunnerStrategyProviderMixin {
  Logger get _logger;
  // ignore: unused_element
  ReloadConfiguration get _configuration;
  // ignore: unused_element
  AssetReader get _assetReader;
  // ignore: unused_element
  BuildSettings get _buildSettings;
  // ignore: unused_element
  String? get _packageConfigPath;

  Future<Map<String, String>> _digestsProvider(
    MetadataProvider metadataProvider,
  ) async {
    final modules = await metadataProvider.modulePathToModule;

    final digestsPath = metadataProvider.entrypoint.replaceAll(
      '.dart.bootstrap.js',
      '.digests',
    );
    final body = await _assetReader.metadataContents(digestsPath);
    if (body == null) {
      throw StateError('Could not read digests at path: $digestsPath');
    }
    final digests = json.decode(body) as Map<String, dynamic>;

    for (final key in digests.keys) {
      if (!modules.containsKey(key)) {
        _logger.warning('Digest key $key is not a module name.');
      }
    }

    return {
      for (final entry in digests.entries)
        if (modules.containsKey(entry.key))
          modules[entry.key]!: entry.value as String,
    };
  }

  Future<Map<String, String>> _moduleProvider(
    MetadataProvider metadataProvider,
  ) async => (await metadataProvider.moduleToModulePath).map(
    (key, value) =>
        MapEntry(key, stripTopLevelDirectory(removeJsExtension(value))),
  );

  Future<String?> _moduleForServerPath(
    MetadataProvider metadataProvider,
    String serverPath,
  ) async {
    final modulePathToModule = await metadataProvider.modulePathToModule;
    final relativePath = stripLeadingSlashes(serverPath);
    for (final e in modulePathToModule.entries) {
      if (stripTopLevelDirectory(e.key) == relativePath) {
        return e.value;
      }
    }
    return null;
  }

  Future<String?> _serverPathForModule(
    MetadataProvider metadataProvider,
    String module,
  ) async {
    final modulePath = (await metadataProvider.moduleToModulePath)[module];
    return modulePath == null ? null : stripTopLevelDirectory(modulePath);
  }

  Future<String?> _sourceMapPathForModule(
    MetadataProvider metadataProvider,
    String module,
  ) async {
    final sourceMapPath = (await metadataProvider.moduleToSourceMap)[module];
    return sourceMapPath == null ? null : stripTopLevelDirectory(sourceMapPath);
  }

  String? _serverPathForAppUri(String appUrl) {
    final appUri = Uri.parse(appUrl);
    if (appUri.isScheme('org-dartlang-app')) {
      // We skip the root from which we are serving.
      return appUri.pathSegments.skip(1).join('/');
    }
    if (appUri.isScheme('package')) {
      return '/packages/${appUri.path}';
    }
    return null;
  }

  Future<Map<String, ModuleInfo>> _moduleInfoForProvider(
    MetadataProvider metadataProvider,
  ) async {
    final modules = await metadataProvider.modules;
    final result = <String, ModuleInfo>{};
    for (final module in modules) {
      final serverPath = await _serverPathForModule(metadataProvider, module);
      if (serverPath == null) {
        _logger.warning('No module info found for module $module');
      } else {
        result[module] = ModuleInfo(
          // TODO: Save locations of full kernel files in ddc metadata.
          // Issue: https://github.com/dart-lang/sdk/issues/43684
          // TODO: Change these to URIs instead of paths when the SDK supports
          // it.
          p.setExtension(serverPath, '.full.dill'),
          p.setExtension(serverPath, '.dill'),
        );
      }
    }
    return result;
  }
}
