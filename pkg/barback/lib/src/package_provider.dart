// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.package_provider;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';

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
  Future<Asset> getAsset(AssetId id);
}
