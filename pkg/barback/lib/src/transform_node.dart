// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform_node;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'declaring_transform.dart';
import 'declaring_transformer.dart';
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
  bool get isDirty => _state != _State.NOT_PRIMARY && _state != _State.APPLIED;

  /// Whether [transformer] is lazy and this transform has yet to be forced.
  bool _isLazy;

  /// The subscriptions to each input's [AssetNode.onStateChange] stream.
  final _inputSubscriptions = new Map<AssetId, StreamSubscription>();

  /// The controllers for the asset nodes emitted by this node.
  final _outputControllers = new Map<AssetId, AssetNodeController>();

  /// The ids of inputs the transformer tried and failed to read last time it
  /// ran.
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

  /// A controller for log entries emitted by this node.
  final _onLogController = new StreamController<LogEntry>.broadcast(sync: true);

  /// The current state of [this].
  var _state = _State.COMPUTING_IS_PRIMARY;

  /// Whether [this] has been marked as removed.
  bool get _isRemoved => _onAssetController.isClosed;

  /// Whether the most recent run of this transform has declared that it
  /// consumes the primary input.
  ///
  /// Defaults to `false`. This is not meaningful unless [_state] is
  /// [_State.APPLIED].
  bool _consumePrimary = false;

  /// The set of output ids that [transformer] declared it would emit.
  ///
  /// This is only non-null if [transformer] is a [DeclaringTransformer] and its
  /// [declareOutputs] has been run successfully.
  Set<AssetId> _declaredOutputs;

  TransformNode(this.phase, Transformer transformer, this.primary,
      this._location)
      : transformer = transformer,
        _isLazy = transformer is LazyTransformer {
    _onLogPool.add(_onLogController.stream);

    _primarySubscription = primary.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        _dirty();
      }
    });

    _phaseSubscription = phase.previous.onAsset.listen((node) {
      if (_missingInputs.contains(node.id)) _dirty();
    });

    _isPrimary();
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
    _onLogController.close();
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
    _dirty();
  }

  /// Marks this transform as dirty.
  ///
  /// This causes all of the transform's outputs to be marked as dirty as well.
  void _dirty() {
    if (_state == _State.NOT_PRIMARY) {
      _emitPassThrough();
      return;
    }
    if (_state == _State.COMPUTING_IS_PRIMARY || _isLazy) return;

    if (_passThroughController != null) _passThroughController.setDirty();
    for (var controller in _outputControllers.values) {
      controller.setDirty();
    }

    if (_state == _State.APPLIED) {
      _apply();
    } else {
      _state = _State.NEEDS_APPLY;
    }
  }

  /// Runs [transformer.isPrimary] and adjusts [this]'s state according to the
  /// result.
  ///
  /// This will also run [_declareOutputs] and/or [_apply] as appropriate.
  void _isPrimary() {
    syncFuture(() => transformer.isPrimary(primary.id))
        .catchError((error, stackTrace) {
      if (_isRemoved) return false;

      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      phase.cascade.reportError(_wrapException(error, stackTrace));

      return false;
    }).then((isPrimary) {
      if (_isRemoved) return null;
      if (isPrimary) {
        return _declareOutputs().then((_) {
          if (_isRemoved) return;
          if (_isLazy) {
            _state = _State.APPLIED;
            _onDoneController.add(null);
          } else {
            _apply();
          }
        });
      }

      _emitPassThrough();
      _state = _State.NOT_PRIMARY;
      _onDoneController.add(null);
    });
  }

  /// Runs [transform.declareOutputs] and emits the resulting assets as dirty
  /// assets.
  Future _declareOutputs() {
    if (transformer is! DeclaringTransformer) return new Future.value();

    var controller = new DeclaringTransformController(this);
    return syncFuture(() {
      return (transformer as DeclaringTransformer)
          .declareOutputs(controller.transform);
    }).then((_) {
      if (_isRemoved) return;
      if (controller.loggedError) return;

      _consumePrimary = controller.consumePrimary;
      _declaredOutputs = controller.outputIds;
      var invalidIds = _declaredOutputs
          .where((id) => id.package != phase.cascade.package).toSet();
      for (var id in invalidIds) {
        _declaredOutputs.remove(id);
        // TODO(nweiz): report this as a warning rather than a failing error.
        phase.cascade.reportError(new InvalidOutputException(info, id));
      }

      if (!_declaredOutputs.contains(primary.id)) _emitPassThrough();

      for (var id in _declaredOutputs) {
        var controller = transformer is LazyTransformer
            ? new AssetNodeController.lazy(id, force, this)
            : new AssetNodeController(id, this);
        _outputControllers[id] = controller;
        _onAssetController.add(controller.node);
      }
    }).catchError((error, stackTrace) {
      if (_isRemoved) return;
      phase.cascade.reportError(_wrapException(error, stackTrace));
    });
  }

  /// Applies this transform.
  void _apply() {
    assert(!_isRemoved && !_isLazy);

    // Clear input subscriptions here as well as in [_process] because [_apply]
    // may be restarted independently if only a secondary input changes.
    _clearInputSubscriptions();
    _state = _State.APPLYING;
    _runApply().then((hadError) {
      if (_isRemoved) return;

      if (_state == _State.NEEDS_APPLY) {
        _apply();
        return;
      }

      assert(_state == _State.APPLYING);
      if (hadError) {
        _clearOutputs();
        // If the transformer threw an error, we don't want to emit the
        // pass-through asset in case it will be overwritten by the transformer.
        // However, if the transformer declared that it wouldn't overwrite or
        // consume the pass-through asset, we can safely emit it.
        if (_declaredOutputs != null && !_consumePrimary &&
            !_declaredOutputs.contains(primary.id)) {
          _emitPassThrough();
        } else {
          _dontEmitPassThrough();
        }
      }

      _state = _State.APPLIED;
      _onDoneController.add(null);
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
        return node.onStateChange.listen((_) => _dirty());
      });

      return node.asset;
    });
  }

  /// Run [Transformer.apply] as soon as [primary] is available.
  ///
  /// Returns whether or not an error occurred while running the transformer.
  Future<bool> _runApply() {
    var transformController = new TransformController(this);
    _onLogPool.add(transformController.onLog);

    return primary.whenAvailable((_) {
      if (_isRemoved) return null;
      _state = _State.APPLYING;
      return syncFuture(() => transformer.apply(transformController.transform));
    }).then((_) {
      if (_state == _State.NEEDS_APPLY || _isRemoved) return false;
      if (transformController.loggedError) return true;
      _handleApplyResults(transformController);
      return false;
    }).catchError((error, stackTrace) {
      // If the transform became dirty while processing, ignore any errors from
      // it.
      if (_state == _State.NEEDS_APPLY || _isRemoved) return false;

      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      phase.cascade.reportError(_wrapException(error, stackTrace));
      return true;
    });
  }

  /// Handle the results of running [Transformer.apply].
  ///
  /// [transformController] should be the controller for the [Transform] passed
  /// to [Transformer.apply].
  void _handleApplyResults(TransformController transformController) {
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

    if (_declaredOutputs != null) {
      var missingOutputs = _declaredOutputs.difference(
          newOutputs.map((asset) => asset.id).toSet());
      if (missingOutputs.isNotEmpty) {
        _warn("This transformer didn't emit declared "
            "${pluralize('output asset', missingOutputs.length)} "
            "${toSentence(missingOutputs)}.");
      }
    }

    // Remove outputs that used to exist but don't anymore.
    for (var id in _outputControllers.keys.toList()) {
      if (newOutputs.containsId(id)) continue;
      _outputControllers.remove(id).setRemoved();
    }

    // Emit or stop emitting the pass-through asset between removing and
    // adding outputs to ensure there are no collisions.
    if (!_consumePrimary && !newOutputs.containsId(primary.id)) {
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
    } else if (primary.state.isDirty) {
      _passThroughController.setDirty();
    } else if (!_passThroughController.node.state.isAvailable) {
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

  /// Emit a warning about the transformer on [id].
  void _warn(String message) {
    _onLogController.add(
        new LogEntry(info, primary.id, LogLevel.WARNING, message, null));
  }

  String toString() =>
    "transform node in $_location for $transformer on $primary";
}

/// The enum of states that [TransformNode] can be in.
class _State {
  /// The transform is running [Transformer.isPrimary].
  ///
  /// This is the initial state of the transformer. Once [Transformer.isPrimary]
  /// finishes running, this will transition to [APPLYING] if the input is
  /// primary, or [NOT_PRIMARY] if it's not.
  static final COMPUTING_IS_PRIMARY = const _State._("computing isPrimary");

  /// The transform is running [Transformer.apply].
  ///
  /// If an input changes while in this state, it will transition to
  /// [NEEDS_APPLY]. If the [TransformNode] is still in this state when
  /// [Transformer.apply] finishes running, it will transition to [APPLIED].
  static final APPLYING = const _State._("applying");

  /// The transform is running [Transformer.apply], but an input changed after
  /// it started, so it will need to re-run [Transformer.apply].
  ///
  /// This will transition to [APPLYING] once [Transformer.apply] finishes
  /// running.
  static final NEEDS_APPLY = const _State._("needs apply");

  /// The transform has finished running [Transformer.apply], whether or not it
  /// emitted an error.
  ///
  /// If the transformer is lazy, the [TransformNode] can also be in this state
  /// when [Transformer.declareOutputs] has been run but [Transformer.apply] has
  /// not.
  ///
  /// If an input changes, this will transition to [APPLYING].
  static final APPLIED = const _State._("applied");

  /// The transform has finished running [Transformer.isPrimary], which returned
  /// `false`.
  ///
  /// This will never transition to another state.
  static final NOT_PRIMARY = const _State._("not primary");

  final String name;

  const _State._(this.name);

  String toString() => name;
}
