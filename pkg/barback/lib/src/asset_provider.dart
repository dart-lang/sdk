// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_provider;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';

/// API for locating and accessing packages on disk.
///
/// Implemented by pub and provided to barback so that it isn't coupled
/// directly to pub.
abstract class AssetProvider {
  /// The names of all packages that can be provided by this provider.
  ///
  /// This is equal to the transitive closure of the entrypoint package
  /// dependencies.
  Iterable<String> get packages;

  // TODO(rnystrom): Make this async.
  /// The paths of all available asset files in [package], relative to the
  /// package's root directory.
  ///
  /// You can pass [within], which should be the relative path to a directory
  /// within the package, to only return the files within that subdirectory.
  List<AssetId> listAssets(String package, {String within});

  Future<Asset> getAsset(AssetId id);
}
