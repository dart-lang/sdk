// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase_output;

import 'dart:async';
import 'dart:collection';

import 'asset_forwarder.dart';
import 'asset_node.dart';
import 'errors.dart';
import 'phase.dart';

/// A class that handles a single output of a phase.
///
/// Normally there's only a single [AssetNode] for a phase's output, but it's
/// possible that multiple transformers in the same phase emit assets with the
/// same id, causing collisions. This handles those collisions by forwarding the
/// chronologically first asset.
///
/// When the asset being forwarding changes, the old value of [output] will be
/// marked as removed and a new value will replace it. Users of this class can
/// be notified of this using [onAsset].
class PhaseOutput {
  /// The phase for which this is an output.
  final Phase _phase;

  /// A string describing the location of [this] in the transformer graph.
  final String _location;

  /// The asset node for this output.
  AssetNode get output => _outputForwarder.node;
  AssetForwarder _outputForwarder;

  /// A stream that emits an [AssetNode] each time this output starts forwarding
  /// a new asset.
  Stream<AssetNode> get onAsset => _onAssetController.stream;
  final _onAssetController =
      new StreamController<AssetNode>.broadcast(sync: true);

  /// The assets for this output.
  ///
  /// If there's no collision, this will only have one element. Otherwise, it
  /// will be ordered by which asset was added first.
  final _assets = new Queue<AssetNode>();

  /// The [AssetCollisionException] for this output, or null if there is no
  /// collision currently.
  AssetCollisionException get collisionException {
    if (_assets.length == 1) return null;
    return new AssetCollisionException(
        _assets.where((asset) => asset.transform != null)
            .map((asset) => asset.transform.info),
        output.id);
  }

  PhaseOutput(this._phase, AssetNode output, this._location)
      : _outputForwarder = new AssetForwarder(output) {
    assert(!output.state.isRemoved);
    add(output);
  }

  /// Adds an asset node as an output with this id.
  void add(AssetNode node) {
    assert(node.id == output.id);
    assert(!output.state.isRemoved);
    _assets.add(node);
    _watchAsset(node);
  }

  /// Removes all existing listeners on [output] without actually closing
  /// [this].
  ///
  /// This marks [output] as removed, but immediately replaces it with a new
  /// [AssetNode] in the same state as the old output. This is used when adding
  /// a new [Phase] to cause consumers of the prior phase's outputs to be to
  /// start consuming the new phase's outputs instead.
  void removeListeners() {
    _outputForwarder.close();
    _outputForwarder = new AssetForwarder(_assets.first);
    _onAssetController.add(output);
  }

  /// Watches [node] to adjust [_assets] and [output] when it's removed.
  void _watchAsset(AssetNode node) {
    node.whenRemoved(() {
      if (_assets.length == 1) {
        assert(_assets.single == node);
        _outputForwarder.close();
        _onAssetController.close();
        return;
      }

      // If there was more than one asset, we're resolving a collision --
      // possibly partially.
      var wasFirst = _assets.first == node;
      _assets.remove(node);

      // If this was the first asset, we replace it with the next asset
      // (chronologically).
      if (wasFirst) removeListeners();

      // If there's still a collision, report it. This lets the user know if
      // they've successfully resolved the collision or not.
      if (_assets.length > 1) {
        // TODO(nweiz): report this through the output asset.
        _phase.cascade.reportError(collisionException);
      }
    });
  }

  String toString() => "phase output in $_location for $output";
}
