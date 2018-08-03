// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import '../../../tools/testing/dart/dependency_graph.dart';

main() {
  var graph = new Graph<int>();
  var numberOfEvents = 0;
  var addEventAssertions = [];
  var changeEventAssertions = [];

  Node<int> newNode(int i, List<Node<int>> deps) {
    var node = graph.add(i, deps);
    Expect.isTrue(node.data == i);
    Expect.isTrue(graph.nodes.contains(node));
    for (var dep in deps) {
      Expect.isTrue(node.dependencies.contains(dep));
      Expect.isTrue(dep.neededFor.contains(node));
    }

    numberOfEvents++;
    addEventAssertions.add((event) {
      Expect.isTrue(event == node);
      Expect.isTrue(event.data == i);
    });

    return node;
  }

  changeState(Node<int> node, NodeState newState) {
    var oldState = node.state;

    graph.changeState(node, newState);
    Expect.isTrue(node.state == newState);

    numberOfEvents++;
    changeEventAssertions.add((event) {
      Expect.isTrue(event is StateChangedEvent);
      Expect.isTrue(event.node == node);
      Expect.isTrue(event.from == oldState);
      Expect.isTrue(event.to == newState);
    });
  }

  var node1, node2, node3;

  node1 = newNode(1, []);
  changeState(node1, NodeState.processing);
  node2 = newNode(2, [node1]);
  changeState(node1, NodeState.successful);
  node3 = newNode(3, [node1, node2]);
  changeState(node2, NodeState.failed);
  changeState(node3, NodeState.unableToRun);

  graph.added.take(numberOfEvents).toList().then((events) {
    for (var i = 0; i < events.length; i++) {
      addEventAssertions[i](events[i]);
    }
  });

  graph.changed.take(numberOfEvents).toList().then((events) {
    for (var i = 0; i < events.length; i++) {
      changeEventAssertions[i](events[i]);
    }
  });
}
