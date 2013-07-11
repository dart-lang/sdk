// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase;

import 'dart:async';

import 'asset.dart';
import 'asset_graph.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'transform_node.dart';
import 'transformer.dart';

/// One phase in the ordered series of transformations in an [AssetGraph].
///
/// Each phase can access outputs from previous phases and can in turn pass
/// outputs to later phases. Phases are processed strictly serially. All
/// transforms in a phase will be complete before moving on to the next phase.
/// Within a single phase, all transforms will be run in parallel.
///
/// Building can be interrupted between phases. For example, a source is added
/// which starts the background process. Sometime during, say, phase 2 (which
/// is running asynchronously) that source is modified. When the process queue
/// goes to advance to phase 3, it will see that modification and start the
/// waterfall from the beginning again.
class Phase {
  /// The graph that owns this phase.
  final AssetGraph graph;

  /// This phase's position relative to the other phases. Zero-based.
  final int _index;

  /// The transformers that can access [inputs].
  ///
  /// Their outputs will be available to the next phase.
  final List<Transformer> _transformers;

  /// The inputs that are available for transforms in this phase to consume.
  ///
  /// For the first phase, these will be the source assets. For all other
  /// phases, they will be the outputs from the previous phase.
  final inputs = new Map<AssetId, AssetNode>();

  /// The transforms currently applicable to assets in [inputs].
  ///
  /// These are the transforms that have been "wired up": they represent a
  /// repeatable transformation of a single concrete set of inputs. "dart2js"
  /// is a transformer. "dart2js on web/main.dart" is a transform.
  final _transforms = new Set<TransformNode>();

  /// The nodes that are new in this phase since the last time [process] was
  /// called.
  ///
  /// When we process, we'll check these to see if we can hang new transforms
  /// off them.
  final _newInputs = new Set<AssetNode>();

  /// The phase after this one.
  ///
  /// Outputs from this phase will be passed to it.
  final Phase _next;

  Phase(this.graph, this._index, this._transformers, this._next);

  /// Updates the phase's inputs with [updated] and removes [removed].
  ///
  /// This marks any affected [transforms] as dirty or discards them if their
  /// inputs are removed.
  void updateInputs(AssetSet updated, Set<AssetId> removed) {
    // Remove any nodes that are no longer being output. Handle removals first
    // in case there are assets that were removed by one transform but updated
    // by another. In that case, the update should win.
    for (var id in removed) {
      var node = inputs.remove(id);

      // Every transform that was using it is dirty now.
      if (node != null) {
        node.consumers.forEach((consumer) => consumer.dirty());
      }
    }

    // Update and new or modified assets.
    for (var asset in updated) {
      var node = inputs[asset.id];
      if (node == null) {
        // It's a new node. Add it and remember it so we can see if any new
        // transforms will consume it.
        node = new AssetNode(asset);
        inputs[asset.id] = node;
        _newInputs.add(node);
      } else {
        node.updateAsset(asset);
      }
    }
  }

  /// Processes this phase.
  ///
  /// For all new inputs, it tries to see if there are transformers that can
  /// consume them. Then all applicable transforms are applied.
  ///
  /// Returns a future that completes when processing is done. If there is
  /// nothing to process, returns `null`.
  Future process() {
    var future = _processNewInputs();
    if (future == null) {
      return _processTransforms();
    }

    return future.then((_) => _processTransforms());
  }

  /// Creates new transforms for any new inputs that are applicable.
  Future _processNewInputs() {
    if (_newInputs.isEmpty) return null;

    var futures = [];
    for (var node in _newInputs) {
      for (var transformer in _transformers) {
        // TODO(rnystrom): Catch all errors from isPrimary() and redirect
        // to results.
        futures.add(transformer.isPrimary(node.asset).then((isPrimary) {
          if (!isPrimary) return;
          var transform = new TransformNode(this, transformer, node);
          node.consumers.add(transform);
          _transforms.add(transform);
        }));
      }
    }

    _newInputs.clear();

    return Future.wait(futures);
  }

  /// Applies all currently wired up and dirty transforms.
  ///
  /// Passes their outputs to the next phase.
  Future _processTransforms() {
    var dirtyTransforms = _transforms.where((transform) => transform.isDirty);
    if (dirtyTransforms.isEmpty) return null;

    return Future.wait(dirtyTransforms.map((transform) => transform.apply()))
        .then((transformOutputs) {
      // Collect all of the outputs. Since the transforms are run in parallel,
      // we have to be careful here to ensure that the result is deterministic
      // and not influenced by the order that transforms complete.
      var updated = new AssetSet();
      var removed = new Set<AssetId>();
      var collisions = new Set<AssetId>();

      // Handle the generated outputs of all transforms first.
      for (var outputs in transformOutputs) {
        // Collect the outputs of all transformers together.
        for (var asset in outputs.updated) {
          if (updated.containsId(asset.id)) {
            // Report a collision.
            collisions.add(asset.id);
          } else {
            // TODO(rnystrom): In the case of a collision, the asset that
            // "wins" is chosen non-deterministically. Do something better.
            updated.add(asset);
          }
        }

        // Track any assets no longer output by this transform. We don't
        // handle the case where *another* transform generates the asset
        // no longer generated by this one. updateInputs() handles that.
        removed.addAll(outputs.removed);
      }

      // Report any collisions in deterministic order.
      collisions = collisions.toList();
      collisions.sort((a, b) => a.toString().compareTo(b.toString()));
      for (var collision in collisions) {
        graph.reportError(new AssetCollisionException(collision));
        // TODO(rnystrom): Define what happens after a collision occurs.
      }

      // Pass the outputs to the next phase.
      _next.updateInputs(updated, removed);
    });
  }
}
