// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.asset_node;

import 'dart:async';

import 'asset.dart';
import 'asset_id.dart';
import 'errors.dart';
import 'transform_node.dart';
import 'utils.dart';

/// Describes the current state of an asset as part of a transformation graph.
///
/// An asset node can be in one of three states (see [AssetState]). It provides
/// an [onStateChange] stream that emits an event whenever it changes state.
///
/// Asset nodes are controlled using [AssetNodeController]s.
class AssetNode {
  /// The id of the asset that this node represents.
  final AssetId id;

  /// The [AssetNode] from which [this] is forwarded.
  ///
  /// For nodes that aren't forwarded, this will return [this]. Otherwise, it
  /// will return the first node in the forwarding chain.
  ///
  /// This is used to determine whether two nodes are forwarded from the same
  /// source.
  AssetNode get origin => _origin == null ? this : _origin;
  AssetNode _origin;

  /// The transform that created this asset node.
  ///
  /// This is `null` for source assets. It can change if the upstream transform
  /// that created this asset changes; this change will *not* cause an
  /// [onStateChange] event.
  TransformNode get transform => _transform;
  TransformNode _transform;

  /// The current state of the asset node.
  AssetState get state => _state;
  AssetState _state;

  /// The concrete asset that this node represents.
  ///
  /// This is null unless [state] is [AssetState.AVAILABLE].
  Asset get asset => _asset;
  Asset _asset;

  /// The callback to be called to notify this asset node's creator that the
  /// concrete asset should be generated.
  ///
  /// This is null for non-lazy asset nodes (see [AssetNodeController.lazy]).
  /// Once this is called, it's set to null and [this] is no longer considered
  /// lazy.
  Function _lazyCallback;

  /// A broadcast stream that emits an event whenever the node changes state.
  ///
  /// This stream is synchronous to ensure that when a source asset is modified
  /// or removed, the appropriate portion of the asset graph is dirtied before
  /// any [Barback.getAssetById] calls emit newly-incorrect values.
  Stream<AssetState> get onStateChange => _stateChangeController.stream;

  /// This is synchronous so that a source being updated will always be
  /// propagated through the build graph before anything that depends on it is
  /// requested.
  final _stateChangeController =
      new StreamController<AssetState>.broadcast(sync: true);

  /// Calls [callback] when the node's asset is available.
  ///
  /// If the asset is currently available, this calls [callback] synchronously
  /// to ensure that the asset is still available.
  ///
  /// The return value of [callback] is piped to the returned Future. If the
  /// asset is removed before becoming available, the returned future will throw
  /// an [AssetNotFoundException].
  Future whenAvailable(callback(Asset asset)) {
    return _waitForState((state) => state.isAvailable || state.isRemoved,
        (state) {
      if (state.isRemoved) throw new AssetNotFoundException(id);
      return callback(asset);
    });
  }

  /// Calls [callback] when the node's asset is removed.
  ///
  /// If the asset is already removed when this is called, it calls [callback]
  /// synchronously.
  ///
  /// The return value of [callback] is piped to the returned Future.
  Future whenRemoved(callback()) =>
    _waitForState((state) => state.isRemoved, (_) => callback());

  /// Returns a [Future] that completes when [state] changes from its current
  /// value to any other value.
  ///
  /// The returned [Future] will contain the new state.
  Future<AssetState> whenStateChanges() {
    var startState = state;
    return _waitForState((state) => state != startState, (state) => state);
  }

  /// Calls [callback] as soon as the node is in a state that matches [test].
  ///
  /// [callback] is called synchronously if this is already in such a state.
  ///
  /// The return value of [callback] is piped to the returned Future.
  Future _waitForState(bool test(AssetState state),
      callback(AssetState state)) {
    if (test(state)) return syncFuture(() => callback(state));
    return onStateChange.firstWhere(test).then((_) => callback(state));
  }

  AssetNode._(this.id, this._transform, this._origin)
      : _state = AssetState.DIRTY;

  AssetNode._available(Asset asset, this._transform, this._origin)
      : id = asset.id,
        _asset = asset,
        _state = AssetState.AVAILABLE;

  AssetNode._lazy(this.id, this._transform, this._origin, this._lazyCallback)
      : _state = AssetState.DIRTY;

  /// If [this] is lazy, force it to generate a concrete asset; otherwise, do
  /// nothing.
  ///
  /// See [AssetNodeController.lazy].
  void force() {
    if (_origin != null) {
      _origin.force();
    } else if (_lazyCallback != null) {
      _lazyCallback();
      _lazyCallback = null;
    }
  }

