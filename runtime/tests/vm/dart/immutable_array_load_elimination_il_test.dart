// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that load forwarding eliminates redundant indexed loads on
// _ImmutableList (kImmutableArrayCid) across side-effecting calls, including
// on lists returned by List.unmodifiable (new List.from ->
// makeFixedListUnmodifiable).

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

class Holder {
  final List<int> items;
  Holder(bool flag) : items = flag ? const [10, 20, 30] : const [40, 50, 60];
}

@pragma('vm:never-inline')
void sideEffect() {}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int sumAcrossCall(Holder h) {
  final a = h.items[0];
  sideEffect();
  final b = h.items[0];
  return a + b;
}

void matchIL$sumAcrossCall(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'h' << match.Parameter(index: 0),
      'items' << match.LoadField('h', slot: 'items'),
      'elem' << match.LoadIndexed('items', match.any),
      match.StaticCall(function: 'sideEffect'),
      'unboxed' << match.UnboxInt64('elem'),
      'sum' << match.BinaryInt64Op('unboxed', 'unboxed'),
      match.DartReturn('sum'),
    ]),
  ]);
}

@pragma('vm:prefer-inline')
List<int> _buildFrozen(int x, int y) {
  return List<int>.unmodifiable(<int>[x, y]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int buildThenFreeze(int x, int y) {
  final list = _buildFrozen(x, y);
  final a = list[0];
  sideEffect();
  final b = list[0];
  final c = list[1];
  return a + b + c;
}

void matchIL$buildThenFreeze(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'array' << match.CreateArray(match.any, match.any),
      match.StoreIndexed('array', match.any, match.any),
      match.StoreIndexed('array', match.any, match.any),
      'copy' <<
          match.StaticCall(
            match.any,
            match.any,
            match.any,
            function: 'new List.from',
          ),
      'frozen' <<
          match.StaticCall(
            match.any,
            'copy',
            function: 'makeFixedListUnmodifiable',
          ),
      'a' << match.LoadIndexed('frozen', match.any),
      match.StaticCall(function: 'sideEffect'),
      'c' << match.LoadIndexed('frozen', match.any),
      'a_unboxed' << match.UnboxInt64('a'),
      'ab' << match.BinaryInt64Op('a_unboxed', 'a_unboxed'),
      'c_unboxed' << match.UnboxInt64('c'),
      'abc' << match.BinaryInt64Op('ab', 'c_unboxed'),
      match.DartReturn('abc'),
    ]),
  ]);
}

void main(List<String> args) {
  final flag = args.isEmpty;
  Expect.equals(20, sumAcrossCall(Holder(flag)));
  Expect.equals(80, sumAcrossCall(Holder(!flag)));
  Expect.equals(35, buildThenFreeze(10, 15));
  Expect.equals(70, buildThenFreeze(20, 30));
}
