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

  /// The transformers that can access [inputs].
  ///
  /// Their outputs will be available to the next phase.
  final Set<Transformer> _transformers;

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

  /// Controllers for assets that aren't consumed by transforms in this phase.
  ///
  /// These assets are passed to the next phase unmodified. They need
  /// intervening controllers to ensure that the outputs can be marked dirty
  /// when determining whether transforms apply, and removed if they do.
  final _passThroughControllers = new Map<AssetId, AssetNodeController>();

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
  /// possible for multiple transformers to output an asset with the same id. In
  /// that case, the chronologically first output emitted is passed forward. We
  /// keep track of the other nodes so that if that output is removed, we know
  /// which asset to replace it with.
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
  Phase get next => _next;
  Phase _next;

  /// Returns all currently-available output assets for this phase.
  AssetSet get availableOutputs {
    return new AssetSet.from(_outputs.values
        .map((queue) => queue.first)
        .where((node) => node.state.isAvailable)
        .map((node) => node.asset));
  }

  Phase(this.cascade, Iterable<Transformer> transformers)
      : _transformers = transformers.toSet() {
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

  /// Gets the asset node for an input [id].
  ///
  /// If an input with that ID cannot be found, returns null.
  Future<AssetNode> getInput(AssetId id) {
    return newFuture(() {
      if (id.package == cascade.package) return _inputs[id];
      return cascade.graph.getAssetNode(id);
    });
  }

  /// Gets the asset node for an output [id].
  ///
  /// If an output with that ID cannot be found, returns null.
  Future<AssetNode> getOutput(AssetId id) {
    return newFuture(() {
      if (id.package != cascade.package) return cascade.graph.getAssetNode(id);
      if (!_outputs.containsKey(id)) return null;
      return _outputs[id].first;
    });
  }

  /// Set this phase's transformers to [transformers].
  void updateTransformers(Iterable<Transformer> transformers) {
    _onDirtyController.add(null);

    var newTransformers = transformers.toSet();
    var oldTransformers = _transformers.toSet();
    for (var removedTransformer in
         oldTransformers.difference(newTransformers)) {
      _transformers.remove(removedTransformer);

      // Remove old transforms for which [removedTransformer] was a transformer.
      for (var id in _inputs.keys) {
        // If the transformers are being adjusted for [id], it will
        // automatically pick up on [removedTransformer] being gone.
        if (_adjustTransformersFutures.containsKey(id)) continue;

        _transforms[id].removeWhere((transform) {
          if (transform.transformer != removedTransformer) return false;
          transform.remove();
          return true;
        });

        if (!_transforms[id].isEmpty) continue;
        _passThroughControllers.putIfAbsent(id, () {
          return new AssetNodeController.available(
              _inputs[id].asset, _inputs[id].transform);
        });
      }
    }

    var brandNewTransformers = newTransformers.difference(oldTransformers);
    if (brandNewTransformers.isEmpty) return;
    brandNewTransformers.forEach(_transformers.add);

    // If there are any new transformers, start re-adjusting the transforms for
    // all inputs so we pick up which inputs the new transformers apply to.
    _inputs.forEach((id, node) {
      if (_adjustTransformersFutures.containsKey(id)) return;
      _adjustTransformers(node);
    });
  }

  /// Add a new phase after this one with [transformers].
  ///
  /// This may only be called on a phase with no phase following it.
  Phase addPhase(Iterable<Transformer> transformers) {
    assert(_next == null);
    _next = new Phase(cascade, transformers);
    for (var outputs in _outputs.values) {
      _next.addInput(outputs.first);
    }
    return _next;
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

    // If there's a pass-through for this node, mark it dirty while we figure
    // out whether we need to add any transforms for it.
    var controller = _passThroughControllers[node.id];
    if (controller != null) controller.setDirty();

    // Once the input is available, hook up transformers for it. If it changes
    // while that's happening, try again.
    _adjustTransformersFutures[node.id] = _tryUntilStable(node,
        (asset, transformers) {
      var oldTransformers = _transforms[node.id]
          .map((transform) => transform.transformer).toSet();

      return _removeStaleTransforms(asset, transformers).then((_) =>
          _addFreshTransforms(node, transformers, oldTransformers));
    }).then((_) {
      _adjustPassThrough(node);

      // Now all the transforms are set up correctly and the asset is available
      // for the time being. Set up handlers for when the asset changes in the
      // future.
      node.onStateChange.first.then((state) {
        if (state.isRemoved) {
          _onDirtyController.add(null);
          _transforms.remove(node.id);
          var passThrough = _passThroughControllers.remove(node.id);
          if (passThrough != null) passThrough.setRemoved();
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
      // the node, and its pass-through.
      _transforms.remove(node.id);
      var passThrough = _passThroughControllers.remove(node.id);
      if (passThrough != null) passThrough.setRemoved();
    }).whenComplete(() {
      _adjustTransformersFutures.remove(node.id);
    });

    // Don't top-level errors coming from the input processing. Any errors will
    // eventually be piped through [process]'s returned Future.
    _adjustTransformersFutures[node.id].catchError((_) {});
  }

  // Remove any old transforms that used to have [asset] as a primary asset but
  // no longer apply to its new contents.
  Future _removeStaleTransforms(Asset asset, Set<Transformer> transformers) {
    return Future.wait(_transforms[asset.id].map((transform) {
      return newFuture(() {
        if (!transformers.contains(transform.transformer)) return false;

        // TODO(rnystrom): Catch all errors from isPrimary() and redirect to
        // results.
        return transform.transformer.isPrimary(asset);
      }).then((isPrimary) {
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
  // [oldTransformers] is the set of transformers for which there were
  // transforms that had [node] as a primary input prior to this. They don't
  // need to be checked, since their transforms were removed or preserved in
  // [_removeStaleTransforms].
  Future _addFreshTransforms(AssetNode node, Set<Transformer> transformers,
      Set<Transformer> oldTransformers) {
    return Future.wait(transformers.map((transformer) {
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

  /// Adjust whether [node] is passed through the phase unmodified, based on
  /// whether it's consumed by other transforms in this phase.
  ///
  /// If [node] was already passed-through, this will update the passed-through
  /// value.
  void _adjustPassThrough(AssetNode node) {
    assert(node.state.isAvailable);

    if (_transforms[node.id].isEmpty) {
      var controller = _passThroughControllers[node.id];
      if (controller != null) {
        controller.setAvailable(node.asset);
      } else {
        _passThroughControllers[node.id] =
            new AssetNodeController.available(node.asset, node.transform);
      }
    } else {
      var controller = _passThroughControllers.remove(node.id);
      if (controller != null) controller.setRemoved();
    }
  }

  /// Like [AssetNode.tryUntilStable], but also re-runs [callback] if this
  /// phase's transformers are modified.
  Future _tryUntilStable(AssetNode node,
      Future callback(Asset asset, Set<Transformer> transformers)) {
    var oldTransformers;
    return node.tryUntilStable((asset) {
      oldTransformers = _transformers.toSet();
      return callback(asset, _transformers);
    }).then((result) {
      if (setEquals(oldTransformers, _transformers)) return result;
      return _tryUntilStable(node, callback);
    });
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
    var newPassThroughs = _passThroughControllers.values
        .map((controller) => controller.node)
        .where((output) {
      return !_outputs.containsKey(output.id) ||
        !_outputs[output.id].contains(output);
    }).toSet();

    // Convert this to a list so we can safely modify _transforms while
    // iterating over it.
    var dirtyTransforms =
        flatten(_transforms.values.map((transforms) => transforms.toList()))
        .where((transform) => transform.isDirty).toList();

    if (dirtyTransforms.isEmpty && newPassThroughs.isEmpty) return null;

    var collisions = new Set<AssetId>();
    for (var output in newPassThroughs) {
      if (_addOutput(output)) collisions.add(output.id);
    }

    return Future.wait(dirtyTransforms.map((transform) {
      return transform.apply().then((outputs) {
        for (var output in outputs) {
          if (_addOutput(output)) collisions.add(output.id);
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

  /// Add [output] as an output of this phase, forwarding it to the next phase
  /// if necessary.
  ///
  /// Returns whether or not [output] collides with another pre-existing output.
  bool _addOutput(AssetNode output) {
    _handleOutputRemoval(output);

    if (_outputs.containsKey(output.id)) {
      _outputs[output.id].add(output);
      return true;
    }

    _outputs[output.id] = new Queue<AssetNode>.from([output]);
    if (_next != null) _next.addInput(output);
    return false;
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
      if (wasFirst && _next != null) {
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
