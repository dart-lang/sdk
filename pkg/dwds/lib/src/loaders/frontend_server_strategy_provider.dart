// Copyright 2024 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/loaders/ddc.dart';
import 'package:dwds/src/loaders/ddc_library_bundle.dart';
import 'package:dwds/src/loaders/require.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/readers/asset_reader.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:path/path.dart' as p;

abstract class FrontendServerStrategyProvider<T extends LoadStrategy> {
  final ReloadConfiguration _configuration;
  final AssetReader _assetReader;
  final PackageUriMapper _packageUriMapper;
  final Future<Map<String, String>> Function() _digestsProvider;
  final String _basePath;
  final BuildSettings _buildSettings;
  final String? _packageConfigPath;

  FrontendServerStrategyProvider(
    this._configuration,
    this._assetReader,
    this._packageUriMapper,
    this._digestsProvider,
    this._buildSettings, {
    this._packageConfigPath,
  }) : _basePath = _assetReader.basePath;

  T get strategy;

  String _removeBasePath(String path) {
    if (_basePath.isEmpty) return path;
    final stripped = stripLeadingSlashes(path);
    return stripLeadingSlashes(stripped.substring(_basePath.length));
  }

  String _addBasePath(String serverPath) => _basePath.isEmpty
      ? stripLeadingSlashes(serverPath)
      : '$_basePath/${stripLeadingSlashes(serverPath)}';

  String _removeJsExtension(String path) =>
      path.endsWith('.js') ? p.withoutExtension(path) : path;

  Future<Map<String, String>> _moduleProvider(
    MetadataProvider metadataProvider,
  ) async => (await metadataProvider.moduleToModulePath).map(
    (key, value) =>
        MapEntry(key, stripLeadingSlashes(_removeJsExtension(value))),
  );

  Future<String?> _moduleForServerPath(
    MetadataProvider metadataProvider,
    String serverPath,
  ) async {
    final modulePathToModule = await metadataProvider.modulePathToModule;
    final relativeServerPath = _removeBasePath(serverPath);
    return modulePathToModule[relativeServerPath];
  }

  Future<String> _serverPathForModule(
    MetadataProvider metadataProvider,
    String module,
  ) async =>
      _addBasePath((await metadataProvider.moduleToModulePath)[module] ?? '');

  Future<String> _sourceMapPathForModule(
    MetadataProvider metadataProvider,
    String module,
  ) async =>
      _addBasePath((await metadataProvider.moduleToSourceMap)[module] ?? '');

  String? _serverPathForAppUri(String appUrl) {
    final appUri = Uri.parse(appUrl);
    if (appUri.isScheme('org-dartlang-app')) {
      return _addBasePath(appUri.path);
    }
    if (appUri.isScheme('package')) {
      final resolved = _packageUriMapper.packageUriToServerPath(appUri);
      if (resolved != null) {
        return resolved;
      }
    }
    return null;
  }

  Future<Map<String, ModuleInfo>> _moduleInfoForProvider(
    MetadataProvider metadataProvider,
  ) async {
    final modules = await metadataProvider.moduleToModulePath;
    final result = <String, ModuleInfo>{};
    for (final module in modules.keys) {
      final modulePath = modules[module]!;
      result[module] = ModuleInfo(
        // TODO: Save locations of full kernel files in ddc metadata.
        // Issue: https://github.com/dart-lang/sdk/issues/43684
        p.setExtension(modulePath, '.full.dill'),
        p.setExtension(modulePath, '.dill'),
      );
    }
    return result;
  }
}

/// Provides a [DdcStrategy] suitable for use with Frontend Server.
class FrontendServerDdcStrategyProvider
    extends FrontendServerStrategyProvider<DdcStrategy> {
  late final DdcStrategy _ddcStrategy = DdcStrategy(
    _configuration,
    _moduleProvider,
    (_) => _digestsProvider(),
    _moduleForServerPath,
    _serverPathForModule,
    _sourceMapPathForModule,
    _serverPathForAppUri,
    _moduleInfoForProvider,
    _assetReader,
    _buildSettings,
    (String _) => null,
    packageConfigPath: _packageConfigPath,
  );

  FrontendServerDdcStrategyProvider(
    super._configuration,
    super._assetReader,
    super._packageUriMapper,
    super._digestsProvider,
    super._buildSettings, {
    super.packageConfigPath,
  });

  @override
  DdcStrategy get strategy => _ddcStrategy;
}

/// Provides a [DdcLibraryBundleStrategy] suitable for use with the Frontend
/// Server.
// ignore: prefer-correct-type-name
class FrontendServerDdcLibraryBundleStrategyProvider
    extends FrontendServerStrategyProvider<DdcLibraryBundleStrategy> {
  late final DdcLibraryBundleStrategy _libraryBundleStrategy;

  FrontendServerDdcLibraryBundleStrategyProvider(
    super._configuration,
    super._assetReader,
    super._packageUriMapper,
    super._digestsProvider,
    super._buildSettings, {
    super.packageConfigPath,
    Uri? reloadedSourcesUri,
    bool injectScriptLoad = true,
  }) {
    _libraryBundleStrategy = DdcLibraryBundleStrategy(
      _configuration,
      _moduleProvider,
      (_) => _digestsProvider(),
      _moduleForServerPath,
      _serverPathForModule,
      _sourceMapPathForModule,
      _serverPathForAppUri,
      _moduleInfoForProvider,
      _assetReader,
      _buildSettings,
      (String _) => null,
      packageConfigPath: _packageConfigPath,
      reloadedSourcesUri: reloadedSourcesUri,
      injectScriptLoad: injectScriptLoad,
    );
  }

  @override
  DdcLibraryBundleStrategy get strategy => _libraryBundleStrategy;
}

/// Provides a [RequireStrategy] suitable for use with Frontend Server.
class FrontendServerRequireStrategyProvider
    extends FrontendServerStrategyProvider<RequireStrategy> {
  late final RequireStrategy _requireStrategy = RequireStrategy(
    _configuration,
    _moduleProvider,
    (_) => _digestsProvider(),
    _moduleForServerPath,
    _serverPathForModule,
    _sourceMapPathForModule,
    _serverPathForAppUri,
    _moduleInfoForProvider,
    _assetReader,
    _buildSettings,
    packageConfigPath: _packageConfigPath,
  );

  FrontendServerRequireStrategyProvider(
    super._configuration,
    super._assetReader,
    super._packageUriMapper,
    super._digestsProvider,
    super._buildSettings, {
    super.packageConfigPath,
  });

  @override
  RequireStrategy get strategy => _requireStrategy;
}
