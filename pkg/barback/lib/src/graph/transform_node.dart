// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.graph.transform_node;

import 'dart:async';

import '../asset/asset.dart';
import '../asset/asset_id.dart';
import '../asset/asset_node.dart';
import '../asset/asset_node_set.dart';
import '../errors.dart';
import '../log.dart';
import '../transformer/aggregate_transform.dart';
import '../transformer/aggregate_transformer.dart';
import '../transformer/declaring_aggregate_transform.dart';
import '../transformer/declaring_aggregate_transformer.dart';
import '../transformer/lazy_aggregate_transformer.dart';
import '../utils.dart';
import 'node_status.dart';
import 'node_streams.dart';
import 'phase.dart';
import 'transformer_classifier.dart';

/// Describes a transform on a set of assets and its relationship to the build
/// dependency graph.
///
/// Keeps track of whether it's dirty and needs to be run and which assets it
/// depends on.
class TransformNode {
  /// The aggregate key for this node.
  final String key;

  /// The [TransformerClassifier] that [this] belongs to.
  final TransformerClassifier classifier;

  /// The [Phase] that this transform runs in.
  Phase get phase => classifier.phase;

  /// The [AggregateTransformer] to apply to this node's inputs.
  final AggregateTransformer transformer;

  /// The primary asset nodes this transform runs on.
  final _primaries = new AssetNodeSet();

  /// A string describing the location of [this] in the transformer graph.
  final String _location;

  /// The subscription to the [_primaries]' [AssetNode.onStateChange] streams.
  final _primarySubscriptions = new Map<AssetId, StreamSubscription>();

  /// The subscription to [phase]'s [Phase.onAsset] stream.
  StreamSubscription<AssetNode> _phaseAssetSubscription;

  /// The subscription to [phase]'s [Phase.onStatusChange] stream.
  StreamSubscription<NodeStatus> _phaseStatusSubscription;

  /// How far along [this] is in processing its assets.
  NodeStatus get status {
    if (_state == _State.APPLIED || _state == _State.DECLARED) {
      return NodeStatus.IDLE;
    }

    if (_declaring && _state != _State.DECLARING &&
        _state != _State.NEEDS_DECLARE) {
      return NodeStatus.MATERIALIZING;
    } else {
      return NodeStatus.RUNNING;
    }
  }

  /// The [TransformInfo] describing this node.
  ///
  /// [TransformInfo] is the publicly-visible representation of a transform
  /// node.
  TransformInfo get info => new TransformInfo(transformer,
      new AssetId(phase.cascade.package, key));

  /// Whether this is a declaring transform.
  ///
  /// This is usually identical to `transformer is
  /// DeclaringAggregateTransformer`, but if a declaring and non-lazy
  /// transformer emits an error during `declareOutputs` it's treated as though
  /// it wasn't declaring.
  bool get _declaring => transformer is DeclaringAggregateTransformer &&
      (_state == _State.DECLARING || _declaredOutputs != null);

  /// Whether this transform has been forced since it last finished applying.
  ///
  /// A transform being forced means it should run until it generates outputs
  /// and is no longer dirty. This is always true for non-declaring
  /// transformers, since they always need to eagerly generate outputs.
  bool _forced;

  /// The subscriptions to each secondary input's [AssetNode.onStateChange]
  /// stream.
  final _secondarySubscriptions = new Map<AssetId, StreamSubscription>();

  /// The controllers for the asset nodes emitted by this node.
  final _outputControllers = new Map<AssetId, AssetNodeController>();

  /// The ids of inputs the transformer tried and failed to read last time it
  /// ran.
  final _missingInputs = new Set<AssetId>();

  /// The controllers that are used to pass each primary input through [this] if
  /// it's not consumed or overwritten.
  ///
  /// This needs an intervening controller to ensure that the output can be
  /// marked dirty when determining whether [this] will consume or overwrite it,
  /// and be marked removed if it does. No pass-through controller will exist
  /// for primary inputs that are not being passed through.
  final _passThroughControllers = new Map<AssetId, AssetNodeController>();

