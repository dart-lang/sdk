// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform_node;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'declaring_transform.dart';
import 'errors.dart';
import 'lazy_transformer.dart';
import 'log.dart';
import 'phase.dart';
import 'stream_pool.dart';
import 'transform.dart';
import 'transformer.dart';
import 'utils.dart';

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

  /// A string describing the location of [this] in the transformer graph.
  final String _location;

  /// The subscription to [primary]'s [AssetNode.onStateChange] stream.
  StreamSubscription _primarySubscription;

  /// The subscription to [phase]'s [Phase.onAsset] stream.
  StreamSubscription<AssetNode> _phaseSubscription;

  /// Whether [this] is dirty and still has more processing to do.
  bool get isDirty => !_state.isDone;

  /// Whether [transformer] is lazy and this transform has yet to be forced.
  bool _isLazy;

  /// The subscriptions to each input's [AssetNode.onStateChange] stream.
  final _inputSubscriptions = new Map<AssetId, StreamSubscription>();

  /// The controllers for the asset nodes emitted by this node.
  final _outputControllers = new Map<AssetId, AssetNodeController>();

  final _missingInputs = new Set<AssetId>();

  /// The controller that's used to pass [primary] through [this] if it's not
  /// consumed or overwritten.
  ///
  /// This needs an intervening controller to ensure that the output can be
  /// marked dirty when determining whether [this] will consume or overwrite it,
  /// and be marked removed if it does. [_passThroughController] will be null
  /// if the asset is not being passed through.
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
  final _onAssetController =
      new StreamController<AssetNode>.broadcast(sync: true);

  /// A stream that emits an event whenever this transform logs an entry.
  ///
  /// This is synchronous because error logs can cause the transform to fail, so
  /// we need to ensure that their processing isn't delayed until after the
  /// transform or build has finished.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  /// The current state of [this].
  var _state = _TransformNodeState.PROCESSING;

  /// Whether [this] has been marked as removed.
  bool get _isRemoved => _onAssetController.isClosed;

  /// Whether the most recent run of this transform has declared that it
  /// consumes the primary input.
  ///
  /// Defaults to `false`. This is not meaningful unless [_state] is
  /// [_TransformNodeState.APPLIED].
  bool _consumePrimary = false;

  TransformNode(this.phase, Transformer transformer, this.primary,
      this._location)
      : transformer = transformer,
        _isLazy = transformer is LazyTransformer {
    _primarySubscription = primary.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        _dirty(primaryChanged: true);
      }
    });

    _phaseSubscription = phase.previous.onAsset.listen((node) {
      if (_missingInputs.contains(node.id)) _dirty(primaryChanged: false);
    });

    _process();
  }

  /// The [TransformInfo] describing this node.
  ///
  /// [TransformInfo] is the publicly-visible representation of a transform
  /// node.
  TransformInfo get info => new TransformInfo(transformer, primary.id);

  /// Marks this transform as removed.
  ///
  /// This causes all of the transform's outputs to be marked as removed as
  /// well. Normally this will be automatically done internally based on events
  /// from the primary input, but it's possible for a transform to no longer be
  /// valid even if its primary input still exists.
  void remove() {
    _onAssetController.close();
    _onDoneController.close();
    _primarySubscription.cancel();
    _phaseSubscription.cancel();
    _clearInputSubscriptions();
    _clearOutputs();
    if (_passThroughController != null) {
      _passThroughController.setRemoved();
      _passThroughController = null;
    }
  }

  /// If [transformer] is lazy, ensures that its concrete outputs will be
  /// generated.
  void force() {
    // TODO(nweiz): we might want to have a timeout after which, if the
    // transform's outputs have gone unused, we switch it back to lazy mode.
    if (!_isLazy) return;
    _isLazy = false;
    _dirty(primaryChanged: false);
  }

  /// Marks this transform as dirty.
  ///
  /// This causes all of the transform's outputs to be marked as dirty as well.
  /// [primaryChanged] should be true if and only if [this] was set dirty
  /// because [primary] changed.
  void _dirty({bool primaryChanged: false}) {
    if (!primaryChanged && _state.isNotPrimary) return;

    if (_passThroughController != null) _passThroughController.setDirty();
    for (var controller in _outputControllers.values) {
      controller.setDirty();
    }

    if (_state.isDone) {
      if (primaryChanged) {
        _process();
      } else {
        _apply();
      }
    } else if (primaryChanged) {
      _state = _TransformNodeState.NEEDS_IS_PRIMARY;
    } else if (!_state.needsIsPrimary) {
      _state = _TransformNodeState.NEEDS_APPLY;
    }
  }

  /// Determines whether [primary] is primary for [transformer], and if so runs
  /// [transformer.apply].
  void _process() {
    // Clear all the old input subscriptions. If an input is re-used, we'll
    // re-subscribe.
    _clearInputSubscriptions();
    _state = _TransformNodeState.PROCESSING;
    primary.whenAvailable((_) {
      _state = _TransformNodeState.PROCESSING;
      return transformer.isPrimary(primary.asset.id);
    }).catchError((error, stackTrace) {
      // If the transform became dirty while processing, ignore any errors from
      // it.
      if (_state.needsIsPrimary || _isRemoved) return false;

      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      phase.cascade.reportError(_wrapException(error, stackTrace));

      return false;
    }).then((isPrimary) {
      if (_isRemoved) return;
      if (_state.needsIsPrimary) {
        _process();
      } else if (isPrimary) {
        _apply();
      } else {
        _clearOutputs();
        _emitPassThrough();
        _state = _TransformNodeState.NOT_PRIMARY;
        _onDoneController.add(null);
      }
    });
  }

  /// Applies this transform.
  void _apply() {
    assert(!_onAssetController.isClosed);

    // Clear input subscriptions here as well as in [_process] because [_apply]
    // may be restarted independently if only a secondary input changes.
    _clearInputSubscriptions();
    _state = _TransformNodeState.PROCESSING;
    primary.whenAvailable((_) {
      if (_state.needsIsPrimary) return null;
      _state = _TransformNodeState.PROCESSING;
      // TODO(nweiz): If [transformer] is a [DeclaringTransformer] but not a
      // [LazyTransformer], we can get some mileage out of doing a declarative
      // first so we know how to hook up the assets.
      if (_isLazy) return _declareLazy();
      return _applyImmediate();
    }).catchError((error, stackTrace) {
      // If the transform became dirty while processing, ignore any errors from
      // it.
      if (!_state.isProcessing || _isRemoved) return false;

      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      phase.cascade.reportError(_wrapException(error, stackTrace));
      return true;
    }).then((hadError) {
      if (_isRemoved) return;

      if (_state.needsIsPrimary) {
        _process();
      } else if (_state.needsApply) {
        _apply();
      } else {
        assert(_state.isProcessing);
        if (hadError) {
          _clearOutputs();
          _dontEmitPassThrough();
        }

        _state = _TransformNodeState.APPLIED;
        _onDoneController.add(null);
      }
    });
  }

  /// Gets the asset for an input [id].
  ///
  /// If an input with [id] cannot be found, throws an [AssetNotFoundException].
  Future<Asset> getInput(AssetId id) {
    return phase.previous.getOutput(id).then((node) {
      // Throw if the input isn't found. This ensures the transformer's apply
      // is exited. We'll then catch this and report it through the proper
      // results stream.
      if (node == null) {
        _missingInputs.add(id);
        throw new AssetNotFoundException(id);
      }

      _inputSubscriptions.putIfAbsent(node.id, () {
        return node.onStateChange.listen((_) => _dirty(primaryChanged: false));
      });

      return node.asset;
    });
  }

  /// Applies the transform so that it produces concrete (as opposed to lazy)
  /// outputs.
  ///
  /// Returns whether or not the transformer logged an error.
  Future<bool> _applyImmediate() {
    var transformController = new TransformController(this);
    _onLogPool.add(transformController.onLog);

    return syncFuture(() {
      return transformer.apply(transformController.transform);
    }).then((_) {
      if (!_state.isProcessing || _onAssetController.isClosed) return false;
      if (transformController.loggedError) return true;

      _consumePrimary = transformController.consumePrimary;

      var newOutputs = transformController.outputs;
      // Any ids that are for a different package are invalid.
      var invalidIds = newOutputs
          .map((asset) => asset.id)
          .where((id) => id.package != phase.cascade.package)
          .toSet();
      for (var id in invalidIds) {
        newOutputs.removeId(id);
        // TODO(nweiz): report this as a warning rather than a failing error.
        phase.cascade.reportError(new InvalidOutputException(info, id));
      }

      // Remove outputs that used to exist but don't anymore.
      for (var id in _outputControllers.keys.toList()) {
        if (newOutputs.containsId(id)) continue;
        _outputControllers.remove(id).setRemoved();
      }

      // Emit or stop emitting the pass-through asset between removing and
      // adding outputs to ensure there are no collisions.
      if (!newOutputs.containsId(primary.id)) {
        _emitPassThrough();
      } else {
        _dontEmitPassThrough();
      }

      // Store any new outputs or new contents for existing outputs.
      for (var asset in newOutputs) {
        var controller = _outputControllers[asset.id];
        if (controller != null) {
          controller.setAvailable(asset);
        } else {
          var controller = new AssetNodeController.available(asset, this);
          _outputControllers[asset.id] = controller;
          _onAssetController.add(controller.node);
        }
      }

      return false;
    });
  }

  /// Applies the transform in declarative mode so that it produces lazy
  /// outputs.
  ///
  /// Returns whether or not the transformer logged an error.
  Future<bool> _declareLazy() {
    var transformController = new DeclaringTransformController(this);

    return syncFuture(() {
      return (transformer as LazyTransformer)
          .declareOutputs(transformController.transform);
    }).then((_) {
      if (!_state.isProcessing || _onAssetController.isClosed) return false;
      if (transformController.loggedError) return true;

      _consumePrimary = transformController.consumePrimary;

      var newIds = transformController.outputIds;
      var invalidIds =
          newIds.where((id) => id.package != phase.cascade.package).toSet();
      for (var id in invalidIds) {
        newIds.remove(id);
        // TODO(nweiz): report this as a warning rather than a failing error.
        phase.cascade.reportError(new InvalidOutputException(info, id));
      }

      // Remove outputs that used to exist but don't anymore.
      for (var id in _outputControllers.keys.toList()) {
        if (newIds.contains(id)) continue;
        _outputControllers.remove(id).setRemoved();
      }

      // Emit or stop emitting the pass-through asset between removing and
      // adding outputs to ensure there are no collisions.
      if (!newIds.contains(primary.id)) {
        _emitPassThrough();
      } else {
        _dontEmitPassThrough();
      }

      for (var id in newIds) {
        var controller = _outputControllers[id];
        if (controller != null) {
          controller.setLazy(force);
        } else {
          var controller = new AssetNodeController.lazy(id, force, this);
          _outputControllers[id] = controller;
          _onAssetController.add(controller.node);
        }
      }

      return false;
    });
  }

  /// Cancels all subscriptions to secondary input nodes.
  void _clearInputSubscriptions() {
    _missingInputs.clear();
    for (var subscription in _inputSubscriptions.values) {
      subscription.cancel();
    }
    _inputSubscriptions.clear();
  }

  /// Removes all output assets.
  void _clearOutputs() {
    // Remove all the previously-emitted assets.
    for (var controller in _outputControllers.values) {
      controller.setRemoved();
    }
    _outputControllers.clear();
  }

  /// Emit the pass-through asset if it's not being emitted already.
  void _emitPassThrough() {
    assert(!_outputControllers.containsKey(primary.id));

    if (_consumePrimary) return;
    if (_passThroughController == null) {
      _passThroughController = new AssetNodeController.from(primary);
      _onAssetController.add(_passThroughController.node);
    } else {
      _passThroughController.setAvailable(primary.asset);
    }
  }

  /// Stop emitting the pass-through asset if it's being emitted already.
  void _dontEmitPassThrough() {
    if (_passThroughController == null) return;
    _passThroughController.setRemoved();
    _passThroughController = null;
  }

  BarbackException _wrapException(error, StackTrace stackTrace) {
    if (error is! AssetNotFoundException) {
      return new TransformerException(info, error, stackTrace);
    } else {
      return new MissingInputException(info, error.id);
    }
  }

  String toString() =>
    "transform node in $_location for $transformer on $primary";
}

