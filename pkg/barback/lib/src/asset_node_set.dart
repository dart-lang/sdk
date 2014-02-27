// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_node_set;

import 'package:collection/collection.dart';

import 'asset_node.dart';

/// A set of [AssetNode]s that automatically ensures that nodes are removed from
/// the set as soon as they're marked as [AssetState.REMOVED].
class AssetNodeSet extends DelegatingSet<AssetNode> {
  AssetNodeSet()
      : super(new Set());

  bool add(AssetNode node) {
    if (node.state.isRemoved) return false;
    node.whenRemoved(() => super.remove(node));
    return super.add(node);
  }

  void addAll(Iterable<AssetNode> nodes) => nodes.forEach(add);
}