  /// The asset node for this transform.
  final _streams = new NodeStreams();
  Stream<NodeStatus> get onStatusChange => _streams.onStatusChange;
  Stream<AssetNode> get onAsset => _streams.onAsset;
  Stream<LogEntry> get onLog => _streams.onLog;

  /// The current state of [this].
  var _state = _State.DECLARED;

  /// Whether [this] has been marked as removed.
  bool get _isRemoved => _streams.onAssetController.isClosed;

  // If [transformer] is declaring but not lazy and [primary] is available, we
  // can run [apply] even if [force] hasn't been called, since [transformer]
  // should run eagerly if possible.
  bool get _canRunDeclaringEagerly =>
      _declaring && transformer is! LazyAggregateTransformer &&
      _primaries.every((input) => input.state.isAvailable);

  /// Which primary inputs the most recent run of this transform has declared
  /// that it consumes.
  ///
  /// This starts out `null`, indicating that the transform hasn't declared
  /// anything yet. This is not meaningful unless [_state] is [_State.APPLIED]
  /// or [_State.DECLARED].
  Set<AssetId> _consumedPrimaries;

  /// The set of output ids that [transformer] declared it would emit.
  ///
  /// This is only non-null if [transformer] is a
  /// [DeclaringAggregateTransformer] and its [declareOutputs] has been run
  /// successfully.
  Set<AssetId> _declaredOutputs;

  /// The controller for the currently-running
  /// [DeclaringAggregateTransformer.declareOutputs] call's
  /// [DeclaringAggregateTransform].
  ///
  /// This will be non-`null` when
  /// [DeclaringAggregateTransformer.declareOutputs] is running. This means that
  /// it's always non-`null` when [_state] is [_State.DECLARING], sometimes
  /// non-`null` when it's [_State.NEEDS_DECLARE], and always `null` otherwise.
  DeclaringAggregateTransformController _declareController;

  /// The controller for the currently-running [AggregateTransformer.apply]
  /// call's [AggregateTransform].
  ///
  /// This will be non-`null` when [AggregateTransform.apply] is running, which
  /// means that it's always non-`null` when [_state] is [_State.APPLYING] or
  /// [_State.NEEDS_APPLY], sometimes non-`null` when it's
  /// [_State.NEEDS_DECLARE], and always `null` otherwise.
  AggregateTransformController _applyController;

  /// The number of secondary inputs that have been requested but not yet
  /// produced.
  int _pendingSecondaryInputs = 0;

  /// A stopwatch that tracks the total time spent in a transformer's `apply`
  /// function.
  final _timeInTransformer = new Stopwatch();

  /// A stopwatch that tracks the time in a transformer's `apply` function spent
  /// waiting for [getInput] calls to complete.
  final _timeAwaitingInputs = new Stopwatch();

  TransformNode(this.classifier, this.transformer, this.key, this._location) {
    _forced = transformer is! DeclaringAggregateTransformer;

    _phaseAssetSubscription = phase.previous.onAsset.listen((node) {
      if (!_missingInputs.contains(node.id)) return;
      if (_forced) node.force();
      _dirty();
    });

    _phaseStatusSubscription = phase.previous.onStatusChange.listen((status) {
      if (status == NodeStatus.RUNNING) return;

      _maybeFinishDeclareController();
      _maybeFinishApplyController();
    });

    classifier.onDoneClassifying.listen((_) {
      _maybeFinishDeclareController();
      _maybeFinishApplyController();
    });

    _run();
  }

