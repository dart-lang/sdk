// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that we appropriately choose between EqualityCompare
// and StrictCompare for integer comparisons.

import 'package:vm/testing/il_matchers.dart';

// When comparing an already unboxed value we should prefer EqualityCompare.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
String compareUnboxedToConstant(int value) => value == 1 ? "A" : "B";

void matchIL$compareUnboxedToConstant(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.EqualityCompare('value', match.any, kind: '==')),
    ]),
  ]);
}

// When comparing unboxed value to smi we should prefer to unbox the smi.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
String compareUnboxedToSmi(int value, List<int> list) =>
    value == list.length ? "A" : "B";

void matchIL$compareUnboxedToSmi(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.EqualityCompare('value', match.any, kind: '==')),
    ]),
  ]);
}

// When comparing two Smis we should prefer to StrictCompare.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
String compareTwoBoxedSmis(List<int> list1, List<int> list2) =>
    list1.length == list2.length ? "A" : "B";

void matchIL$compareTwoBoxedSmis(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'list1' << match.Parameter(index: 0),
      'list2' << match.Parameter(index: 1),
      'list1.length' <<
          match.LoadField('list1', slot: 'GrowableObjectArray.length'),
      'list2.length' <<
          match.LoadField('list2', slot: 'GrowableObjectArray.length'),
      match.Branch(
          match.StrictCompare('list1.length', 'list2.length', kind: '===')),
    ]),
  ]);
}

// When comparing a Smi to a boxed value we should prefer to StrictCompare.
@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
String compareBoxedSmiToBoxedInt(List<int> list1, List<int> list2) =>
    list1.length == list2[0] ? "A" : "B";

void matchIL$compareBoxedSmiToBoxedInt(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'list1' << match.Parameter(index: 0),
      'list2' << match.Parameter(index: 1),
      'list1.length' <<
          match.LoadField('list1', slot: 'GrowableObjectArray.length'),
      'list2.length' <<
          match.LoadField('list2', slot: 'GrowableObjectArray.length'),
      'list2.data' <<
          match.LoadField('list2', slot: 'GrowableObjectArray.data'),
      'list2.data[0]' << match.LoadIndexed('list2.data', match.any),
      match.Branch(
          match.StrictCompare('list1.length', 'list2.data[0]', kind: '===')),
    ]),
  ]);
}

void main() {
  print(compareUnboxedToConstant(1));
  print(compareUnboxedToConstant(42));
  print(compareUnboxedToSmi(1, [1]));
  print(compareUnboxedToSmi(42, [1, 2, 3]));
  print(compareTwoBoxedSmis([1, 2, 3], []));
  print(compareTwoBoxedSmis([1], [2]));
  print(compareBoxedSmiToBoxedInt([1], [1]));
  print(compareBoxedSmiToBoxedInt([42, 42], [42, 42]));
}