/// The enum of states that [TransformNode] can be in.
class _TransformNodeState {
  /// The transform node is running [Transformer.isPrimary] or
  /// [Transformer.apply] and doesn't need to re-run them.
  ///
  /// If there are no external changes by the time the processing finishes, this
  /// will transition to [APPLIED] or [NOT_PRIMARY] depending on the result of
  /// [Transformer.isPrimary]. If the primary input changes, this will
  /// transition to [NEEDS_IS_PRIMARY]. If a secondary input changes, this will
  /// transition to [NEEDS_APPLY].
  static final PROCESSING = const _TransformNodeState._("processing");

  /// The transform is running [Transformer.isPrimary] or [Transformer.apply],
  /// but since it started the primary input changed, so it will need to re-run
  /// [Transformer.isPrimary].
  ///
  /// This will always transition to [Transformer.PROCESSING].
  static final NEEDS_IS_PRIMARY =
    const _TransformNodeState._("needs isPrimary");

  /// The transform is running [Transformer.apply], but since it started a
  /// secondary input changed, so it will need to re-run [Transformer.apply].
  ///
  /// If there are no external changes by the time [Transformer.apply] finishes,
  /// this will transition to [PROCESSING]. If the primary input changes, this
  /// will transition to [NEEDS_IS_PRIMARY].
  static final NEEDS_APPLY = const _TransformNodeState._("needs apply");