  /// Adds [input] as a primary input for this node.
  void addPrimary(AssetNode input) {
    _primaries.add(input);
    if (_forced) input.force();

    _primarySubscriptions[input.id] = input.onStateChange
        .listen((_) => _onPrimaryStateChange(input));

    if (_state == _State.DECLARING && !_declareController.isDone) {
      // If we're running `declareOutputs` and its id stream isn't closed yet,
      // pass this in as another id.
      _declareController.addId(input.id);
      _maybeFinishDeclareController();
    } else if (_state == _State.APPLYING) {
      // If we're running `apply`, we need to wait until [input] is available
      // before we pass it into the stream. If it's available now, great; if
      // not, [_onPrimaryStateChange] will handle it.
      if (!input.state.isAvailable) {
        // If we started running eagerly without being forced, abort that run if
        // a new unavailable asset comes in.
        if (input.isLazy && !_forced) _restartRun();
        return;
      }

      _onPrimaryStateChange(input);
      _maybeFinishApplyController();
    } else {
      // Otherwise, a new input means we'll need to re-run `declareOutputs`.
      _restartRun();
    }
  }

  /// Marks this transform as removed.
  ///
  /// This causes all of the transform's outputs to be marked as removed as
  /// well. Normally this will be automatically done internally based on events
  /// from the primary input, but it's possible for a transform to no longer be
  /// valid even if its primary input still exists.
  void remove() {
    _streams.close();
    _phaseAssetSubscription.cancel();
    _phaseStatusSubscription.cancel();
    if (_declareController != null) _declareController.cancel();
    if (_applyController != null) _applyController.cancel();
    _clearSecondarySubscriptions();
    _clearOutputs();

    for (var subscription in _primarySubscriptions.values) {
      subscription.cancel();
    }
    _primarySubscriptions.clear();

    for (var controller in _passThroughControllers.values) {
      controller.setRemoved();
    }
    _passThroughControllers.clear();
  }

  /// If [this] is deferred, ensures that its concrete outputs will be
  /// generated.
  void force() {
    if (_forced || _state == _State.APPLIED) return;
    for (var input in _primaries) {
      input.force();
    }

    _forced = true;
    if (_state == _State.DECLARED) _apply();
  }

  /// Marks this transform as dirty.
  ///
  /// Specifically, this should be called when one of the transform's inputs'
  /// contents change, or when a secondary input is removed. Primary inputs
  /// being added or removed are handled by [addInput] and
  /// [_onPrimaryStateChange].
  void _dirty() {
    if (_state == _State.DECLARING || _state == _State.NEEDS_DECLARE ||
        _state == _State.NEEDS_APPLY) {
      // If we already know that [_apply] needs to be run, there's nothing to do
      // here.
      return;
    }

    if (!_forced && !_canRunDeclaringEagerly) {
      // [forced] should only ever be false for a declaring transformer.
      assert(_declaring);

      // If we've finished applying, transition to DECLARED, indicating that we
      // know what outputs [apply] will emit but we're waiting to emit them
      // concretely until [force] is called. If we're still applying, we'll
      // transition to DECLARED once we finish.
      if (_state == _State.APPLIED) _state = _State.DECLARED;
      for (var controller in _outputControllers.values) {
        controller.setLazy(force);
      }
      _emitDeclaredOutputs();
      return;
    }

    if (_state == _State.APPLIED) {
      if (_declaredOutputs != null) _emitDeclaredOutputs();
      _apply();
    } else if (_state == _State.DECLARED) {
      _apply();
    } else {
      _state = _State.NEEDS_APPLY;
    }
  }

  /// The callback called when [input]'s state changes.
  void _onPrimaryStateChange(AssetNode input) {
    if (input.state.isRemoved) {
      _primarySubscriptions.remove(input.id);

      if (_primaries.isEmpty) {
        // If there are no more primary inputs, there's no more use for this
        // node in the graph. It will be re-created by its
        // [TransformerClassifier] if a new input with [key] is added.
        remove();
        return;
      }

      // Any change to the number of primary inputs requires that we re-run the
      // transformation.
      _restartRun();
    } else if (input.state.isAvailable) {
      if (_state == _State.DECLARED && _canRunDeclaringEagerly) {
        // If [this] is fully declared but hasn't started applying, this input
        // becoming available may mean that all inputs are available, in which
        // case we can run apply eagerly.
        _apply();
        return;
      }

      // If we're not actively passing concrete assets to the transformer, the
      // distinction between a dirty asset and an available one isn't relevant.
      if (_state != _State.APPLYING) return;

      if (_applyController.isDone) {
        // If we get a new asset after we've closed the asset stream, we need to
        // re-run declare and then apply.
        _restartRun();
      } else {
        // If the new asset comes before the asset stream is done, we can just
        // pass it to the stream.
        _applyController.addInput(input.asset);
        _maybeFinishApplyController();
      }
    } else {
      if (_forced) input.force();
      if (_state == _State.APPLYING && !_applyController.addedId(input.id) &&
          (_forced || !input.isLazy)) {
        // If the input hasn't yet been added to the transform's input stream,
        // there's no need to consider the transformation dirty. However, if the
        // input is lazy and we're running eagerly, we need to restart the
        // transformation.
        return;
      }
      _dirty();
    }
  }

