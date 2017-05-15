// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dependency_graph;

import 'dart:async';
import 'utils.dart';

/*
 * [Graph] represents a datastructure for representing an DAG (directed acyclic
 * graph). Each node in the graph is in a given [NodeState] and can have data
 * attached to it with [Node.userData].
 *
 * It's interface consists basically of these methods:
 *   - newNode: Adds a new node to the graph with the given dependencies and
 *              the given user data. The node is in the [NodeState.Initialized]
 *              state.
 *   - changeState: Changes the state of a node.
 *   - sealGraph: Makes the graph immutable.
 *   - stateCount: Counts the number of nodes who are in a given [NodeState].
 *
 * Users of a [Graph] can listen for events by subscribing to the [events]
 * stream. Three types of events will be fired (after the graph was modified):
 *   - NodeAddedEvent: Fired after a node was added ot the graph.
 *   - StateChangedEvent: Fired after the state of a node changed.
 *   - GraphSealedEvent: Fired after the graph was marked as immutable/sealed.
 */
class Graph {
  final _nodes = new Set<Node>();
  final StreamController<GraphEvent> _eventController;
  final _stateCounts = <NodeState, int>{};
  final Stream<GraphEvent> _eventStream;
  bool _isSealed = false;

  factory Graph() {
    var controller = new StreamController<GraphEvent>();
    return new Graph._(controller, controller.stream.asBroadcastStream());
  }

  Graph._(this._eventController, this._eventStream);

  Iterable<Node> get nodes => _nodes;
  Stream<GraphEvent> get events => _eventStream;
  bool get isSealed => _isSealed;

  int stateCount(NodeState state) {
    int count = _stateCounts[state];
    return count == null ? 0 : count;
  }

  void DumpCounts() {
    for (var state in _stateCounts.keys) {
      print("Count[$state] = ${_stateCounts[state]}");
    }
  }

  void sealGraph() {
    assert(!_isSealed);
    _isSealed = true;
    _emitEvent(new GraphSealedEvent());
  }

  Node newNode(Object userData, Iterable<Node> dependencies) {
    assert(!_isSealed);

    var node = new Node._(userData);
    _nodes.add(node);

    for (var dependency in dependencies) {
      dependency._neededFor.add(node);
      node._dependencies.add(dependency);
    }

    _emitEvent(new NodeAddedEvent(node));

    _stateCounts.putIfAbsent(node.state, () => 0);
    _stateCounts[node.state] += 1;

    return node;
  }

  void changeState(Node node, NodeState newState) {
    var fromState = node.state;
    node._state = newState;

    _stateCounts[fromState] -= 1;
    _stateCounts.putIfAbsent(newState, () => 0);
    _stateCounts[newState] += 1;

    _emitEvent(new StateChangedEvent(node, fromState, newState));
  }

  void _emitEvent(GraphEvent event) {
    // We emit events asynchronously so the graph can be build up in small
    // batches and the events are delivered in small batches.
    Timer.run(() {
      _eventController.add(event);
    });
  }
}

class Node extends UniqueObject {
  final Object _userData;
  NodeState _state = NodeState.Initialized;
  Set<Node> _dependencies = new Set<Node>();
  Set<Node> _neededFor = new Set<Node>();

  Node._(this._userData);

  Object get userData => _userData;
  NodeState get state => _state;
  Iterable<Node> get dependencies => _dependencies;
  Iterable<Node> get neededFor => _neededFor;
}

class NodeState extends UniqueObject {
  static NodeState Initialized = new NodeState._("Initialized");
  static NodeState Waiting = new NodeState._("Waiting");
  static NodeState Enqueuing = new NodeState._("Enqueuing");
  static NodeState Processing = new NodeState._("Running");
  static NodeState Successful = new NodeState._("Successful");
  static NodeState Failed = new NodeState._("Failed");
  static NodeState UnableToRun = new NodeState._("UnableToRun");

  final String name;

  NodeState._(this.name);

  String toString() => name;
}

abstract class GraphEvent {}

class GraphSealedEvent extends GraphEvent {}

class NodeAddedEvent extends GraphEvent {
  final Node node;

  NodeAddedEvent(this.node);
}

class StateChangedEvent extends GraphEvent {
  final Node node;
  final NodeState from;
  final NodeState to;

  StateChangedEvent(this.node, this.from, this.to);
}
