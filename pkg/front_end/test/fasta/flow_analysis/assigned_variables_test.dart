// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/flow_analysis/flow_analysis.dart';
import 'package:test/test.dart';

main() {
  test('capturedAnywhere records assignments in closures', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var v3 = _Variable('v3');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.declare(v3);
    assignedVariables.write(v1);
    assignedVariables.beginNode();
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(), isClosure: true);
    assignedVariables.write(v3);
    assignedVariables.finish();
    expect(assignedVariables.capturedAnywhere, {v2});
  });

  test('capturedAnywhere does not record variables local to a closure', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.declare(v2);
    assignedVariables.write(v1);
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(), isClosure: true);
    assignedVariables.finish();
    expect(assignedVariables.capturedAnywhere, {v1});
  });

  test('writtenAnywhere records all assignments', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    var v3 = _Variable('v3');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.declare(v3);
    assignedVariables.write(v1);
    assignedVariables.beginNode();
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(), isClosure: true);
    assignedVariables.write(v3);
    assignedVariables.finish();
    expect(assignedVariables.writtenAnywhere, {v1, v2, v3});
  });

  test('writtenInNode ignores assignments outside the node', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.write(v1);
    assignedVariables.beginNode();
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.write(v2);
    assignedVariables.finish();
    expect(assignedVariables.writtenInNode(node), isEmpty);
  });

  test('writtenInNode records assignments inside the node', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(assignedVariables.writtenInNode(node), {v1});
  });

  test('writtenInNode records assignments in a nested node', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node());
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(assignedVariables.writtenInNode(node), {v1});
  });

  test('writtenInNode records assignments in a closure', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    var node = _Node();
    assignedVariables.endNode(node, isClosure: true);
    assignedVariables.finish();
    expect(assignedVariables.writtenInNode(node), {v1});
  });

  test('capturedInNode ignores assignments in non-nested closures', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.declare(v1);
    assignedVariables.declare(v2);
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node(), isClosure: true);
    assignedVariables.beginNode();
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.beginNode();
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(), isClosure: true);
    assignedVariables.finish();
    expect(assignedVariables.capturedInNode(node), isEmpty);
  });

  test('capturedInNode records assignments in nested closures', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.declare(v1);
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node(), isClosure: true);
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.finish();
    expect(assignedVariables.capturedInNode(node), {v1});
  });

  group('Variables do not percolate beyond the scope they were declared in',
      () {
    test('Non-closure scope', () {
      var assignedVariables = AssignedVariables<_Node, _Variable>();
      var v1 = _Variable('v1');
      var v2 = _Variable('v2');
      assignedVariables.beginNode();
      assignedVariables.beginNode();
      assignedVariables.declare(v1);
      assignedVariables.declare(v2);
      assignedVariables.write(v1);
      assignedVariables.beginNode();
      assignedVariables.write(v2);
      assignedVariables.endNode(_Node(), isClosure: true);
      var innerNode = _Node();
      assignedVariables.endNode(innerNode, isClosure: false);
      var outerNode = _Node();
      assignedVariables.endNode(outerNode);
      assignedVariables.finish();
      expect(assignedVariables.writtenInNode(innerNode), isEmpty);
      expect(assignedVariables.capturedInNode(innerNode), isEmpty);
      expect(assignedVariables.writtenInNode(outerNode), isEmpty);
      expect(assignedVariables.capturedInNode(outerNode), isEmpty);
    });

    test('Closure scope', () {
      var assignedVariables = AssignedVariables<_Node, _Variable>();
      var v1 = _Variable('v1');
      var v2 = _Variable('v2');
      assignedVariables.beginNode();
      assignedVariables.beginNode();
      assignedVariables.declare(v1);
      assignedVariables.declare(v2);
      assignedVariables.write(v1);
      assignedVariables.beginNode();
      assignedVariables.write(v2);
      assignedVariables.endNode(_Node(), isClosure: true);
      var innerNode = _Node();
      assignedVariables.endNode(innerNode, isClosure: true);
      var outerNode = _Node();
      assignedVariables.endNode(outerNode);
      assignedVariables.finish();
      expect(assignedVariables.writtenInNode(innerNode), isEmpty);
      expect(assignedVariables.capturedInNode(innerNode), isEmpty);
      expect(assignedVariables.writtenInNode(outerNode), isEmpty);
      expect(assignedVariables.capturedInNode(outerNode), isEmpty);
    });
  });
}

class _Node {}

class _Variable {
  final String name;

  _Variable(this.name);

  @override
  String toString() => name;
}
