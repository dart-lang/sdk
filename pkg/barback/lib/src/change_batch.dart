// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.change_batch;

import 'asset_id.dart';

/// Represents a batch of source asset changes: additions, removals and
/// modifications.
class ChangeBatch {
  /// The assets that have been added or modified in this batch.
  final updated = new Set<AssetId>();

  /// The assets that have been removed in this batch.
  final removed = new Set<AssetId>();

  /// Adds the updated [assets] to this batch.
  void update(Iterable<AssetId> assets) {
    updated.addAll(assets);

    // If they were previously removed, they are back now.
    removed.removeAll(assets);
  }

  /// Removes [assets] from this batch.
  void remove(Iterable<AssetId> assets) {
    removed.addAll(assets);

    // If they were previously updated, they are gone now.
    updated.removeAll(assets);
  }
}
