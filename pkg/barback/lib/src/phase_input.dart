// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase_input;

import 'dart:async';
import 'dart:collection';

import 'asset.dart';
import 'asset_forwarder.dart';
import 'asset_node.dart';
import 'errors.dart';
import 'log.dart';
import 'phase.dart';
import 'stream_pool.dart';
import 'transform_node.dart';
import 'transformer.dart';
import 'utils.dart';

/// A class for watching a single [AssetNode] and running any transforms that
/// take that node as a primary input.
class PhaseInput {
  /// The phase for which this is an input.
  final Phase _phase;

  /// A string describing the location of [this] in the transformer graph.
  final String _location;

  /// The transformers to (potentially) run against [input].
  final Set<Transformer> _transformers;

  /// The transforms currently applicable to [input].
  ///
  /// These are the transforms that have been "wired up": they represent a
  /// repeatable transformation of a single concrete set of inputs. "dart2js" is
  /// a transformer. "dart2js on web/main.dart" is a transform.
  final _transforms = new Set<TransformNode>();

  /// A forwarder for the input [AssetNode] for this phase.
  ///
  /// This is used to mark the node as removed should the input ever be removed.
  final AssetForwarder _inputForwarder;

  /// The asset node for this input.
  AssetNode get input => _inputForwarder.node;

  /// The controller that's used for the output node if [input] isn't consumed
  /// by any transformers.
  ///
  /// This needs an intervening controller to ensure that the output can be
  /// marked dirty when determining whether transforms apply, and removed if
  /// they do. It's null if the asset is not being passed through.
  AssetNodeController _passThroughController;

  /// Whether [_passThroughController] has been newly created since [process]
  /// last completed.
  bool _newPassThrough = false;

  /// A Future that will complete once the transformers that consume [input] are
  /// determined.
  Future _adjustTransformersFuture;

  /// A stream that emits an event whenever this input becomes dirty and needs
  /// [process] to be called.
  ///
  /// This may emit events when the input was already dirty or while processing
  /// transforms. Events are emitted synchronously to ensure that the dirty
  /// state is thoroughly propagated as soon as any assets are changed.
  Stream get onDirty => _onDirtyPool.stream;
  final _onDirtyPool = new StreamPool.broadcast();

  /// A controller whose stream feeds into [_onDirtyPool].
  ///
  /// This is used whenever the input is changed or removed. It's sometimes
  /// redundant with the events collected from [_transforms], but this stream is
  /// necessary for removed inputs, and the transform stream is necessary for
  /// modified secondary inputs.
  final _onDirtyController = new StreamController.broadcast(sync: true);

  /// Whether this input is dirty and needs [process] to be called.
  bool get isDirty => _adjustTransformersFuture != null ||
      _newPassThrough || _transforms.any((transform) => transform.isDirty);

