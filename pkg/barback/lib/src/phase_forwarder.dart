// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase_forwarder;

import 'dart:async';

import 'asset_node.dart';
import 'asset_node_set.dart';

/// A class that takes care of forwarding assets within a phase.
///
/// Each phase contains one or more channels that process its input assets. Each
/// non-grouped transformer for that phase is a channel, each [TransformerGroup]
/// in that phase is another, and the source node is the final channel. For each
/// input asset, each channel individually decides whether to forward that asset
/// based on whether that channel uses it. If a channel does decide to forward
/// an asset, we call that forwarded asset an "intermediate forwarded asset" to
/// distinguish it from the output of a [PhaseForwarder].
///
/// All intermediate assets with a given origin are provided to a single
/// [PhaseForwarder] via [addIntermediateAsset]. This forwarder then determines
/// whether all channels in the phase produced intermediate assets. If so, that
/// means the input asset wasn't consumed by any channel, so the
/// [PhaseForwarder] forwards it again, producing an output which we'll call the
/// "final forwarded asset".
///
/// A final forwarded asset will be available only if all of the intermediate
/// forwarded assets are themselves available. If any of the intermediate assets
/// are dirty, the final asset will also be marked dirty.
class PhaseForwarder {
  /// The number of channels to forward, counting the source node.
  int _numChannels;

  /// The intermediate forwarded assets.
  final _intermediateAssets = new AssetNodeSet();

  /// The final forwarded asset.
  ///
  /// This will be null if the asset is not being forwarded.
  AssetNode get output =>
      _outputController == null ? null : _outputController.node;
  AssetNodeController _outputController;

  /// A stream that emits an event whenever [this] starts producing a final
  /// forwarded asset.
  ///
  /// Whenever this stream emits an event, the value will be identical to
  /// [output].
  Stream<AssetNode> get onAsset => _onAssetController.stream;
  final _onAssetController =
      new StreamController<AssetNode>.broadcast(sync: true);

  /// Creates a phase forwarder forwarding nodes that come from [node] across
  /// [numTransformers] transformers and [numGroups] groups.
  ///
  /// [node] is passed in explicitly so that it can be forwarded if there are no
  /// other channels.
  PhaseForwarder(AssetNode node, int numTransformers, int numGroups)
      : _numChannels = numTransformers + numGroups + 1 {
    addIntermediateAsset(node);
  }

  /// Notify the forwarder that the number of transformer and group channels has
  /// changed.
  void updateTransformers(int numTransformers, int numGroups) {
    // Add one channel for the source node.
    _numChannels = numTransformers + numGroups + 1;
    _adjustOutput();
  }

  /// Adds an intermediate forwarded asset to [this].
  ///
  /// [asset] must have the same origin as all other intermediate forwarded
  /// assets.
  void addIntermediateAsset(AssetNode asset) {
    if (_intermediateAssets.isNotEmpty) {
      assert(asset.origin == _intermediateAssets.first.origin);
    }

    _intermediateAssets.add(asset);
    asset.onStateChange.listen((_) => _adjustOutput());

    _adjustOutput();
  }

  /// Mark this forwarder as removed.
  ///
  /// This will remove [output] if it exists.
  void remove() {
    if (_outputController != null) {
      _outputController.setRemoved();
      _outputController = null;
    }
    _onAssetController.close();
  }

  /// Adjusts [output] to ensure that it accurately reflects the current state
  /// of the intermediate forwarded assets.
  void _adjustOutput() {
    assert(_intermediateAssets.length <= _numChannels);
    assert(!_intermediateAssets.any((asset) => asset.state.isRemoved));

    // If there are any channels that haven't forwarded an intermediate asset,
    // we shouldn't forward a final asset. If we are currently, remove
    // it.
    if (_intermediateAssets.length < _numChannels) {
      if (_outputController == null) return;
      _outputController.setRemoved();
      _outputController = null;
      return;
    }

    // If there isn't a final asset being forwarded yet, we should forward one.
    // It should be dirty iff any of the intermediate assets are dirty.
    if (_outputController == null) {
      var finalAsset = _intermediateAssets.firstWhere(
          (asset) => asset.state.isDirty,
          orElse: () => _intermediateAssets.first);
      _outputController = new AssetNodeController.from(finalAsset);
      _onAssetController.add(output);
      return;
    }

    // If we're already forwarding a final asset, set it dirty iff any of the
    // intermediate assets are dirty.
    if (_intermediateAssets.any((asset) => asset.state.isDirty)) {
      if (!_outputController.node.state.isDirty) _outputController.setDirty();
    } else if (!_outputController.node.state.isAvailable) {
      _outputController.setAvailable(_intermediateAssets.first.asset);
    }
  }
}
