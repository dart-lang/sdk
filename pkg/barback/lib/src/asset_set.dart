// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_set;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'asset.dart';
import 'asset_id.dart';

/// A set of [Asset]s with distinct IDs.
///
/// This uses the [AssetId] of each asset to determine uniqueness, so no two
/// assets with the same ID can be in the set.
class AssetSet extends IterableBase<Asset> {
  final _assets = new Map<AssetId, Asset>();

  Iterator<Asset> get iterator => _assets.values.iterator;

  int get length => _assets.length;

  /// Gets the [Asset] in the set with [id], or returns `null` if no asset with
  /// that ID is present.
  Asset operator[](AssetId id) => _assets[id];

  /// Adds [asset] to the set.
  ///
  /// If there is already an asset with that ID in the set, it is replaced by
  /// the new one. Returns [asset].
  Asset add(Asset asset) {
    _assets[asset.id] = asset;
    return asset;
  }

  /// Adds [assets] to the set.
  void addAll(Iterable<Asset> assets) {
    assets.forEach(add);
  }

  /// Returns `true` if the set contains [asset].
  bool contains(Asset asset) {
    var other = _assets[asset.id];
    return other == asset;
  }

  /// Returns `true` if the set contains an [Asset] with [id].
  bool containsId(AssetId id) {
    return _assets.containsKey(id);
  }

  /// Removes all assets from the set.
  void clear() {
    _assets.clear();
  }
}