  /// A stream that emits an event whenever any transforms that use [input] as
  /// their primary input log an entry.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  PhaseInput(this._phase, AssetNode input, Iterable<Transformer> transformers,
      this._location)
      : _transformers = transformers.toSet(),
        _inputForwarder = new AssetForwarder(input) {
    _onDirtyPool.add(_onDirtyController.stream);

    input.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else if (_adjustTransformersFuture == null) {
        _adjustTransformers();
      }
    });

    _adjustTransformers();
  }

  /// Removes this input.
  ///
  /// This marks all outputs of the input as removed.
  void remove() {
    _onDirtyController.add(null);
    _onDirtyPool.close();
    _onLogPool.close();
    _inputForwarder.close();
    if (_passThroughController != null) {
      _passThroughController.setRemoved();
      _passThroughController = null;
    }
  }

  /// Set this input's transformers to [transformers].
  void updateTransformers(Iterable<Transformer> newTransformersIterable) {
    var newTransformers = newTransformersIterable.toSet();
    var oldTransformers = _transformers.toSet();
    for (var removedTransformer in
         oldTransformers.difference(newTransformers)) {
      _transformers.remove(removedTransformer);

      // If the transformers are being adjusted for [id], it will
      // automatically pick up on [removedTransformer] being gone.
      if (_adjustTransformersFuture != null) continue;

      _transforms.removeWhere((transform) {
        if (transform.transformer != removedTransformer) return false;
        transform.remove();
        return true;
      });
    }

    if (_transforms.isEmpty && _adjustTransformersFuture == null &&
        _passThroughController == null) {
      _passThroughController = new AssetNodeController.from(input);
      _newPassThrough = true;
    }

    var brandNewTransformers = newTransformers.difference(oldTransformers);
    if (brandNewTransformers.isEmpty) return;

    brandNewTransformers.forEach(_transformers.add);
    if (_adjustTransformersFuture == null) _adjustTransformers();
  }

  /// Force all [LazyTransformer]s' transforms in this input to begin producing
  /// concrete assets.
  void forceAllTransforms() {
    for (var transform in _transforms) {
      transform.force();
    }
  }

  /// Asynchronously determines which transformers can consume [input] as a
  /// primary input and creates transforms for them.
  ///
  /// This ensures that if [input] is modified or removed during or after the
  /// time it takes to adjust its transformers, they're appropriately
  /// re-adjusted. Its progress can be tracked in [_adjustTransformersFuture].
  void _adjustTransformers() {
    // Mark the input as dirty. This may not actually end up creating any new
    // transforms, but we want adding or removing a source asset to consistently
    // kick off a build, even if that build does nothing.
    _onDirtyController.add(null);

    // If there's a pass-through for this input, mark it dirty while we figure
    // out whether we need to add any transforms for it.
    if (_passThroughController != null) _passThroughController.setDirty();

    // Once the input is available, hook up transformers for it. If it changes
    // while that's happening, try again.
    _adjustTransformersFuture = _tryUntilStable((asset, transformers) {
      var oldTransformers =
          _transforms.map((transform) => transform.transformer).toSet();

      return _removeStaleTransforms(asset, transformers).then((_) =>
          _addFreshTransforms(transformers, oldTransformers));
    }).then((_) => _adjustPassThrough()).catchError((error) {
      if (error is! AssetNotFoundException || error.id != input.id) {
        throw error;
      }

      // If the asset is removed, [_tryUntilStable] will throw an
      // [AssetNotFoundException]. In that case, just remove it.
      remove();
    }).whenComplete(() {
      _adjustTransformersFuture = null;
    });

    // Don't top-level errors coming from the input processing. Any errors will
    // eventually be piped through [process]'s returned Future.
    _adjustTransformersFuture.catchError((_) {});
  }

  // Remove any old transforms that used to have [asset] as a primary asset but
  // no longer apply to its new contents.
  Future _removeStaleTransforms(Asset asset, Set<Transformer> transformers) {
    return Future.wait(_transforms.map((transform) {
      return newFuture(() {
        if (!transformers.contains(transform.transformer)) return false;

        // TODO(rnystrom): Catch all errors from isPrimary() and redirect to
        // results (issue 16162).
        return transform.transformer.isPrimary(asset);
      }).then((isPrimary) {
        if (isPrimary) return;
        _transforms.remove(transform);
        transform.remove();
      });
    }));
  }

  // Add new transforms for transformers that consider [input]'s asset to be a
  // primary input.
  //
  // [oldTransformers] is the set of transformers for which there were
  // transforms that had [input] as a primary input prior to this. They don't
  // need to be checked, since their transforms were removed or preserved in
  // [_removeStaleTransforms].
  Future _addFreshTransforms(Set<Transformer> transformers,
      Set<Transformer> oldTransformers) {
    return Future.wait(transformers.map((transformer) {
      if (oldTransformers.contains(transformer)) return new Future.value();

      // If the asset is unavailable, the results of this [_adjustTransformers]
      // run will be discarded, so we can just short-circuit.
      if (input.asset == null) return new Future.value();

      // We can safely access [input.asset] here even though it might have
      // changed since (as above) if it has, [_adjustTransformers] will just be
      // re-run.
      // TODO(rnystrom): Catch all errors from isPrimary() and redirect to
      // results.
      return transformer.isPrimary(input.asset).then((isPrimary) {
        if (!isPrimary) return;
        var transform = new TransformNode(
            _phase, transformer, input, _location);
        _transforms.add(transform);
        _onDirtyPool.add(transform.onDirty);
        _onLogPool.add(transform.onLog);
      });
    }));
  }

  /// Adjust whether [input] is passed through the phase unmodified, based on
  /// whether it's consumed by other transforms in this phase.
  ///
  /// If [input] was already passed-through, this will update the passed-through
  /// value.
  void _adjustPassThrough() {
    assert(input.state.isAvailable);

    if (_transforms.isEmpty) {
      if (_passThroughController != null) {
        _passThroughController.setAvailable(input.asset);
      } else {
        _passThroughController = new AssetNodeController.from(input);
        _newPassThrough = true;
      }
    } else if (_passThroughController != null) {
      _passThroughController.setRemoved();
      _passThroughController = null;
      _newPassThrough = false;
    }
  }

  /// Like [AssetNode.tryUntilStable], but also re-runs [callback] if this
  /// phase's transformers are modified.
  Future _tryUntilStable(
      Future callback(Asset asset, Set<Transformer> transformers)) {
    var oldTransformers;
    return input.tryUntilStable((asset) {
      oldTransformers = _transformers.toSet();
      return callback(asset, _transformers);
    }).then((result) {
      if (setEquals(oldTransformers, _transformers)) return result;
      return _tryUntilStable(callback);
    });
  }

  /// Processes the transforms for this input.
  ///
  /// Returns the set of newly-created asset nodes that transforms have emitted
  /// for this input. The assets returned this way are guaranteed not to be
  /// [AssetState.REMOVED].
  Future<Set<AssetNode>> process() {
    return _waitForTransformers(() => _processTransforms()).then((outputs) {
      if (input.state.isRemoved) return new Set();
      return outputs;
    });
  }

  /// Runs [callback] once all the transformers are adjusted correctly and the
  /// input is ready to be processed.
  ///
  /// If the transformers are already properly adjusted, [callback] is called
  /// synchronously to ensure that [_adjustTransformers] isn't called before the
  /// callback.
  Future _waitForTransformers(callback()) {
    if (_adjustTransformersFuture == null) return syncFuture(callback);
    return _adjustTransformersFuture.then(
        (_) => _waitForTransformers(callback));
  }

  /// Applies all currently wired up and dirty transforms.
  Future<Set<AssetNode>> _processTransforms() {
    if (input.state.isRemoved) return new Future.value(new Set());

    if (_passThroughController != null) {
      if (!_newPassThrough) return new Future.value(new Set());
      _newPassThrough = false;
      return new Future.value(
          new Set<AssetNode>.from([_passThroughController.node]));
    }

    return Future.wait(_transforms.map((transform) {
      if (!transform.isDirty) return new Future.value(new Set());
      return transform.apply();
    })).then((outputs) => unionAll(outputs));
  }

  String toString() => "phase input in $_location for $input";
}
