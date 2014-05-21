// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset.asset_node_set;

import 'package:collection/collection.dart';

import 'asset_id.dart';
import 'asset_node.dart';

/// A set of [AssetNode]s that automatically ensures that nodes are removed from
/// the set as soon as they're marked as [AssetState.REMOVED].
///
/// Asset nodes may be accessed by their ids. This means that only one node with
/// a given id may be stored in the set at a time.
class AssetNodeSet extends DelegatingSet<AssetNode> {
  // TODO(nweiz): Use DelegatingMapSet when issue 18705 is fixed.
  /// A map from asset ids to assets in the set.
  final _assetsById = new Map<AssetId, AssetNode>();

  AssetNodeSet()
      : super(new Set());

  /// Returns the asset node in the set with [id], or `null` if none exists.
  AssetNode operator [](AssetId id) => _assetsById[id];

  bool add(AssetNode node) {
    if (node.state.isRemoved) return false;
    node.whenRemoved(() {
      super.remove(node);
      _assetsById.remove(node.id);
    });
    _assetsById[node.id] = node;
    return super.add(node);
  }

  /// Returns whether an asset node with the given [id] is in the set.
  bool containsId(AssetId id) => _assetsById.containsKey(id);

  void addAll(Iterable<AssetNode> nodes) => nodes.forEach(add);
}