  /// Run the entire transformation, including both `declareOutputs` (if
  /// applicable) and `apply`.
  void _run() {
    assert(_state != _State.DECLARING);
    assert(_state != _State.APPLYING);

    _markOutputsDirty();
    _declareOutputs(() {
      if (_forced || _canRunDeclaringEagerly) {
        _apply();
      } else {
        _state = _State.DECLARED;
        _streams.changeStatus(NodeStatus.IDLE);
      }
    });
  }

  /// Restart the entire transformation, including `declareOutputs` if
  /// applicable.
  void _restartRun() {
    if (_state == _State.DECLARED || _state == _State.APPLIED) {
      // If we're currently idle, we can restart the transformation immediately.
      _run();
      return;
    }

    // If we're actively running `declareOutputs` or `apply`, cancel the
    // transforms and transition to `NEEDS_DECLARE`. Once the transformer's
    // method returns, we'll transition to `DECLARING`.
    if (_declareController != null) _declareController.cancel();
    if (_applyController != null) _applyController.cancel();
    _state = _State.NEEDS_DECLARE;
  }

  /// Runs [transform.declareOutputs] and emits the resulting assets as dirty
  /// assets.
  ///
  /// Calls [callback] when it's finished. This doesn't return a future so that
  /// [callback] is called synchronously if there are no outputs to declare. If
  /// [this] is removed while inputs are being declared, [callback] will not be
  /// called.
  void _declareOutputs(void callback()) {
    if (transformer is! DeclaringAggregateTransformer) {
      callback();
      return;
    }

    _state = _State.DECLARING;
    var controller = new DeclaringAggregateTransformController(this);
    _declareController = controller;
    _streams.onLogPool.add(controller.onLog);
    for (var primary in _primaries) {
      controller.addId(primary.id);
    }
    _maybeFinishDeclareController();

    syncFuture(() {
      return (transformer as DeclaringAggregateTransformer)
          .declareOutputs(controller.transform);
    }).whenComplete(() {
      // Cancel the controller here even if `declareOutputs` wasn't interrupted.
      // Since the declaration is finished, we want to close out the
      // controller's streams.
      controller.cancel();
      _declareController = null;
    }).then((_) {
      if (_isRemoved) return;
      if (_state == _State.NEEDS_DECLARE) {
        _declareOutputs(callback);
        return;
      }

      if (controller.loggedError) {
        // If `declareOutputs` fails, fall back to treating a declaring
        // transformer as though it were eager.
        if (transformer is! LazyAggregateTransformer) _forced = true;
        callback();
        return;
      }

      _consumedPrimaries = controller.consumedPrimaries;
      _declaredOutputs = controller.outputIds;
      var invalidIds = _declaredOutputs
          .where((id) => id.package != phase.cascade.package).toSet();
      for (var id in invalidIds) {
        _declaredOutputs.remove(id);
        // TODO(nweiz): report this as a warning rather than a failing error.
        phase.cascade.reportError(new InvalidOutputException(info, id));
      }

      for (var primary in _primaries) {
        if (_declaredOutputs.contains(primary.id)) continue;
        _passThrough(primary.id);
      }
      _emitDeclaredOutputs();
      callback();
    }).catchError((error, stackTrace) {
      if (_isRemoved) return;
      if (transformer is! LazyAggregateTransformer) _forced = true;
      phase.cascade.reportError(_wrapException(error, stackTrace));
      callback();
    });
  }

