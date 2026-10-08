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

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool testPhi(bool b) {
  final list = b ? const <int>[1] : List.filled(2, 2, growable: false);
  return list.isEmpty;
}

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

void matchIL$testPhi(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'c_imm' <<
          match.Constant(
            T: match.CompileType(
              concreteClass: '_ImmutableList',
              type: '_ImmutableList<int>',
              canBeNull: false,
            ),
          ),
    ]),
    match.block('Function', [
      'b' << match.Parameter(index: 0),
      match.Branch(
        match.StrictCompare('b', match.any),
        ifTrue: 'B_true',
        ifFalse: 'B_false',
      ),
    ]),
    'B_true' << match.block('Target', [match.Goto('B_join')]),
    'B_false' <<
        match.block('Target', [
          'c_list' <<
              match.CreateArray(
                match.any,
                match.any,
                T: match.CompileType(
                  concreteClass: '_List',
                  type: '_List<int>',
                  canBeNull: false,
                ),
              ),
          match.Goto('B_loop'),
        ]),
    'B_loop' <<
        match.block('Join', [
          match.Branch(
            match.RelationalOp(match.any, match.any, kind: '<'),
            ifTrue: 'B_loop_body',
            ifFalse: 'B_loop_exit',
          ),
        ]),
    'B_loop_body' << match.block('Target', [match.Goto('B_loop')]),
    'B_loop_exit' << match.block('Target', [match.Goto('B_join')]),
    'B_join' <<
        match.block('Join', [
          'list' <<
              match.Phi(
                'c_imm',
                'c_list',
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

  print(testPhi(args.isEmpty));
  print(testPhi(args.isNotEmpty));
}
