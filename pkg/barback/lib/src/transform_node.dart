// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform_node;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
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

  // TODO(nweiz): Remove this and move isPrimary computation into TransformNode.
  /// Whether the parent [PhaseInput] is currently computing whether its input
  /// is primary for [this].
  bool _pendingIsPrimary = false;

  /// Whether [this] is dirty and still has more processing to do.
  bool get isDirty => _pendingIsPrimary || _isApplying;

  /// Whether any input has become dirty since [_apply] last started running.
  var _hasBecomeDirty = false;

  /// Whether [_apply] is currently running.
  var _isApplying = false;

  /// Whether [transformer] is lazy and this transform has yet to be forced.
  bool _isLazy;

  /// The subscriptions to each input's [AssetNode.onStateChange] stream.
  var _inputSubscriptions = new Map<AssetId, StreamSubscription>();

  /// The controllers for the asset nodes emitted by this node.
  var _outputControllers = new Map<AssetId, AssetNodeController>();

  // TODO(nweiz): It's weird that this is different than the [onDone] stream the
  // other nodes emit. See if we can make that more consistent.
  /// A stream that emits an event whenever [onDirty] changes its value.
  ///
  /// This is synchronous in order to guarantee that it will emit an event as
  /// soon as [isDirty] changes. It's possible for this to emit multiple events
  /// while [isDirty] is `true`. However, it will only emit a single event each
  /// time [isDirty] becomes `false`.
  Stream get onStateChange => _onStateChangeController.stream;
  final _onStateChangeController = new StreamController.broadcast(sync: true);

  /// A stream that emits any new assets emitted by [this].
  ///
  /// Assets are emitted synchronously to ensure that any changes are thoroughly
  /// propagated as soon as they occur.
  Stream<AssetNode> get onAsset => _onAssetController.stream;
  final _onAssetController = new StreamController<AssetNode>(sync: true);

  /// A stream that emits an event whenever this transform logs an entry.
  ///
  /// This is synchronous because error logs can cause the transform to fail, so
  /// we need to ensure that their processing isn't delayed until after the
  /// transform or build has finished.
  Stream<LogEntry> get onLog => _onLogPool.stream;
  final _onLogPool = new StreamPool<LogEntry>.broadcast();

  TransformNode(this.phase, Transformer transformer, this.primary,
      this._location)
      : transformer = transformer,
        _isLazy = transformer is LazyTransformer {
    _primarySubscription = primary.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        if (state.isDirty) _pendingIsPrimary = true;
        _dirty();
      }
    });

    _apply();
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
    _hasBecomeDirty = false;
    _onAssetController.close();
    _onStateChangeController.close();
    _primarySubscription.cancel();
    for (var subscription in _inputSubscriptions.values) {
      subscription.cancel();
    }
    for (var controller in _outputControllers.values) {
      controller.setRemoved();
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

  // TODO(nweiz): remove this and move isPrimary computation into TransformNode.
  /// Mark that the parent [PhaseInput] has determined that its input is indeed
  /// primary for [this].
  void markPrimary() {
    if (!_pendingIsPrimary) return;
    _pendingIsPrimary = false;
    if (!_isApplying) _apply();
  }

  /// Marks this transform as dirty.
  ///
  /// This causes all of the transform's outputs to be marked as dirty as well.
  void _dirty() {
    for (var controller in _outputControllers.values) {
      controller.setDirty();
    }

    _hasBecomeDirty = true;
    _onStateChangeController.add(null);
    if (!_isApplying && !_pendingIsPrimary) _apply();
  }

  /// Applies this transform.
  void _apply() {
    assert(!_onAssetController.isClosed);

    // Clear all the old input subscriptions. If an input is re-used, we'll
    // re-subscribe.
    for (var subscription in _inputSubscriptions.values) {
      subscription.cancel();
    }
    _inputSubscriptions.clear();

    _isApplying = true;
    _onStateChangeController.add(null);
    primary.whenAvailable((_) {
      _hasBecomeDirty = false;

      // TODO(nweiz): If [transformer] is a [DeclaringTransformer] but not a
      // [LazyTransformer], we can get some mileage out of doing a declarative
      // first so we know how to hook up the assets.
      if (_isLazy) return _declareLazy();
      return _applyImmediate();
    }).catchError((error, stackTrace) {
      // If the transform became dirty while processing, ignore any errors from
      // it.
      if (_hasBecomeDirty || _onAssetController.isClosed) return;

      if (error is! MissingInputException) {
        error = new TransformerException(info, error, stackTrace);
      }

      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      phase.cascade.reportError(error);

      // Remove all the previously-emitted assets.
      for (var controller in _outputControllers.values) {
        controller.setRemoved();
      }
      _outputControllers.clear();
    }).then((_) {
      if (_onAssetController.isClosed) return;

      _isApplying = false;
      if (_hasBecomeDirty) {
        // Re-apply the transform if it became dirty while applying.
        if (!_pendingIsPrimary) _apply();
      } else {
        assert(!isDirty);
        // Otherwise, notify the parent nodes that it's no longer dirty.
        _onStateChangeController.add(null);
      }
    });
  }

  /// Gets the asset for an input [id].
  ///
  /// If an input with that ID cannot be found, throws an
  /// [AssetNotFoundException].
  Future<Asset> getInput(AssetId id) {
    return phase.getInput(id).then((node) {
      // Throw if the input isn't found. This ensures the transformer's apply
      // is exited. We'll then catch this and report it through the proper
      // results stream.
      if (node == null) throw new MissingInputException(info, id);

      _inputSubscriptions.putIfAbsent(node.id,
          () => node.onStateChange.listen((_) => _dirty()));

      return node.asset;
    });
  }

  /// Applies the transform so that it produces concrete (as opposed to lazy)
  /// outputs.
  Future _applyImmediate() {
    var transformController = new TransformController(this);
    _onLogPool.add(transformController.onLog);

    return syncFuture(() {
      return transformer.apply(transformController.transform);
    }).then((_) {
      if (_hasBecomeDirty || _onAssetController.isClosed) return;

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
    });
  }

  /// Applies the transform in declarative mode so that it produces lazy
  /// outputs.
  Future _declareLazy() {
    var transformController = new DeclaringTransformController(this);

    return syncFuture(() {
      return (transformer as LazyTransformer)
          .declareOutputs(transformController.transform);
    }).then((_) {
      if (_hasBecomeDirty || _onAssetController.isClosed) return;

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
    });
  }

  String toString() =>
    "transform node in $_location for $transformer on $primary";
}
