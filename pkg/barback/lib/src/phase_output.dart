// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase_output;

import 'dart:async';
import 'dart:collection';

import 'asset_cascade.dart';
import 'asset_node.dart';
import 'errors.dart';
import 'phase.dart';
import 'utils.dart';

/// A class that handles a single output of a phase.
///
/// Normally there's only a single [AssetNode] for a phase's output, but it's
/// possible that multiple transformers in the same phase emit assets with the
/// same id, causing collisions. This handles those collisions by forwarding the
/// chronologically first asset.
class PhaseOutput {
  /// The phase for which this is an output.
  final Phase _phase;

  /// The asset node for this output.
  AssetNode get output => _outputController.node;
  AssetNodeController _outputController;

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

  PhaseOutput(this._phase, AssetNode output)
      : _outputController = new AssetNodeController.from(output) {
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
    _outputController.setRemoved();
    _outputController = new AssetNodeController.from(_assets.first);
  }

  /// Watches [node] for state changes and adjusts [_assets] and [output]
  /// appropriately when they occur.
  void _watchAsset(AssetNode node) {
    node.onStateChange.listen((state) {
      if (state.isRemoved) {
        _removeAsset(node);
        return;
      }
      if (_assets.first != node) return;

      if (state.isAvailable) {
        _outputController.setAvailable(node.asset);
      } else {
        assert(state.isDirty);
        _outputController.setDirty();
      }
    });
  }

  /// Removes [node] as an output.
  void _removeAsset(AssetNode node) {
    if (_assets.length == 1) {
      assert(_assets.single == node);
      _outputController.setRemoved();
      return;
    }

    // If there was more than one asset, we're resolving a collision --
    // possibly partially.
    var wasFirst = _assets.first == node;
    _assets.remove(node);

    // If this was the first asset, we replace it with the next asset
    // (chronologically).
    if (wasFirst) {
      var newOutput = _assets.first;
      _outputController.setOrigin(newOutput.origin);
      if (newOutput.state.isAvailable) {
        if (output.state.isAvailable) _outputController.setDirty();
        _outputController.setAvailable(newOutput.asset);
      } else {
        assert(newOutput.isDirty);
        if (!output.state.isDirty) _outputController.setDirty();
      }
    }

    // If there's still a collision, report it. This lets the user know
    // if they've successfully resolved the collision or not.
    if (_assets.length > 1) {
      // Pump the event queue to ensure that the removal of the input triggers
      // a new build to which we can attach the error.
      // TODO(nweiz): report this through the output asset.
      newFuture(() => _phase.cascade.reportError(collisionException));
    }
  }
}
