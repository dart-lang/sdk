// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm/testing/il_matchers.dart';

class A {
  final List<int> list;
  A(this.list);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool testField(A a) => a.list.isEmpty;

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool testParam(List<int> list) => list.isEmpty;

void matchIL$testField(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'a' << match.Parameter(index: 0),
      'list' <<
          match.LoadField(
            'a',
            slot: 'list',
            T: match.CompileType(type: '_Array<int>', canBeNull: false),
          ),
      'len' << match.LoadField('list', slot: 'Array.length'),
      'res' << match.StrictCompare('len', match.any, kind: '==='),
      match.DartReturn('res'),
    ]),
  ]);
}

void matchIL$testParam(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'list' <<
          match.Parameter(
            index: 0,
            T: match.CompileType(type: '_Array<int>', canBeNull: false),
          ),
      'len' << match.LoadField('list', slot: 'Array.length'),
      'res' << match.StrictCompare('len', match.any, kind: '==='),
      match.DartReturn('res'),
    ]),
  ]);
}

void main(List<String> args) {
  // Ensure ListBase.isEmpty is also called on a growable list so TFA does not
  // devirtualize `this.length` inside `ListBase.isEmpty` itself.
  print(<int>[1, 2, 3].isEmpty);

  final list1 = const <int>[1];
  final list2 = List.filled(2, 2, growable: false);

  print(testField(A(list1)));
  print(testField(A(list2)));

  print(testParam(list1));
  print(testParam(list2));
}
