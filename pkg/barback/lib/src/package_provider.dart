// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.package_provider;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'transformer.dart';

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

  /// Returns the list of transformer phases that are applicable to [package].
  ///
  /// The phases will be run in sequence, with the outputs of one pipelined into
  /// the next. All [Transformer]s in a single phase will be run in parallel.
  Iterable<Iterable<Transformer>> getTransformers(String package);

  Future<Asset> getAsset(AssetId id);
}
