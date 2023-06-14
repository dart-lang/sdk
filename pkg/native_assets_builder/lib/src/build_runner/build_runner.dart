// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

import '../package_layout/package_layout.dart';
import '../utils/run_process.dart';
import 'build_planner.dart';

typedef DependencyMetadata = Map<String, Metadata>;

/// The programmatic API to be used by Dart launchers to invoke native builds.
///
/// These methods are invoked by launchers such as dartdev (for `dart run`)
/// and flutter_tools (for `flutter run` and `flutter build`).
class NativeAssetsBuildRunner {
  final Logger logger;
  final Uri dartExecutable;

  NativeAssetsBuildRunner({
    required this.logger,
    required this.dartExecutable,
  });

  final _metadata = <Target, DependencyMetadata>{};

  /// [workingDirectory] is expected to contain `.dart_tool`.
  ///
  /// This method is invoked by launchers such as dartdev (for `dart run`) and
  /// flutter_tools (for `flutter run` and `flutter build`).
  ///
  /// Completes the future with an error if the build fails.
  Future<List<Asset>> build({
    required LinkModePreference linkModePreference,
    required Target target,
    required Uri workingDirectory,
    required BuildMode buildMode,
    CCompilerConfig? cCompilerConfig,
    IOSSdk? targetIOSSdk,
    int? targetAndroidNdkApi,
    required bool includeParentEnvironment,
  }) async {
    assert(_metadata.isEmpty);
    final packageLayout =
        await PackageLayout.fromRootPackageRoot(workingDirectory);
    final packagesWithNativeAssets =
        await packageLayout.packagesWithNativeAssets;
    final planner = await NativeAssetsBuildPlanner.fromRootPackageRoot(
      rootPackageRoot: packageLayout.rootPackageRoot,
      packagesWithNativeAssets: packagesWithNativeAssets,
      dartExecutable: Uri.file(Platform.resolvedExecutable),
    );
    final plan = planner.plan();
    final assetList = <Asset>[];
    for (final package in plan) {
      final dependencyMetadata = _metadataForPackage(
        packageGraph: planner.packageGraph,
        packageName: package.name,
        targetMetadata: _metadata[target],
      );
      final config = await _cliConfig(
        packageName: package.name,
        packageRoot: packageLayout.packageRoot(package.name),
        target: target,
        buildMode: buildMode,
        linkMode: linkModePreference,
        buildParentDir: packageLayout.dartToolNativeAssetsBuilder,
        dependencyMetadata: dependencyMetadata,
        cCompilerConfig: cCompilerConfig,
        targetIOSSdk: targetIOSSdk,
        targetAndroidNdkApi: targetAndroidNdkApi,
      );
      final assets = await _buildPackageCached(
        config,
        packageLayout.packageConfigUri,
        workingDirectory,
        includeParentEnvironment,
      );
      assetList.addAll(assets);
    }
    return assetList;
  }

  /// [workingDirectory] is expected to contain `.dart_tool`.
  ///
  /// This method is invoked by launchers such as dartdev (for `dart run`) and
  /// flutter_tools (for `flutter run` and `flutter build`).
  ///
  /// Completes the future with an error if the build fails.
  Future<List<Asset>> dryRun({
    required LinkModePreference linkModePreference,
    required OS targetOs,
    required Uri workingDirectory,
    required bool includeParentEnvironment,
  }) async {
    assert(_metadata.isEmpty);
    final packageLayout =
        await PackageLayout.fromRootPackageRoot(workingDirectory);
    final packagesWithNativeAssets =
        await packageLayout.packagesWithNativeAssets;
    final planner = await NativeAssetsBuildPlanner.fromRootPackageRoot(
      rootPackageRoot: packageLayout.rootPackageRoot,
      packagesWithNativeAssets: packagesWithNativeAssets,
      dartExecutable: Uri.file(Platform.resolvedExecutable),
    );
    final plan = planner.plan();
    final assetList = <Asset>[];
    for (final package in plan) {
      final config = await _cliConfigDryRun(
        packageName: package.name,
        packageRoot: packageLayout.packageRoot(package.name),
        targetOs: targetOs,
        linkMode: linkModePreference,
        buildParentDir: packageLayout.dartToolNativeAssetsBuilder,
      );
      final assets = await _buildPackage(
        config,
        packageLayout.packageConfigUri,
        workingDirectory,
        includeParentEnvironment,
        dryRun: true,
      );
      assetList.addAll(assets);
    }
    return assetList;
  }

  Future<List<Asset>> _buildPackageCached(
    BuildConfig config,
    Uri packageConfigUri,
    Uri workingDirectory,
    bool includeParentEnvironment,
  ) async {
    final packageName = config.packageName;
    final outDir = config.outDir;
    if (!await Directory.fromUri(outDir).exists()) {
      await Directory.fromUri(outDir).create(recursive: true);
    }

    final buildOutput = await BuildOutput.readFromFile(outDir: outDir);
    final lastBuilt = buildOutput?.timestamp.roundDownToSeconds() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final dependencies = buildOutput?.dependencies;
    final lastChange = await dependencies?.lastModified() ?? DateTime.now();

    if (lastBuilt.isAfter(lastChange)) {
      logger.info('Skipping build for $packageName in $outDir. '
          'Last build on $lastBuilt, last input change on $lastChange.');
      // All build flags go into [outDir]. Therefore we do not have to check
      // here whether the config is equal.

      setMetadata(config.target, packageName, buildOutput?.metadata);
      return buildOutput!.assets;
    }

    return _buildPackage(
      config,
      packageConfigUri,
      workingDirectory,
      includeParentEnvironment,
      dryRun: false,
    );
  }

