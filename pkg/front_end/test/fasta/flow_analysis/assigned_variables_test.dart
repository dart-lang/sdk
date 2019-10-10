// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/flow_analysis/flow_analysis.dart';
import 'package:test/test.dart';

main() {
  test('writtenInNode ignores assignments outside the node', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.write(v1);
    assignedVariables.beginNode();
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.write(v2);
    expect(assignedVariables.writtenInNode(node), isEmpty);
  });

  test('writtenInNode records assignments inside the node', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    var node = _Node();
    assignedVariables.endNode(node);
    expect(assignedVariables.writtenInNode(node), {v1});
  });

  test('writtenInNode records assignments in a nested node', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.beginNode();
    assignedVariables.beginNode();
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node());
    var node = _Node();
    assignedVariables.endNode(node);
    expect(assignedVariables.writtenInNode(node), {v1});
  });

  test('writtenInNode records assignments in a closure', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.beginNode(isClosure: true);
    assignedVariables.write(v1);
    var node = _Node();
    assignedVariables.endNode(node, isClosure: true);
    expect(assignedVariables.writtenInNode(node), {v1});
  });

  test('capturedInNode ignores assignments in non-nested closures', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    var v2 = _Variable('v2');
    assignedVariables.beginNode(isClosure: true);
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node(), isClosure: true);
    assignedVariables.beginNode();
    var node = _Node();
    assignedVariables.endNode(node);
    assignedVariables.beginNode(isClosure: true);
    assignedVariables.write(v2);
    assignedVariables.endNode(_Node(), isClosure: true);
    expect(assignedVariables.capturedInNode(node), isEmpty);
  });

  test('capturedInNode records assignments in nested closures', () {
    var assignedVariables = AssignedVariables<_Node, _Variable>();
    var v1 = _Variable('v1');
    assignedVariables.beginNode();
    assignedVariables.beginNode(isClosure: true);
    assignedVariables.write(v1);
    assignedVariables.endNode(_Node(), isClosure: true);
    var node = _Node();
    assignedVariables.endNode(node);
    expect(assignedVariables.capturedInNode(node), {v1});
  });
}

class _Node {}

class _Variable {
  final String name;

  _Variable(this.name);

  @override
  String toString() => name;
}
