// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform_node;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'phase.dart';
import 'transform.dart';
import 'transformer.dart';

/// Describes a transform on a set of assets and its relationship to the build
/// dependency graph.
///
/// Keeps track of whether it's dirty and needs to be run and which assets it
/// depends on.
class TransformNode {
  /// The [Phase] that this transform runs in.
  final Phase phase;

  /// The [Transformer] to apply to this node's inputs.
  final Transformer transformer;

  /// The node for the primary asset this transform depends on.
  final AssetNode primary;

  /// The subscription to [primary]'s [AssetNode.onStateChange] stream.
  StreamSubscription _primarySubscription;

  /// True if an input has been modified since the last time this transform
  /// began running.
  bool get isDirty => _isDirty;
  var _isDirty = true;

  /// The inputs read by this transform the last time it was run.
  ///
  /// Used to tell if an input was added or removed in a later run.
  var _inputs = new Set<AssetNode>();

  /// The subscriptions to each input's [AssetNode.onStateChange] stream.
  var _inputSubscriptions = new Map<AssetId, StreamSubscription>();

  /// The controllers for the asset nodes emitted by this node.
  var _outputControllers = new Map<AssetId, AssetNodeController>();

  TransformNode(this.phase, this.transformer, this.primary) {
    _primarySubscription = primary.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        _dirty();
      }
    });
  }

  /// Marks this transform as removed.
  ///
  /// This causes all of the transform's outputs to be marked as removed as
  /// well. Normally this will be automatically done internally based on events
  /// from the primary input, but it's possible for a transform to no longer be
  /// valid even if its primary input still exists.
  void remove() {
    _isDirty = true;
    _primarySubscription.cancel();
    for (var subscription in _inputSubscriptions.values) {
      subscription.cancel();
    }
    for (var controller in _outputControllers.values) {
      controller.setRemoved();
    }
  }

  /// Marks this transform as dirty.
  ///
  /// This causes all of the transform's outputs to be marked as dirty as well.
  void _dirty() {
    _isDirty = true;
    for (var controller in _outputControllers.values) {
      controller.setDirty();
    }
  }

  /// Applies this transform.
  ///
  /// Returns a set of asset nodes representing the outputs from this transform
  /// that weren't emitted last time it was run.
  Future<Set<AssetNode>> apply() {
    var newInputs = new Set<AssetNode>();
    var newOutputs = new AssetSet();
    var transform = createTransform(this, newInputs, newOutputs);
    _isDirty = false;
    return transformer.apply(transform).catchError((error) {
      // If the transform became dirty while processing, ignore any errors from
      // it.
      if (_isDirty) return;

      // Catch all transformer errors and pipe them to the results stream.
      // This is so a broken transformer doesn't take down the whole graph.
      phase.cascade.reportError(error);

      // Don't allow partial results from a failed transform.
      newOutputs.clear();
    }).then((_) {
      if (_isDirty) return [];

      _adjustInputs(newInputs);
      return _adjustOutputs(newOutputs);
    });
  }

  /// Adjusts the inputs of the transform to reflect the inputs consumed on its
  /// most recent run.
  void _adjustInputs(Set<AssetNode> newInputs) {
    // Stop watching any inputs that were removed.
    for (var oldInput in _inputs.difference(newInputs)) {
      _inputSubscriptions.remove(oldInput.id).cancel();
    }

    // Watch any new inputs so this transform will be re-processed when an
    // input is modified.
    for (var newInput in newInputs.difference(_inputs)) {
      if (newInput.id == primary.id) continue;
      // TODO(nweiz): support the case where a new secondary input changes
      // after it's been loaded by the transform but before the transform has
      // finished running.
      _inputSubscriptions[newInput.id] = newInput.onStateChange
          .listen((_) => _dirty());
    }

    _inputs = newInputs;
  }

  /// Adjusts the outputs of the transform to reflect the outputs emitted on its
  /// most recent run.
  Set<AssetNode> _adjustOutputs(AssetSet newOutputs) {
    // Any ids that are for a different package are invalid.
    var invalidIds = newOutputs
        .map((asset) => asset.id)
        .where((id) => id.package != phase.cascade.package)
        .toSet();
    for (var id in invalidIds) {
      newOutputs.removeId(id);
      // TODO(nweiz): report this as a warning rather than a failing error.
      phase.cascade.reportError(
          new InvalidOutputException(phase.cascade.package, id));
    }

    // Remove outputs that used to exist but don't anymore.
    for (var id in _outputControllers.keys.toList()) {
      if (newOutputs.containsId(id)) continue;
      _outputControllers.remove(id).setRemoved();
    }

    var brandNewOutputs = new Set<AssetNode>();
    // Store any new outputs or new contents for existing outputs.
    for (var asset in newOutputs) {
      var controller = _outputControllers[asset.id];
      if (controller != null) {
        controller.setAvailable(asset);
      } else {
        var controller = new AssetNodeController.available(asset);
        _outputControllers[asset.id] = controller;
        brandNewOutputs.add(controller.node);
      }
    }

    return brandNewOutputs;
  }
}
