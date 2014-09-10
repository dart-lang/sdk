// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.package_provider;

import 'dart:async';

import 'asset/asset.dart';
import 'asset/asset_id.dart';

/// API for locating and accessing packages on disk.
///
/// Implemented by pub and provided to barback so that it isn't coupled
/// directly to pub.
abstract class PackageProvider {
  /// The names of all packages that can be provided by this provider.
  ///
  /// This is equal to the transitive closure of the entrypoint package
  /// dependencies.
  Iterable<String> get packages;

  /// Loads an asset from disk.
  ///
  /// This should be re-entrant; it may be called multiple times with the same
  /// id before the previously returned future has completed.
  ///
  /// If no asset with [id] exists, the provider should throw an
  /// [AssetNotFoundException].
  Future<Asset> getAsset(AssetId id);
}

/// A PackageProvider for which some packages are known to be static—that is,
/// the package has no transformers and its assets won't ever change.
///
/// For static packages, rather than telling barback up-front which assets that
/// package contains via [Barback.updateSources], barback will lazily query the
/// provider for an asset when it's needed. This is much more efficient.
abstract class StaticPackageProvider implements PackageProvider {
  /// The names of all static packages provided by this provider.
  ///
  /// This must be disjoint from [packages].
  Iterable<String> get staticPackages;

  /// Returns all ids of assets in [package].
  ///
  /// This is used for [Barback.getAllAssets].
  Stream<AssetId> getAllAssetIds(String package);
}
