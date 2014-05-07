// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.graph.transform_node;

import 'dart:async';

import '../asset/asset.dart';
import '../asset/asset_id.dart';
import '../asset/asset_node.dart';
import '../errors.dart';
import '../log.dart';
import '../transformer/aggregate_transform.dart';
import '../transformer/declaring_aggregate_transform.dart';
import '../transformer/declaring_transform.dart';
import '../transformer/declaring_transformer.dart';
import '../transformer/lazy_transformer.dart';
import '../transformer/transform.dart';
import '../transformer/transformer.dart';
import 'node_status.dart';
import 'node_streams.dart';
import 'phase.dart';

/// Describes a transform on a set of assets and its relationship to the build
/// dependency graph.
///
/// Keeps track of whether it's dirty and needs to be run and which assets it
/// depends on.
class TransformNode {
  /// The aggregate key for this node.
  final String key;

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

  /// How far along [this] is in processing its assets.
  NodeStatus get status {
    if (_state == _State.APPLIED || _state == _State.DECLARED) {
      return NodeStatus.IDLE;
    }

    if (_declaring && _state != _State.DECLARING) {
      return NodeStatus.MATERIALIZING;
    } else {
      return NodeStatus.RUNNING;
    }
  }

  /// Whether this is a declaring transform.
  ///
  /// This is usually identical to `transformer is DeclaringTransformer`, but if
  /// a declaring and non-lazy transformer emits an error during
  /// `declareOutputs` it's treated as though it wasn't declaring.
  bool get _declaring => transformer is DeclaringTransformer &&
      (_state == _State.DECLARING || _declaredOutputs != null);

  /// Whether this transform has been forced since it last finished applying.
  ///
  /// A transform being forced means it should run until it generates outputs
  /// and is no longer dirty. This is always true for non-declaring
  /// transformers, since they always need to eagerly generate outputs.
  bool _forced;

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

  /// The asset node for this transform.
  final _streams = new NodeStreams();
  Stream<NodeStatus> get onStatusChange => _streams.onStatusChange;
  Stream<AssetNode> get onAsset => _streams.onAsset;
  Stream<LogEntry> get onLog => _streams.onLog;

  /// The current state of [this].
  var _state = _State.DECLARING;

  /// Whether [this] has been marked as removed.
  bool get _isRemoved => _streams.onAssetController.isClosed;

