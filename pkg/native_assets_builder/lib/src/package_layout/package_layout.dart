// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:package_config/package_config.dart';

/// Directory layout for dealing with native assets.
///
/// Build scripts for native assets will be run from the context of another
/// root package.
///
/// The directory layout follows pub's convention for caching:
/// https://dart.dev/tools/pub/package-layout#project-specific-caching-for-tools
class PackageLayout {
  /// The root folder of the current dart invocation root package.
  ///
  /// `$rootPackageRoot`.
  final Uri rootPackageRoot;

  /// Package config containing the information of where to foot the root [Uri]s
  /// of other packages.
  ///
  /// Can be `null` to enable quick construction of a
  /// [PackageLayout].
  final PackageConfig packageConfig;

  final Uri packageConfigUri;

  PackageLayout._(
      this.rootPackageRoot, this.packageConfig, this.packageConfigUri);

  static Future<PackageLayout> fromRootPackageRoot(Uri rootPackageRoot) async {
    rootPackageRoot = rootPackageRoot.normalizePath();
    final packageConfigUri =
        rootPackageRoot.resolve('.dart_tool/package_config.json');
    assert(await File.fromUri(packageConfigUri).exists());
    final packageConfig = await loadPackageConfigUri(packageConfigUri);
    return PackageLayout._(rootPackageRoot, packageConfig, packageConfigUri);
  }

  /// The .dart_tool directory is used to store built artifacts and caches.
  ///
  /// `$rootPackageRoot/.dart_tool/`.
  ///
  /// Each package should only modify the subfolder of `.dart_tool/` with its
  /// own name.
  /// https://dart.dev/tools/pub/package-layout#project-specific-caching-for-tools
  late final Uri dartTool = rootPackageRoot.resolve('.dart_tool/');

  /// The directory where `package:native_assets_builder` stores all persistent
  /// information.
  ///
  /// This folder is owned by `package:native_assets_builder`, no other package
  /// should read or modify it.
  /// https://dart.dev/tools/pub/package-layout#project-specific-caching-for-tools
  ///
  /// `$rootPackageRoot/.dart_tool/native_assets_builder/`.
  late final Uri dartToolNativeAssetsBuilder =
      dartTool.resolve('native_assets_builder/');

  /// The root of `package:$packageName`.
  ///
  /// `$packageName/`.
  ///
  /// This folder is owned by pub, and should _never_ be written to.
  Uri packageRoot(String packageName) {
    final package = packageConfig[packageName];
    if (package == null) {
      throw StateError('Package $packageName not found in packageConfig.');
    }
    return package.root;
  }

  /// All packages in [packageConfig] with native assets.
  ///
  /// Whether a package has native assets is defined by whether it contains
  /// a `build.dart`.
  ///
  /// `package:native` itself is excluded.
  late final Future<List<Package>> packagesWithNativeAssets = () async {
    final result = <Package>[];
    for (final package in packageConfig.packages) {
      final packageRoot = package.root;
      if (packageRoot.scheme == 'file') {
        if (await File.fromUri(packageRoot.resolve('build.dart')).exists()) {
          result.add(package);
        }
      }
    }
    return result;
  }();
}
