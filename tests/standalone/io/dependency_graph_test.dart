// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import '../../../tools/testing/dart/dependency_graph.dart' as graph;

main() {
  var dgraph = new graph.Graph();
  var numberOfEvents = 0;
  var eventAssertions = [];

  graph.Node newNode(int i, List deps) {
    graph.Node node = dgraph.newNode(i, deps);
    Expect.isTrue(node.userData == i);
    Expect.isTrue(dgraph.nodes.contains(node));
    for (var dep in deps) {
      Expect.isTrue(node.dependencies.contains(dep));
      Expect.isTrue(dep.neededFor.contains(node));
    }

    numberOfEvents++;
    eventAssertions.add((event) {
      Expect.isTrue(event is graph.NodeAddedEvent);
      Expect.isTrue(event.node == node);
    });

    return node;
  }

  changeState(graph.Node node, graph.NodeState newState) {
    var oldState = node.state;

    dgraph.changeState(node, newState);
    Expect.isTrue(node.state == newState);

    numberOfEvents++;
    eventAssertions.add((event) {
      Expect.isTrue(event is graph.StateChangedEvent);
      Expect.isTrue(event.node == node);
      Expect.isTrue(event.from == oldState);
      Expect.isTrue(event.to == newState);
    });
  }

  var node1, node2, node3;

  node1 = newNode(1, []);
  changeState(node1, graph.NodeState.Processing);
  node2 = newNode(2, [node1]);
  changeState(node1, graph.NodeState.Successful);
  node3 = newNode(3, [node1, node2]);
  changeState(node2, graph.NodeState.Failed);
  changeState(node3, graph.NodeState.UnableToRun);

  dgraph.events.take(numberOfEvents).toList().then((events) {
    for (var i = 0; i < events.length; i++) {
      eventAssertions[i](events[i]);
    }
  });
}
