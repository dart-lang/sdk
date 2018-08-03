// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'utils.dart';

/// A directed acyclic graph where each node is in a [NodeState] and can have
/// data attached to it with [Node.data].
///
/// The graph exposes a few broadcast streams that can be subscribed to in
/// order to be notified of modifications to the graph.
class Graph<T> {
  final _nodes = new Set<Node<T>>();
  final _stateCounts = <NodeState, int>{};
  bool _isSealed = false;

  /// Notifies when nodes are added to the graph.
  final Stream<Node<T>> added;
  final StreamController<Node<T>> _addedController;

  /// Notifies when a node's state has changed.
  final Stream<StateChangedEvent<T>> changed;
  final StreamController<StateChangedEvent<T>> _changedController;

  /// Notifies when the graph is sealed.
  final Stream<Null> sealed;
  final StreamController<Null> _sealedController;

  factory Graph() {
    var added = new StreamController<Node<T>>();
    var changed = new StreamController<StateChangedEvent<T>>();
    var sealed = new StreamController<Null>();

    return new Graph._(
        added,
        added.stream.asBroadcastStream(),
        changed,
        changed.stream.asBroadcastStream(),
        sealed,
        sealed.stream.asBroadcastStream());
  }

  Graph._(this._addedController, this.added, this._changedController,
      this.changed, this._sealedController, this.sealed);

  Iterable<Node<T>> get nodes => _nodes;
  bool get isSealed => _isSealed;

  /// Counts the number of nodes who are in [state].
  int stateCount(NodeState state) {
    int count = _stateCounts[state];
    return count == null ? 0 : count;
  }

  void dumpCounts() {
    for (var state in _stateCounts.keys) {
      print("Count[$state] = ${_stateCounts[state]}");
    }
  }

  /// Makes the graph immutable.
  void seal() {
    assert(!_isSealed);
    _isSealed = true;
    _emitEvent(_sealedController, null);
  }

  /// Adds a new node to the graph with [dependencies] and [userData].
  ///
  /// The node is in the [NodeState.initialized] state.
  Node<T> add(T userData, Iterable<Node<T>> dependencies) {
    assert(!_isSealed);

    var node = new Node._(userData);
    _nodes.add(node);

    for (var dependency in dependencies) {
      dependency._neededFor.add(node);
      node._dependencies.add(dependency);
    }

    _emitEvent(_addedController, node);

    _stateCounts.putIfAbsent(node.state, () => 0);
    _stateCounts[node.state] += 1;

    return node;
  }

  /// Changes the state of [node] to [state].
  void changeState(Node<T> node, NodeState state) {
    var fromState = node.state;
    node._state = state;

    _stateCounts[fromState] -= 1;
    _stateCounts.putIfAbsent(state, () => 0);
    _stateCounts[state] += 1;

    _emitEvent(
        _changedController, new StateChangedEvent(node, fromState, state));
  }

  /// We emit events asynchronously so the graph can be build up in small
  /// batches and the events are delivered in small batches.
  void _emitEvent<E>(StreamController<E> controller, E event) {
    Timer.run(() {
      controller.add(event);
    });
  }
}

/// A single node in a [Graph].
class Node<T> extends UniqueObject {
  final T data;
  NodeState _state = NodeState.initialized;
  final Set<Node<T>> _dependencies = new Set();
  final Set<Node<T>> _neededFor = new Set();

  Node._(this.data);

  NodeState get state => _state;
  Iterable<Node<T>> get dependencies => _dependencies;
  Iterable<Node<T>> get neededFor => _neededFor;
}

class NodeState {
  static const initialized = const NodeState._("Initialized");
  static const waiting = const NodeState._("Waiting");
  static const enqueuing = const NodeState._("Enqueuing");
  static const processing = const NodeState._("Running");
  static const successful = const NodeState._("Successful");
  static const failed = const NodeState._("Failed");
  static const unableToRun = const NodeState._("UnableToRun");

  final String name;

  const NodeState._(this.name);

  String toString() => name;
}

class StateChangedEvent<T> {
  final Node<T> node;
  final NodeState from;
  final NodeState to;

  StateChangedEvent(this.node, this.from, this.to);
}
