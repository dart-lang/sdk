// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.transform_node;

import 'dart:async';

import 'package:source_maps/span.dart';

import 'asset.dart';
import 'asset_id.dart';
import 'asset_node.dart';
import 'asset_set.dart';
import 'declaring_transform.dart';
import 'errors.dart';
import 'lazy_transformer.dart';
import 'log.dart';
import 'phase.dart';
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

  /// True if an input has been modified since the last time this transform
  /// began running.
  bool get isDirty => _isDirty;
  var _isDirty = true;

  /// Whether [transformer] is lazy and this transform has yet to be forced.
  bool _isLazy;

  /// The subscriptions to each input's [AssetNode.onStateChange] stream.
  var _inputSubscriptions = new Map<AssetId, StreamSubscription>();

  /// The controllers for the asset nodes emitted by this node.
  var _outputControllers = new Map<AssetId, AssetNodeController>();

  /// A stream that emits an event whenever this transform becomes dirty and
  /// needs to be re-run.
  ///
  /// This may emit events when the transform was already dirty or while
  /// processing transforms. Events are emitted synchronously to ensure that the
  /// dirty state is thoroughly propagated as soon as any assets are changed.
  Stream get onDirty => _onDirtyController.stream;
  final _onDirtyController = new StreamController.broadcast(sync: true);

  /// A stream that emits an event whenever this transform logs an entry.
  ///
  /// This is synchronous because error logs can cause the transform to fail, so
  /// we need to ensure that their processing isn't delayed until after the
  /// transform or build has finished.
  Stream<LogEntry> get onLog => _onLogController.stream;
  final _onLogController = new StreamController<LogEntry>.broadcast(sync: true);

  TransformNode(this.phase, Transformer transformer, this.primary,
      this._location)
      : transformer = transformer,
        _isLazy = transformer is LazyTransformer {
    _primarySubscription = primary.onStateChange.listen((state) {
      if (state.isRemoved) {
        remove();
      } else {
        _dirty();
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
    _isDirty = true;
    _onDirtyController.close();
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

  /// Marks this transform as dirty.
  ///
  /// This causes all of the transform's outputs to be marked as dirty as well.
  void _dirty() {
    _isDirty = true;
    for (var controller in _outputControllers.values) {
      controller.setDirty();
    }
    _onDirtyController.add(null);
  }

  /// Applies this transform.
  ///
  /// Returns a set of asset nodes representing the outputs from this transform
  /// that weren't emitted last time it was run.
  Future<Set<AssetNode>> apply() {
    assert(!_onDirtyController.isClosed);

    // Clear all the old input subscriptions. If an input is re-used, we'll
    // re-subscribe.
    for (var subscription in _inputSubscriptions.values) {
      subscription.cancel();
    }
    _inputSubscriptions.clear();

    _isDirty = false;

    return syncFuture(() {
      // TODO(nweiz): If [transformer] is a [DeclaringTransformer] but not a
      // [LazyTransformer], we can get some mileage out of doing a declarative
      // first so we know how to hook up the assets.
      if (_isLazy) return _declareLazy();
      return _applyImmediate();
    }).catchError((error, stackTrace) {
      // If the transform became dirty while processing, ignore any errors from
      // it.
      if (_isDirty) return new Set();

      if (error is! MissingInputException) {
        error = new TransformerException(info, error, stackTrace);
      }

      // Catch all transformer errors and pipe them to the results stream. This
      // is so a broken transformer doesn't take down the whole graph.
      phase.cascade.reportError(error);

      return new Set();
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

      // If the asset node is found, wait until its contents are actually
      // available before we return them.
      return node.whenAvailable((asset) {
        _inputSubscriptions.putIfAbsent(node.id,
            () => node.onStateChange.listen((_) => _dirty()));

        return asset;
      }).catchError((error) {
        if (error is! AssetNotFoundException || error.id != id) throw error;
        // If the node was removed before it could be loaded, treat it as though
        // it never existed and throw a MissingInputException.
        throw new MissingInputException(info, id);
      });
    });
  }

  /// Applies the transform so that it produces concrete (as opposed to lazy)
  /// outputs.
  Future<Set<AssetNode>> _applyImmediate() {
    var newOutputs = new AssetSet();
    var transform = new Transform(this, newOutputs, _log);

    return syncFuture(() => transformer.apply(transform)).then((_) {
      if (_isDirty) return new Set();

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

      var brandNewOutputs = new Set<AssetNode>();
      // Store any new outputs or new contents for existing outputs.
      for (var asset in newOutputs) {
        var controller = _outputControllers[asset.id];
        if (controller != null) {
          controller.setAvailable(asset);
        } else {
          var controller = new AssetNodeController.available(asset, this);
          _outputControllers[asset.id] = controller;
          brandNewOutputs.add(controller.node);
        }
      }

      return brandNewOutputs;
    });
  }

  /// Applies the transform in declarative mode so that it produces lazy
  /// outputs.
  Future<Set<AssetNode>> _declareLazy() {
    var newIds = new Set();
    var transform = new DeclaringTransform(this, newIds, _log);

    return syncFuture(() {
      return (transformer as LazyTransformer).declareOutputs(transform);
    }).then((_) {
      if (_isDirty) return new Set();

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

      var brandNewOutputs = new Set<AssetNode>();
      for (var id in newIds) {
        var controller = _outputControllers[id];
        if (controller != null) {
          controller.setLazy(force);
        } else {
          var controller = new AssetNodeController.lazy(id, force, this);
          _outputControllers[id] = controller;
          brandNewOutputs.add(controller.node);
        }
      }

      return brandNewOutputs;
    });
  }

  void _log(AssetId asset, LogLevel level, String message, Span span) {
    // If the log isn't already associated with an asset, use the primary.
    if (asset == null) asset = primary.id;
    var entry = new LogEntry(info, asset, level, message, span);
    _onLogController.add(entry);
  }

  String toString() =>
    "transform node in $_location for $transformer on $primary";
}