  /// Emits a dirty asset node for all outputs that were declared by the
  /// transformer.
  ///
  /// This won't emit any outputs for which there already exist output
  /// controllers. It should only be called for transforms that have declared
  /// their outputs.
  void _emitDeclaredOutputs() {
    assert(_declaredOutputs != null);
    for (var id in _declaredOutputs) {
      if (_outputControllers.containsKey(id)) continue;
      var controller = _forced
          ? new AssetNodeController(id, this)
          : new AssetNodeController.lazy(id, force, this);
      _outputControllers[id] = controller;
      _streams.onAssetController.add(controller.node);
    }
  }

  //// Mark all emitted and passed-through outputs of this transform as dirty.
  void _markOutputsDirty() {
    for (var controller in _passThroughControllers.values) {
      controller.setDirty();
    }
    for (var controller in _outputControllers.values) {
      if (_forced) {
        controller.setDirty();
      } else {
        controller.setLazy(force);
      }
    }
  }

  /// Applies this transform.
  void _apply() {
    assert(!_isRemoved);

    _markOutputsDirty();
    _clearSecondarySubscriptions();
    _state = _State.APPLYING;
    _streams.changeStatus(status);
    _runApply().then((hadError) {
      if (_isRemoved) return;

      if (_state == _State.DECLARED) return;

      if (_state == _State.NEEDS_DECLARE) {
        _run();
        return;
      }

      // If an input's contents changed while running `apply`, retry unless the
      // transformer is deferred and hasn't been forced.
      if (_state == _State.NEEDS_APPLY) {
        if (_forced || _canRunDeclaringEagerly) {
          _apply();
        } else {
          _state = _State.DECLARED;
        }
        return;
      }

      if (_declaring) _forced = false;

      assert(_state == _State.APPLYING);
      if (hadError) {
        _clearOutputs();
        // If the transformer threw an error, we don't want to emit the
        // pass-through assets in case they'll be overwritten by the
        // transformer. However, if the transformer declared that it wouldn't
        // overwrite or consume a pass-through asset, we can safely emit it.
        if (_declaredOutputs != null) {
          for (var input in _primaries) {
            if (_consumedPrimaries.contains(input.id) ||
                _declaredOutputs.contains(input.id)) {
              _consumePrimary(input.id);
            } else {
              _passThrough(input.id);
            }
          }
        }
      }

      _state = _State.APPLIED;
      _streams.changeStatus(NodeStatus.IDLE);
    });
  }

  /// Gets the asset for an input [id].
  ///
  /// If an input with [id] cannot be found, throws an [AssetNotFoundException].
  Future<Asset> getInput(AssetId id) {
    _timeAwaitingInputs.start();
    _pendingSecondaryInputs++;
    return phase.previous.getOutput(id).then((node) {
      // Throw if the input isn't found. This ensures the transformer's apply
      // is exited. We'll then catch this and report it through the proper
      // results stream.
      if (node == null) {
        _missingInputs.add(id);
        throw new AssetNotFoundException(id);
      }

      _secondarySubscriptions.putIfAbsent(node.id, () {
        return node.onStateChange.listen((_) => _dirty());
      });

      return node.asset;
    }).whenComplete(() {
      _pendingSecondaryInputs--;
      if (_pendingSecondaryInputs != 0) _timeAwaitingInputs.stop();
    });
  }