  String toString() =>
    "$state${_lazyCallback == null ? '' : ' lazy'} asset $id";
}

/// The controller for an [AssetNode].
///
/// This controls which state the node is in.
class AssetNodeController {
  final AssetNode node;

  /// Creates a controller for a dirty node.
  AssetNodeController(AssetId id, [TransformNode transform])
      : node = new AssetNode._(id, transform, null);

  /// Creates a controller for an available node with the given concrete
  /// [asset].
  AssetNodeController.available(Asset asset, [TransformNode transform])
      : node = new AssetNode._available(asset, transform, null);

  /// Creates a controller for a lazy node.
  ///
  /// For the most part, this node works like any other dirty node. However, the
  /// owner of its controller isn't expected to do the work to make it available
  /// as soon as possible like they would for a non-lazy node. Instead, when its
  /// value is needed, [callback] will fire to indicate that it should be made
  /// available as soon as possible.
  ///
  /// [callback] is guaranteed to only fire once.
  AssetNodeController.lazy(AssetId id, void callback(),
          [TransformNode transform])
      : node = new AssetNode._lazy(id, transform, null, callback);

  /// Creates a controller for a node whose initial state matches the current
  /// state of [node].
  ///
  /// [AssetNode.origin] of the returned node will automatically be set to
  /// `node.origin`.
  ///
  /// If [node] is lazy, the returned node will also be lazy.
  AssetNodeController.from(AssetNode node)
      : node = new AssetNode._(node.id, node.transform, node.origin) {
    if (node.state.isAvailable) {
      setAvailable(node.asset);
    } else if (node.state.isRemoved) {
      setRemoved();
    }
  }

  /// Marks the node as [AssetState.DIRTY].
  void setDirty() {
    assert(node._state != AssetState.REMOVED);
    node._state = AssetState.DIRTY;
    node._asset = null;
    node._lazyCallback = null;
    node._stateChangeController.add(AssetState.DIRTY);
  }

  /// Marks the node as [AssetState.REMOVED].
  ///
  /// Once a node is marked as removed, it can't be marked as any other state.
  /// If a new asset is created with the same id, it will get a new node.
  void setRemoved() {
    assert(node._state != AssetState.REMOVED);
    node._state = AssetState.REMOVED;
    node._asset = null;
    node._lazyCallback = null;
    node._stateChangeController.add(AssetState.REMOVED);
  }

  /// Marks the node as [AssetState.AVAILABLE] with the given concrete [asset].
  ///
  /// It's an error to mark an already-available node as available. It should be
  /// marked as dirty first.
  void setAvailable(Asset asset) {
    assert(asset.id == node.id);
    assert(node._state != AssetState.REMOVED);
    assert(node._state != AssetState.AVAILABLE);
    node._state = AssetState.AVAILABLE;
    node._asset = asset;
    node._lazyCallback = null;
    node._stateChangeController.add(AssetState.AVAILABLE);
  }

  /// Marks the node as [AssetState.DIRTY] and lazy.
  ///
  /// Lazy nodes aren't expected to have their values generated until needed.
  /// Once it's necessary, [callback] will be called. [callback] is guaranteed
  /// to be called only once.
  ///
  /// See also [AssetNodeController.lazy].
  void setLazy(void callback()) {
    assert(node._state != AssetState.REMOVED);
    node._state = AssetState.DIRTY;
    node._asset = null;
    node._lazyCallback = callback;
    node._stateChangeController.add(AssetState.DIRTY);
  }

  String toString() => "controller for $node";
}

// TODO(nweiz): add an error state.
/// An enum of states that an [AssetNode] can be in.
class AssetState {
  /// The node has a concrete asset loaded, available, and up-to-date. The asset
  /// is accessible via [AssetNode.asset]. An asset can only be marked available
  /// again from the [AssetState.DIRTY] state.
  static final AVAILABLE = const AssetState._("available");

  /// The asset is no longer available, possibly for good. A removed asset will
  /// never enter another state.
  static final REMOVED = const AssetState._("removed");

  /// The asset will exist in the future (unless it's removed), but the concrete
  /// asset is not yet available.
  static final DIRTY = const AssetState._("dirty");

  /// Whether this state is [AssetState.AVAILABLE].
  bool get isAvailable => this == AssetState.AVAILABLE;

  /// Whether this state is [AssetState.REMOVED].
  bool get isRemoved => this == AssetState.REMOVED;

  /// Whether this state is [AssetState.DIRTY].
  bool get isDirty => this == AssetState.DIRTY;

  final String name;

  const AssetState._(this.name);

  String toString() => name;
}
