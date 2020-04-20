// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A directed acyclic graph where each node is in a [NodeState] and can have
/// data attached to it with [Node.data].
///
/// The graph exposes a few broadcast streams that can be subscribed to in
/// order to be notified of modifications to the graph.
class Graph<T> {
  final _nodes = <Node<T>>{};
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
    var added = StreamController<Node<T>>();
    var changed = StreamController<StateChangedEvent<T>>();
    var sealed = StreamController<Null>();

    return Graph._(
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
  int stateCount(NodeState state) => _stateCounts[state] ?? 0;

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
  Node<T> add(T userData, Iterable<Node<T>> dependencies,
      {bool timingDependency = false}) {
    assert(!_isSealed);

    var node = Node._(userData, timingDependency);
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

    _emitEvent(_changedController, StateChangedEvent(node, fromState, state));
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
class Node<T> {
  final T data;
  final bool timingDependency;
  NodeState _state = NodeState.initialized;
  final Set<Node<T>> _dependencies = {};
  final Set<Node<T>> _neededFor = {};

  Node._(this.data, this.timingDependency);

  NodeState get state => _state;
  Iterable<Node<T>> get dependencies => _dependencies;
  Iterable<Node<T>> get neededFor => _neededFor;
}

class NodeState {
  static const initialized = NodeState._("Initialized");
  static const waiting = NodeState._("Waiting");
  static const enqueuing = NodeState._("Enqueuing");
  static const processing = NodeState._("Running");
  static const successful = NodeState._("Successful");
  static const failed = NodeState._("Failed");
  static const unableToRun = NodeState._("UnableToRun");

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