  Future<List<Asset>> _buildPackage(
    BuildConfig config,
    Uri packageConfigUri,
    Uri workingDirectory,
    bool includeParentEnvironment, {
    required bool dryRun,
  }) async {
    final outDir = config.outDir;
    final configFile = outDir.resolve('config.yaml');
    final buildDotDart = config.packageRoot.resolve('build.dart');
    final configFileContents = config.toYamlString();
    logger.info('config.yaml contents: $configFileContents');
    await File.fromUri(configFile).writeAsString(configFileContents);
    final buildOutputFile = File.fromUri(outDir.resolve(BuildOutput.fileName));
    if (await buildOutputFile.exists()) {
      // Ensure we'll never read outdated build results.
      await buildOutputFile.delete();
    }
    await runProcess(
      workingDirectory: workingDirectory,
      executable: dartExecutable,
      arguments: [
        '--packages=${packageConfigUri.toFilePath()}',
        buildDotDart.toFilePath(),
        '--config=${configFile.toFilePath()}',
      ],
      logger: logger,
      includeParentEnvironment: includeParentEnvironment,
      expectedExitCode: 0,
      throwOnUnexpectedExitCode: true,
    );
    final buildOutput = await BuildOutput.readFromFile(outDir: outDir);
    if (!dryRun) {
      setMetadata(config.target, config.packageName, buildOutput?.metadata);
    }
    return buildOutput?.assets ?? [];
  }

  void setMetadata(Target target, String packageName, Metadata? metadata) {
    if (metadata == null) {
      return;
    }
    _metadata[target] ??= {};
    _metadata[target]![packageName] = metadata;
  }

  static Future<BuildConfig> _cliConfig({
    required String packageName,
    required Uri packageRoot,
    required Target target,
    IOSSdk? targetIOSSdk,
    int? targetAndroidNdkApi,
    required BuildMode buildMode,
    required LinkModePreference linkMode,
    required Uri buildParentDir,
    CCompilerConfig? cCompilerConfig,
    DependencyMetadata? dependencyMetadata,
  }) async {
    final buildDirName = BuildConfig.checksum(
      packageRoot: packageRoot,
      targetOs: target.os,
      targetArchitecture: target.architecture,
      buildMode: buildMode,
      linkModePreference: linkMode,
      targetIOSSdk: targetIOSSdk,
      cCompiler: cCompilerConfig,
      dependencyMetadata: dependencyMetadata,
      targetAndroidNdkApi: targetAndroidNdkApi,
    );
    final outDirUri = buildParentDir.resolve('$buildDirName/');
    final outDir = Directory.fromUri(outDirUri);
    if (!await outDir.exists()) {
      // TODO(https://dartbug.com/50565): Purge old or unused folders.
      await outDir.create(recursive: true);
    }
    return BuildConfig(
      outDir: outDirUri,
      packageRoot: packageRoot,
      targetOs: target.os,
      targetArchitecture: target.architecture,
      buildMode: buildMode,
      linkModePreference: linkMode,
      targetIOSSdk: targetIOSSdk,
      cCompiler: cCompilerConfig,
      dependencyMetadata: dependencyMetadata,
      targetAndroidNdkApi: targetAndroidNdkApi,
    );
  }

  static Future<BuildConfig> _cliConfigDryRun({
    required String packageName,
    required Uri packageRoot,
    required OS targetOs,
    required LinkModePreference linkMode,
    required Uri buildParentDir,
  }) async {
    final String buildDirName = 'dry_run_${targetOs}_$linkMode';
    final outDirUri = buildParentDir.resolve('$buildDirName/');
    final outDir = Directory.fromUri(outDirUri);
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    return BuildConfig.dryRun(
      outDir: outDirUri,
      packageRoot: packageRoot,
      targetOs: targetOs,
      linkModePreference: linkMode,
    );
  }

  DependencyMetadata? _metadataForPackage({
    required PackageGraph packageGraph,
    required String packageName,
    DependencyMetadata? targetMetadata,
  }) {
    if (targetMetadata == null) {
      return null;
    }
    final dependencies = packageGraph.neighborsOf(packageName).toSet();
    return {
      for (final entry in targetMetadata.entries)
        if (dependencies.contains(entry.key)) entry.key: entry.value,
    };
  }
}

extension on DateTime {
  DateTime roundDownToSeconds() =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch -
          millisecondsSinceEpoch % Duration(seconds: 1).inMilliseconds);
}

extension on BuildConfig {
  String get packageName =>
      packageRoot.pathSegments.lastWhere((e) => e.isNotEmpty);
}
