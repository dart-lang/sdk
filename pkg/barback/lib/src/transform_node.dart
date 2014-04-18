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
  bool get isDirty => _state != _State.NOT_PRIMARY &&
      _state != _State.APPLIED && _state != _State.DECLARED;

  /// Whether this transform is deferred.
  ///
  /// A transform is deferred if either its transformer is lazy or if its
  /// transformer is declaring and its primary input comes from a deferred
  /// transformer.
  final bool deferred;

  /// Whether this is a deferred transform waiting for [force] to be called to
  /// generate inputs.
  ///
  /// This defaults to `true` for deferred transforms and `false` otherwise.
  /// During or after running `isPrimary` or `declareOutputs`, this may become
  /// `false`, indicating that the transform has been forced and should generate
  /// outputs as soon as possible. It will only be set back to `true` if an
  /// input changes *after* `apply` has completed.
  bool _awaitingForce;

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
  var _state = _State.DECLARING;

  /// Whether [this] has been marked as removed.
  bool get _isRemoved => _onAssetController.isClosed;

  /// Whether the most recent run of this transform has declared that it
  /// consumes the primary input.
  ///
  /// Defaults to `false`. This is not meaningful unless [_state] is
  /// [_State.APPLIED] or [_State.DECLARED].
  bool _consumePrimary = false;

  /// The set of output ids that [transformer] declared it would emit.
  ///
  /// This is only non-null if [transformer] is a [DeclaringTransformer] and its
  /// [declareOutputs] has been run successfully.
  Set<AssetId> _declaredOutputs;

  TransformNode(this.phase, Transformer transformer, AssetNode primary,
      this._location)
      : transformer = transformer,
        primary = primary,
        deferred = transformer is LazyTransformer ||
            (transformer is DeclaringTransformer && primary.deferred) {
    _awaitingForce = deferred;

    _onLogPool.add(_onLogController.stream);

    _primarySubscription = primary.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        if (state.isDirty && !deferred) primary.force();
        // If this is deferred but applying, that means it must have been
        // forced, so we should ensure its input remains forced as well.
        if (deferred && _state == _State.APPLYING) primary.force();
        _dirty();
      }
    });

    _phaseSubscription = phase.previous.onAsset.listen((node) {
      if (!_missingInputs.contains(node.id)) return;
      if (!deferred) node.force();
      _dirty();
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

  /// If [this] is deferred, ensures that its concrete outputs will be
  /// generated.
  void force() {
    if (!_awaitingForce) return;
    primary.force();
    _awaitingForce = false;
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

    // If we're in the process of running [isPrimary] or [declareOutputs], we
    // already know that [apply] needs to be run so there's nothing we need to
    // mark as dirty.
    if (_state == _State.DECLARING) return;

    // If we're waiting until [force] is called to run [apply], we don't want to
    // run [apply] too early.
    if (_awaitingForce) return;

    if (_state == _State.APPLIED && deferred) {
      // Transition to DECLARED, indicating that we know what outputs [apply]
      // will emit but we're waiting to emit them concretely until [force] is
      // called.
      _state = _State.DECLARED;
      _awaitingForce = true;
      for (var controller in _outputControllers.values) {
        controller.setLazy(force);
      }
      return;
    }

    if (_passThroughController != null) _passThroughController.setDirty();
    for (var controller in _outputControllers.values) {
      controller.setDirty();
    }

    if (_state == _State.APPLIED || _state == _State.DECLARED) {
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
        if (!deferred) primary.force();
        return _declareOutputs().then((_) {
          if (_isRemoved) return;
          if (_awaitingForce) {
            _state = _State.DECLARED;
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
        var controller = _awaitingForce
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
    assert(!_isRemoved && !_awaitingForce);

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
        return node.onStateChange.listen((state) => _dirty());
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
  /// The transform is running [Transformer.isPrimary] followed by
  /// [DeclaringTransformer.declareOutputs] (for a [DeclaringTransformer]).
  ///
  /// This is the initial state of the transformer, and it will only occur once
  /// since [Transformer.isPrimary] and [DeclaringTransformer.declareOutputs]
  /// are independent of the contents of the primary input. Once the two methods
  /// finish running, this will transition to [NOT_PRIMARY] if the input isn't
  /// primary, [DECLARED] if the transform is deferred, and [APPLYING]
  /// otherwise.
  static final DECLARING = const _State._("computing isPrimary");

  /// The transform is deferred and has run
  /// [DeclaringTransformer.declareOutputs] but hasn't yet been forced.
  ///
  /// This will transition to [APPLYING] when one of the outputs has been
  /// forced.
  static final DECLARED = const _State._("declared");

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
  /// If the transformer is deferred, the [TransformNode] can also be in this
  /// state when [Transformer.declareOutputs] has been run but
  /// [Transformer.apply] has not.
  ///
  /// If an input changes, this will transition to [DECLARED] if the transform
  /// is deferred and [APPLYING] otherwise.
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