  /// Run [AggregateTransformer.apply].
  ///
  /// Returns whether or not an error occurred while running the transformer.
  Future<bool> _runApply() {
    var controller = new AggregateTransformController(this);
    _applyController = controller;
    _streams.onLogPool.add(controller.onLog);
    for (var primary in _primaries) {
      if (!primary.state.isAvailable) continue;
      controller.addInput(primary.asset);
    }
    _maybeFinishApplyController();

    return syncFuture(() {
      _timeInTransformer.reset();
      _timeAwaitingInputs.reset();
      _timeInTransformer.start();
      return transformer.apply(controller.transform);
    }).whenComplete(() {
      _timeInTransformer.stop();
      _timeAwaitingInputs.stop();

      // Cancel the controller here even if `apply` wasn't interrupted. Since
      // the apply is finished, we want to close out the controller's streams.
      controller.cancel();
      _applyController = null;
    }).then((_) {
      assert(_state != _State.DECLARED);
      assert(_state != _State.DECLARING);
      assert(_state != _State.APPLIED);

      if (!_forced && _primaries.any((node) => !node.state.isAvailable)) {
        _state = _State.DECLARED;
        _streams.changeStatus(NodeStatus.IDLE);
        return false;
      }

      if (_isRemoved) return false;
      if (_state == _State.NEEDS_APPLY) return false;
      if (_state == _State.NEEDS_DECLARE) return false;
      if (controller.loggedError) return true;

      // If the transformer took long enough, log its duration in fine output.
      // That way it's not always visible, but users running with "pub serve
      // --verbose" can see it.
      if (_timeInTransformer.elapsed > new Duration(seconds: 1) ||
          (_timeInTransformer.elapsed - _timeAwaitingInputs.elapsed >
              new Duration(milliseconds: 200))) {
        _streams.onLogController.add(new LogEntry(
            info, info.primaryId, LogLevel.FINE,
            "Took ${niceDuration(_timeInTransformer.elapsed)} "
              "(${niceDuration(_timeAwaitingInputs.elapsed)} awaiting "
              "secondary inputs).",
            null));
      }

      _handleApplyResults(controller);
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
  /// [controller] should be the controller for the [AggegateTransform] passed
  /// to [AggregateTransformer.apply].
  void _handleApplyResults(AggregateTransformController controller) {
    _consumedPrimaries = controller.consumedPrimaries;

    var newOutputs = controller.outputs;
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

    // Emit or stop emitting pass-through assets between removing and adding
    // outputs to ensure there are no collisions.
    for (var id in _primaries.map((node) => node.id)) {
      if (_consumedPrimaries.contains(id) || newOutputs.containsId(id)) {
        _consumePrimary(id);
      } else {
        _passThrough(id);
      }
    }

    // Store any new outputs or new contents for existing outputs.
    for (var asset in newOutputs) {
      var controller = _outputControllers[asset.id];
      if (controller != null) {
        controller.setAvailable(asset);
      } else {
        var controller = new AssetNodeController.available(asset, this);
        _outputControllers[asset.id] = controller;
        _streams.onAssetController.add(controller.node);
      }
    }
  }

  /// Cancels all subscriptions to secondary input nodes.
  void _clearSecondarySubscriptions() {
    _missingInputs.clear();
    for (var subscription in _secondarySubscriptions.values) {
      subscription.cancel();
    }
    _secondarySubscriptions.clear();
  }

  /// Removes all output assets.
  void _clearOutputs() {
    // Remove all the previously-emitted assets.
    for (var controller in _outputControllers.values) {
      controller.setRemoved();
    }
    _outputControllers.clear();
  }

  /// Emit the pass-through node for the primary input [id] if it's not being
  /// emitted already.
  void _passThrough(AssetId id) {
    assert(!_outputControllers.containsKey(id));

    if (_consumedPrimaries.contains(id)) return;
    var controller = _passThroughControllers[id];
    var primary = _primaries[id];
    if (controller == null) {
      controller = new AssetNodeController.from(primary);
      _passThroughControllers[id] = controller;
      _streams.onAssetController.add(controller.node);
    } else if (primary.state.isDirty) {
      controller.setDirty();
    } else if (!controller.node.state.isAvailable) {
      controller.setAvailable(primary.asset);
    }
  }

  /// Stops emitting the pass-through node for the primary input [id] if it's
  /// being emitted.
  void _consumePrimary(AssetId id) {
    var controller = _passThroughControllers.remove(id);
    if (controller == null) return;
    controller.setRemoved();
  }

  /// If `declareOutputs` is running and all previous phases have declared their
  /// outputs, mark [_declareController] as done.
  void _maybeFinishDeclareController() {
    if (_declareController == null) return;
    if (classifier.isClassifying) return;
    if (phase.previous.status == NodeStatus.RUNNING) return;
    _declareController.done();
  }

  /// If `apply` is running, all previous phases have declared their outputs,
  /// and all primary inputs are available and thus have been passed to the
  /// transformer, mark [_applyController] as done.
  void _maybeFinishApplyController() {
    if (_applyController == null) return;
    if (classifier.isClassifying) return;
    if (_primaries.any((input) => !input.state.isAvailable)) return;
    if (phase.previous.status == NodeStatus.RUNNING) return;
    _applyController.done();
  }

  BarbackException _wrapException(error, StackTrace stackTrace) {
    if (error is! AssetNotFoundException) {
      return new TransformerException(info, error, stackTrace);
    } else {
      return new MissingInputException(info, error.id);
    }
  }

  String toString() =>
      "transform node in $_location for $transformer on ${info.primaryId} "
      "($_state, $status, ${_forced ? '' : 'un'}forced)";
}

/// The enum of states that [TransformNode] can be in.
class _State {
  /// The transform is running [DeclaringAggregateTransformer.declareOutputs].
  ///
  /// If the set of primary inputs changes while in this state, it will
  /// transition to [NEEDS_DECLARE]. If the [TransformNode] is still in this
  /// state when `declareOutputs` finishes running, it will transition to
  /// [APPLYING] if the transform is non-lazy and all of its primary inputs are
  /// available, and [DECLARED] otherwise.
  ///
  /// Non-declaring transformers will transition out of this state and into
  /// [APPLYING] immediately.
  static const DECLARING = const _State._("declaring outputs");

  /// The transform is running [AggregateTransformer.declareOutputs] or
  /// [AggregateTransform.apply], but a primary input was added or removed after
  /// it started, so it will need to re-run `declareOutputs`.
  ///
  /// The [TransformNode] will transition to [DECLARING] once `declareOutputs`
  /// or `apply` finishes running.
  static const NEEDS_DECLARE = const _State._("needs declare");

  /// The transform is deferred and has run
  /// [DeclaringAggregateTransformer.declareOutputs] but hasn't yet been forced.
  ///
  /// The [TransformNode] will transition to [APPLYING] when one of the outputs
  /// has been forced or if the transformer is non-lazy and all of its primary
  /// inputs become available.
  static const DECLARED = const _State._("declared");

  /// The transform is running [AggregateTransformer.apply].
  ///
  /// If an input's contents change or a secondary input is added or removed
  /// while in this state, the [TransformNode] will transition to [NEEDS_APPLY].
  /// If a primary input is added or removed, it will transition to
  /// [NEEDS_DECLARE]. If it's still in this state when `apply` finishes
  /// running, it will transition to [APPLIED].
  static const APPLYING = const _State._("applying");

  /// The transform is running [AggregateTransformer.apply], but an input's
  /// contents changed or a secondary input was added or removed after it
  /// started, so it will need to re-run `apply`.
  ///
  /// If a primary input is added or removed while in this state, the
  /// [TranformNode] will transition to [NEEDS_DECLARE]. If it's still in this
  /// state when `apply` finishes running, it will transition to [APPLYING].
  static const NEEDS_APPLY = const _State._("needs apply");

  /// The transform has finished running [AggregateTransformer.apply], whether
  /// or not it emitted an error.
  ///
  /// If an input's contents change or a secondary input is added or removed,
  /// the [TransformNode] will transition to [DECLARED] if the transform is
  /// declaring and [APPLYING] otherwise. If a primary input is added or
  /// removed, this will transition to [DECLARING].
  static const APPLIED = const _State._("applied");

  final String name;

  const _State._(this.name);

  String toString() => name;
}