  /// The transform has finished running [Transformer.apply], whether or not it
  /// emitted an error.
  ///
  /// If the primary input or a secondary input changes, this will transition to
  /// [PROCESSING].
  static final APPLIED = const _TransformNodeState._("applied");

  /// The transform has finished running [Transformer.isPrimary], which returned
  /// `false`.
  ///
  /// If the primary input changes, this will transition to [PROCESSING].
  static final NOT_PRIMARY = const _TransformNodeState._("not primary");

  /// Whether [this] is [PROCESSING].
  bool get isProcessing => this == _TransformNodeState.PROCESSING;

  /// Whether [this] is [NEEDS_IS_PRIMARY].
  bool get needsIsPrimary => this == _TransformNodeState.NEEDS_IS_PRIMARY;

  /// Whether [this] is [NEEDS_APPLY].
  bool get needsApply => this == _TransformNodeState.NEEDS_APPLY;

  /// Whether [this] is [APPLIED].
  bool get isApplied => this == _TransformNodeState.APPLIED;

  /// Whether [this] is [NOT_PRIMARY].
  bool get isNotPrimary => this == _TransformNodeState.NOT_PRIMARY;

  /// Whether the transform has finished running [Transformer.isPrimary] and
  /// [Transformer.apply].
  ///
  /// Specifically, whether [this] is [APPLIED] or [NOT_PRIMARY].
  bool get isDone => isApplied || isNotPrimary;

  final String name;

  const _TransformNodeState._(this.name);

  String toString() => name;
}
