// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.phase_input;

import 'dart:async';

import 'asset_forwarder.dart';
import 'asset_node.dart';
import 'asset_node_set.dart';
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

  /// The controller that's used for the output node if [input] isn't
  /// overwritten by any transformers.
  ///
  /// This needs an intervening controller to ensure that the output can be
  /// marked dirty when determining whether transforms will overwrite it, and be
  /// marked removed if they do. It's null if the asset is not being passed
  /// through.
  AssetNodeController _passThroughController;

  /// A stream that emits an event whenever [this] is no longer dirty.
  ///
  /// This is synchronous in order to guarantee that it will emit an event as
  /// soon as [isDirty] flips from `true` to `false`.
  Stream get onDone => _onDoneController.stream;
  final _onDoneController = new StreamController.broadcast(sync: true);

  /// A stream that emits any new assets emitted by [this].
  ///
  /// Assets are emitted synchronously to ensure that any changes are thoroughly
  /// propagated as soon as they occur.
  Stream<AssetNode> get onAsset => _onAssetController.stream;
  final _onAssetController = new StreamController<AssetNode>(sync: true);

  /// Whether [this] is dirty and still has more processing to do.
  bool get isDirty => _isAdjustingTransformers ||
      _transforms.any((transform) => transform.isDirty);

  /// The set of assets emitted by the transformers for this input that have the
  /// same id as [input].
  final _overwritingOutputs = new AssetNodeSet();

  /// Whether [this] has been rmeoved.
  bool get _isRemoved => _onAssetController.isClosed;

  /// Whether [input] has become dirty since [_adjustTransformers] last started
  /// running.
  bool _hasBecomeDirty = false;

  /// Whether [_isAdjustingTransformers] is currently running.
  bool _isAdjustingTransformers = false;

  /// A stream that emits an event whenever any transforms that use [input] as
  /// their primary input log an entry.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  PhaseInput(this._phase, AssetNode input, Iterable<Transformer> transformers,
      this._location)
      : _transformers = transformers.toSet(),
        _inputForwarder = new AssetForwarder(input) {
    input.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        _dirty();
      }
    });

    _adjustTransformers();
  }

  /// Removes this input.
  ///
  /// This marks all outputs of the input as removed.
  void remove() {
    _onDoneController.close();
    _hasBecomeDirty = false;
    _onAssetController.close();
    _onLogPool.close();
    _inputForwarder.close();
    if (_passThroughController != null) {
      _passThroughController.setRemoved();
      _passThroughController = null;
    }
  }

  /// Mark [this] as dirty and start re-running [_adjustTransformers] if
  /// necessary.
  void _dirty() {
    // If there's a pass-through for this input, mark it dirty until we figure
    // out if a transformer will emit an asset with that id.
    if (_passThroughController != null) _passThroughController.setDirty();
    _hasBecomeDirty = true;
    if (!_isAdjustingTransformers) _adjustTransformers();
  }

  /// Set this input's transformers to [transformers].
  void updateTransformers(Iterable<Transformer> newTransformersIterable) {
    var newTransformers = newTransformersIterable.toSet();
    var oldTransformers = _transformers.toSet();
    var removedTransformers = oldTransformers.difference(newTransformers);
    for (var removedTransformer in removedTransformers) {
      _transformers.remove(removedTransformer);
    }

    var brandNewTransformers = newTransformers.difference(oldTransformers);
    brandNewTransformers.forEach(_transformers.add);

    if (removedTransformers.isNotEmpty || brandNewTransformers.isNotEmpty) {
      _dirty();
    }
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
  /// re-adjusted.
  void _adjustTransformers() {
    assert(!_isRemoved);

    _isAdjustingTransformers = true;
    input.whenAvailable((asset) {
      _hasBecomeDirty = false;

      // Take a snapshot of the existing transformers that apply to this input.
      // Since [_removeStaleTransforms] will check each of these transformers to
      // be sure [input] is still primary for them, we use this set to avoid
      // needlessly re-checking in [_addFreshTransforms].
      var oldTransformers =
          _transforms.map((transform) => transform.transformer).toSet();

      return _removeStaleTransforms().then((_) {
        if (_hasBecomeDirty || _isRemoved) return null;
        return _addFreshTransforms(oldTransformers);
      });
    }).catchError((error, stackTrace) {
      if (error is! AssetNotFoundException || error.id != input.id) throw error;

      // If the asset is removed, [input.whenAvailable] will throw an
      // [AssetNotFoundException]. In that case, just remove it.
      remove();
    }).then((_) {
      if (_isRemoved) return;

      _isAdjustingTransformers = false;
      if (_hasBecomeDirty) {
        _adjustTransformers();
      } else if (!isDirty) {
        _adjustPassThrough();
        _onDoneController.add(null);
      }
    });
  }

  // Remove any old transforms that used to have [input]'s asset as a primary
  // asset but no longer apply to its new contents.
  Future _removeStaleTransforms() {
    assert(input.state.isAvailable);

    return Future.wait(_transforms.map((transform) {
      return syncFuture(() {
        if (!_transformers.contains(transform.transformer)) return false;

        // TODO(rnystrom): Catch all errors from isPrimary() and redirect to
        // results (issue 16162).
        return transform.transformer.isPrimary(input.asset);
      }).then((isPrimary) {
        if (_hasBecomeDirty) return;
        if (isPrimary) {
          transform.markPrimary();
        } else if (_transforms.remove(transform)) {
          transform.remove();
        }
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
  Future _addFreshTransforms(Set<Transformer> oldTransformers) {
    assert(input.state.isAvailable);

    return Future.wait(_transformers.map((transformer) {
      if (oldTransformers.contains(transformer)) return new Future.value();

      // TODO(rnystrom): Catch all errors from isPrimary() and redirect to
      // results.
      return transformer.isPrimary(input.asset).then((isPrimary) {
        if (_hasBecomeDirty || !isPrimary) return;
        var transform = new TransformNode(
            _phase, transformer, input, _location);
        _transforms.add(transform);

        transform.onStateChange.listen((_) {
          if (isDirty) {
            if (_passThroughController == null) return;
            _passThroughController.setDirty();
          } else {
            _adjustPassThrough();
            _onDoneController.add(null);
          }
        });

        transform.onAsset.listen((asset) {
          if (asset.id == input.id) {
            _overwritingOutputs.add(asset);
            asset.whenRemoved(_adjustPassThrough);
            _adjustPassThrough();
          }

          _onAssetController.add(asset);
        }, onDone: () => _transforms.remove(transform));

        _onLogPool.add(transform.onLog);
      });
    }));
  }

  /// Adjust whether [input] is passed through the phase unmodified, based on
  /// whether it's overwritten by other transforms in this phase.
  ///
  /// If [input] was already passed-through, this will update the passed-through
  /// value.
  void _adjustPassThrough() {
    // If [input] is removed, [_adjustPassThrough] can still be called due to
    // [TransformNode]s marking their outputs as removed.
    if (!input.state.isAvailable) return;

    // If there's an output with the same id as the primary input, that
    // overwrites the input so it doesn't get passed through. Otherwise,
    // create a pass-through controller if none exists, or set the existing
    // one available.
    if (_overwritingOutputs.isNotEmpty) {
      if (_passThroughController != null) {
        _passThroughController.setRemoved();
        _passThroughController = null;
      }
    } else if (isDirty) {
      // If the input is dirty, we're still figuring out whether a transform
      // will overwrite the input. As such, we shouldn't pass through the asset
      // yet.
    } else if (_passThroughController == null) {
      _passThroughController = new AssetNodeController.from(input);
      _onAssetController.add(_passThroughController.node);
    } else if (_passThroughController.node.state.isDirty) {
      _passThroughController.setAvailable(input.asset);
    }
  }

  String toString() => "phase input in $_location for $input";
}