  // If [transformer] is declaring but not lazy and [primary] is available, we
  // can run [apply] even if [force] hasn't been called, since [transformer]
  // should run eagerly if possible.
  bool get _canRunDeclaringEagerly =>
      _declaring && transformer is! LazyTransformer &&
      primary.state.isAvailable;

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
      : key = primary.id.path,
        transformer = transformer,
        primary = primary {
    _forced = transformer is! DeclaringTransformer;
    if (_forced) primary.force();

    _primarySubscription = primary.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        if (_forced) primary.force();
        _dirty();
      }
    });

    _phaseSubscription = phase.previous.onAsset.listen((node) {
      if (!_missingInputs.contains(node.id)) return;
      if (_forced) node.force();
      _dirty();
    });

    _declareOutputs().then((_) {
      if (_forced || _canRunDeclaringEagerly) {
        _apply();
      } else {
        _state = _State.DECLARED;
        _streams.changeStatus(NodeStatus.IDLE);
      }
    });
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
    _streams.close();
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
    if (_forced || _state == _State.APPLIED) return;
    primary.force();
    _forced = true;
    if (_state == _State.DECLARED) _dirty();
  }

  /// Marks this transform as dirty.
  ///
  /// This causes all of the transform's outputs to be marked as dirty as well.
  void _dirty() {
    // If we're in the process of running [declareOutputs], we already know that
    // [apply] needs to be run so there's nothing we need to mark as dirty.
    if (_state == _State.DECLARING) return;

    if (!_forced && !_canRunDeclaringEagerly) {
      // [forced] should only ever be false for a declaring transformer.
      assert(_declaring);

      // If we've finished applying, transition to MATERIALIZING, indicating
      // that we know what outputs [apply] will emit but we're waiting to emit
      // them concretely until [force] is called. If we're still applying, we'll
      // transition to MATERIALIZING once we finish.
      if (_state == _State.APPLIED) _state = _State.DECLARED;
      for (var controller in _outputControllers.values) {
        controller.setLazy(force);
      }
      _emitDeclaredOutputs();
      return;
    }

    if (_passThroughController != null) _passThroughController.setDirty();
    for (var controller in _outputControllers.values) {
      controller.setDirty();
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

  /// Runs [transform.declareOutputs] and emits the resulting assets as dirty
  /// assets.
  Future _declareOutputs() {
    if (transformer is! DeclaringTransformer) return new Future.value();

    var controller = new DeclaringAggregateTransformController(this);
    _streams.onLogPool.add(controller.onLog);
    controller.idController.add(primary.id);
    return newDeclaringTransform(controller.transform).then((transform) {
      return (transformer as DeclaringTransformer).declareOutputs(transform);
    }).then((_) {
      if (_isRemoved) return;
      if (controller.loggedError) return;

      _consumePrimary = controller.consumedPrimaries.contains(primary.id);
      _declaredOutputs = controller.outputIds;
      var invalidIds = _declaredOutputs
          .where((id) => id.package != phase.cascade.package).toSet();
      for (var id in invalidIds) {
        _declaredOutputs.remove(id);
        // TODO(nweiz): report this as a warning rather than a failing error.
        phase.cascade.reportError(new InvalidOutputException(info, id));
      }

      if (!_declaredOutputs.contains(primary.id)) _emitPassThrough();
      _emitDeclaredOutputs();
    }).catchError((error, stackTrace) {
      if (_isRemoved) return;
      if (transformer is! LazyTransformer) _forced = true;
      phase.cascade.reportError(_wrapException(error, stackTrace));
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

  /// Applies this transform.
  void _apply() {
    assert(!_isRemoved);

    // Clear input subscriptions here as well as in [_process] because [_apply]
    // may be restarted independently if only a secondary input changes.
    _clearInputSubscriptions();
    _state = _State.APPLYING;
    _streams.changeStatus(status);
    _runApply().then((hadError) {
      if (_isRemoved) return;

      if (_state == _State.DECLARED) return;

      if (_state == _State.NEEDS_APPLY) {
        _apply();
        return;
      }

      if (_declaring) _forced = false;

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
      _streams.changeStatus(NodeStatus.IDLE);
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
    var controller = new AggregateTransformController(this);
    _streams.onLogPool.add(controller.onLog);

    return primary.whenAvailable((_) {
      if (_isRemoved) return null;
      _state = _State.APPLYING;
      controller.inputController.add(primary.asset);
      return newTransform(controller.transform).then((transform) {
        return transformer.apply(transform);
      });
    }).then((_) {
      if (!_forced && !primary.state.isAvailable) {
        _state = _State.DECLARED;
        _streams.changeStatus(NodeStatus.IDLE);
        return false;
      }

      if (_isRemoved) return false;
      if (_state == _State.NEEDS_APPLY) return false;
      if (_state == _State.DECLARING) return false;
      if (controller.loggedError) return true;
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
    _consumePrimary = controller.consumedPrimaries.contains(primary.id);

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
        _streams.onAssetController.add(controller.node);
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
      _streams.onAssetController.add(_passThroughController.node);
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
    _streams.onLogController.add(
        new LogEntry(info, primary.id, LogLevel.WARNING, message, null));
  }

  String toString() =>
      "transform node in $_location for $transformer on $primary ($_state, "
      "$status, ${_forced ? '' : 'un'}forced)";
}

/// The enum of states that [TransformNode] can be in.
class _State {
  /// The transform is running [DeclaringTransformer.declareOutputs].
  ///
  /// This is the initial state of the transformer, and it will only occur once
  /// since [DeclaringTransformer.declareOutputs] is independent of the contents
  /// of the primary input. Once the method finishes running, this will
  /// transition to [APPLYING] if the transform is non-lazy and the input is
  /// available, and [DECLARED] otherwise.
  ///
  /// Non-declaring transformers will transition out of this state and into
  /// [APPLYING] immediately.
  static final DECLARING = const _State._("declaring outputs");

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

  final String name;

  const _State._(this.name);

  String toString() => name;
}
