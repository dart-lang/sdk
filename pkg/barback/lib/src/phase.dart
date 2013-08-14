// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase;

import 'dart:async';
import 'dart:collection';

import 'asset.dart';
import 'asset_cascade.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'errors.dart';
import 'stream_pool.dart';
import 'transform_node.dart';
import 'transformer.dart';
import 'utils.dart';

/// One phase in the ordered series of transformations in an [AssetCascade].
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
  /// The cascade that owns this phase.
  final AssetCascade cascade;

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
  final _inputs = new Map<AssetId, AssetNode>();

  /// The transforms currently applicable to assets in [inputs], indexed by
  /// the ids of their primary inputs.
  ///
  /// These are the transforms that have been "wired up": they represent a
  /// repeatable transformation of a single concrete set of inputs. "dart2js"
  /// is a transformer. "dart2js on web/main.dart" is a transform.
  final _transforms = new Map<AssetId, Set<TransformNode>>();

  /// Futures that will complete once the transformers that can consume a given
  /// asset are determined.
  ///
  /// Whenever an asset is added or modified, we need to asynchronously
  /// determine which transformers can use it as their primary input. We can't
  /// start processing until we know which transformers to run, and this allows
  /// us to wait until we do.
  var _adjustTransformersFutures = new Map<AssetId, Future>();

  /// New asset nodes that were added while [_adjustTransformers] was still
  /// being run on an old version of that asset.
  var _pendingNewInputs = new Map<AssetId, AssetNode>();

  /// A map of output ids to the asset node outputs for those ids and the
  /// transforms that produced those asset nodes.
  ///
  /// Usually there's only one node for a given output id. However, it's
  /// possible for multiple transformers in this phase to output an asset with
  /// the same id. In that case, the chronologically first output emitted is
  /// passed forward. We keep track of the other nodes so that if that output is
  /// removed, we know which asset to replace it with.
  final _outputs = new Map<AssetId, Queue<AssetNode>>();

  /// A stream that emits an event whenever this phase becomes dirty and needs
  /// to be run.
  ///
  /// This may emit events when the phase was already dirty or while processing
  /// transforms. Events are emitted synchronously to ensure that the dirty
  /// state is thoroughly propagated as soon as any assets are changed.
  Stream get onDirty => _onDirtyPool.stream;
  final _onDirtyPool = new StreamPool.broadcast();

  /// A controller whose stream feeds into [_onDirtyPool].
  ///
  /// This is used whenever an input is added, changed, or removed. It's
  /// sometimes redundant with the events collected from [_transforms], but this
  /// stream is necessary for new and removed inputs, and the transform stream
  /// is necessary for modified secondary inputs.
  final _onDirtyController = new StreamController.broadcast(sync: true);

  /// The phase after this one.
  ///
  /// Outputs from this phase will be passed to it.
  final Phase _next;

  Phase(this.cascade, this._index, this._transformers, this._next) {
    _onDirtyPool.add(_onDirtyController.stream);
  }

  /// Adds a new asset as an input for this phase.
  ///
  /// [node] doesn't have to be [AssetState.AVAILABLE]. Once it is, the phase
  /// will automatically begin determining which transforms can consume it as a
  /// primary input. The transforms themselves won't be applied until [process]
  /// is called, however.
  ///
  /// This should only be used for brand-new assets or assets that have been
  /// removed and re-created. The phase will automatically handle updated assets
  /// using the [AssetNode.onStateChange] stream.
  void addInput(AssetNode node) {
    // We remove [node.id] from [inputs] as soon as the node is removed rather
    // than at the same time [node.id] is removed from [_transforms] so we don't
    // have to wait on [_adjustTransformers]. It's important that [inputs] is
    // always up-to-date so that the [AssetCascade] can look there for available
    // assets.
    _inputs[node.id] = node;
    node.whenRemoved.then((_) => _inputs.remove(node.id));

    if (!_adjustTransformersFutures.containsKey(node.id)) {
      _transforms[node.id] = new Set<TransformNode>();
      _adjustTransformers(node);
      return;
    }

    // If an input is added while the same input is still being processed,
    // that means that the asset was removed and recreated while
    // [_adjustTransformers] was being run on the old value. We have to wait
    // until that finishes, then run it again on whatever the newest version
    // of that asset is.

    // We may already be waiting for the existing [_adjustTransformers] call to
    // finish. If so, all we need to do is change the node that will be loaded
    // after it completes.
    var containedKey = _pendingNewInputs.containsKey(node.id);
    _pendingNewInputs[node.id] = node;
    if (containedKey) return;

    // If we aren't already waiting, start doing so.
    _adjustTransformersFutures[node.id].then((_) {
      assert(!_adjustTransformersFutures.containsKey(node.id));
      assert(_pendingNewInputs.containsKey(node.id));
      _transforms[node.id] = new Set<TransformNode>();
      _adjustTransformers(_pendingNewInputs.remove(node.id));
    }, onError: (_) {
      // If there was a programmatic error while processing the old input,
      // we don't want to just ignore it; it may have left the system in an
      // inconsistent state. We also don't want to top-level it, so we
      // ignore it here but don't start processing the new input. That way
      // when [process] is called, the error will be piped through its
      // return value.
    }).catchError((e) {
      // If our code above has a programmatic error, ensure it will be piped
      // through [process] by putting it into [_adjustTransformersFutures].
      _adjustTransformersFutures[node.id] = new Future.error(e);
    });
  }

  /// Returns the input for this phase with the given [id], but only if that
  /// input is known not to be consumed as a transformer's primary input.
  ///
  /// If the input is unavailable, or if the phase hasn't determined whether or
  /// not any transformers will consume it as a primary input, null will be
  /// returned instead. This means that the return value is guaranteed to always
  /// be [AssetState.AVAILABLE].
  AssetNode getUnconsumedInput(AssetId id) {
    if (!_inputs.containsKey(id)) return null;

    // If the asset has transforms, it's not unconsumed.
    if (!_transforms[id].isEmpty) return null;

    // If we're working on figuring out if the asset has transforms, we can't
    // prove that it's unconsumed.
    if (_adjustTransformersFutures.containsKey(id)) return null;

    // The asset should be available. If it were removed, it wouldn't be in
    // _inputs, and if it were dirty, it'd be in _adjustTransformersFutures.
    assert(_inputs[id].state.isAvailable);
    return _inputs[id];
  }

  /// Gets the asset node for an input [id].
  ///
  /// If an input with that ID cannot be found, returns null.
  Future<AssetNode> getInput(AssetId id) {
    return newFuture(() {
      // TODO(rnystrom): Need to handle passthrough where an asset from a
      // previous phase can be found.
      if (id.package == cascade.package) return _inputs[id];
      return cascade.graph.getAssetNode(id);
    });
  }

  /// Asynchronously determines which transformers can consume [node] as a
  /// primary input and creates transforms for them.
  ///
  /// This ensures that if [node] is modified or removed during or after the
  /// time it takes to adjust its transformers, they're appropriately
  /// re-adjusted. Its progress can be tracked in [_adjustTransformersFutures].
  void _adjustTransformers(AssetNode node) {
    // Mark the phase as dirty. This may not actually end up creating any new
    // transforms, but we want adding or removing a source asset to consistently
    // kick off a build, even if that build does nothing.
    _onDirtyController.add(null);

    // Once the input is available, hook up transformers for it. If it changes
    // while that's happening, try again.
    _adjustTransformersFutures[node.id] = node.tryUntilStable((asset) {
      var oldTransformers = _transforms[node.id]
          .map((transform) => transform.transformer).toSet();

      return _removeStaleTransforms(asset)
          .then((_) => _addFreshTransforms(node, oldTransformers));
    }).then((_) {
      // Now all the transforms are set up correctly and the asset is available
      // for the time being. Set up handlers for when the asset changes in the
      // future.
      node.onStateChange.first.then((state) {
        if (state.isRemoved) {
          _onDirtyController.add(null);
          _transforms.remove(node.id);
        } else {
          _adjustTransformers(node);
        }
      }).catchError((e) {
        _adjustTransformersFutures[node.id] = new Future.error(e);
      });
    }).catchError((error) {
      if (error is! AssetNotFoundException || error.id != node.id) throw error;

      // If the asset is removed, [tryUntilStable] will throw an
      // [AssetNotFoundException]. In that case, just remove all transforms for
      // the node.
      _transforms.remove(node.id);
    }).whenComplete(() {
      _adjustTransformersFutures.remove(node.id);
    });

    // Don't top-level errors coming from the input processing. Any errors will
    // eventually be piped through [process]'s returned Future.
    _adjustTransformersFutures[node.id].catchError((_) {});
  }

  // Remove any old transforms that used to have [asset] as a primary asset but
  // no longer apply to its new contents.
  Future _removeStaleTransforms(Asset asset) {
    return Future.wait(_transforms[asset.id].map((transform) {
      // TODO(rnystrom): Catch all errors from isPrimary() and redirect to
      // results.
      return transform.transformer.isPrimary(asset).then((isPrimary) {
        if (isPrimary) return;
        _transforms[asset.id].remove(transform);
        _onDirtyPool.remove(transform.onDirty);
        transform.remove();
      });
    }));
  }

  // Add new transforms for transformers that consider [node]'s asset to be a
  // primary input.
  //
  // [oldTransformers] is the set of transformers that had [node] as a primary
  // input prior to this. They don't need to be checked, since they were removed
  // or preserved in [_removeStaleTransforms].
  Future _addFreshTransforms(AssetNode node, Set<Transformer> oldTransformers) {
    return Future.wait(_transformers.map((transformer) {
      if (oldTransformers.contains(transformer)) return new Future.value();

      // If the asset is unavailable, the results of this [_adjustTransformers]
      // run will be discarded, so we can just short-circuit.
      if (node.asset == null) return new Future.value();

      // We can safely access [node.asset] here even though it might have
      // changed since (as above) if it has, [_adjustTransformers] will just be
      // re-run.
      // TODO(rnystrom): Catch all errors from isPrimary() and redirect to
      // results.
      return transformer.isPrimary(node.asset).then((isPrimary) {
        if (!isPrimary) return;
        var transform = new TransformNode(this, transformer, node);
        _transforms[node.id].add(transform);
        _onDirtyPool.add(transform.onDirty);
      });
    }));
  }

  /// Processes this phase.
  ///
  /// Returns a future that completes when processing is done. If there is
  /// nothing to process, returns `null`.
  Future process() {
    if (_adjustTransformersFutures.isEmpty) return _processTransforms();
    return _waitForInputs().then((_) => _processTransforms());
  }

  Future _waitForInputs() {
    if (_adjustTransformersFutures.isEmpty) return new Future.value();
    return Future.wait(_adjustTransformersFutures.values)
        .then((_) => _waitForInputs());
  }

  /// Applies all currently wired up and dirty transforms.
  Future _processTransforms() {
    // Convert this to a list so we can safely modify _transforms while
    // iterating over it.
    var dirtyTransforms =
        flatten(_transforms.values.map((transforms) => transforms.toList()))
        .where((transform) => transform.isDirty).toList();
    if (dirtyTransforms.isEmpty) return null;

    var collisions = new Set<AssetId>();
    return Future.wait(dirtyTransforms.map((transform) {
      return transform.apply().then((outputs) {
        for (var output in outputs) {
          if (_outputs.containsKey(output.id)) {
            _outputs[output.id].add(output);
            collisions.add(output.id);
          } else {
            _outputs[output.id] = new Queue<AssetNode>.from([output]);
            _next.addInput(output);
          }

          _handleOutputRemoval(output);
        }
      });
    })).then((_) {
      // Report collisions in a deterministic order.
      collisions = collisions.toList();
      collisions.sort((a, b) => a.compareTo(b));
      for (var collision in collisions) {
        // Ensure that there's still a collision. It's possible it was resolved
        // while another transform was running.
        if (_outputs[collision].length <= 1) continue;
        cascade.reportError(new AssetCollisionException(
            _outputs[collision].where((asset) => asset.transform != null)
                .map((asset) => asset.transform.info),
            collision));
      }
    });
  }

  /// Properly resolve collisions when [output] is removed.
  void _handleOutputRemoval(AssetNode output) {
    output.whenRemoved.then((_) {
      var assets = _outputs[output.id];
      if (assets.length == 1) {
        assert(assets.single == output);
        _outputs.remove(output.id);
        return;
      }

      // If there was more than one asset, we're resolving a collision --
      // possibly partially.
      var wasFirst = assets.first == output;
      assets.remove(output);

      // If this was the first asset, we need to pass the next asset
      // (chronologically) to the next phase. Pump the event queue first to give
      // [_next] a chance to handle the removal of its input before getting a
      // new input.
      if (wasFirst) {
        newFuture(() => _next.addInput(assets.first));
      }

      // If there's still a collision, report it. This lets the user know
      // if they've successfully resolved the collision or not.
      if (assets.length > 1) {
        // Pump the event queue to ensure that the removal of the input triggers
        // a new build to which we can attach the error.
        newFuture(() => cascade.reportError(new AssetCollisionException(
            assets.where((asset) => asset.transform != null)
                .map((asset) => asset.transform.info),
            output.id)));
      }
    });
  }
}
