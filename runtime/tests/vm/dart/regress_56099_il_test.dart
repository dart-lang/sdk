// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that bounds check is removed from _GrowableList.add.

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void addElement(List<int> list, int value) {
  list.add(value);
}

void main() {
  addElement([], int.parse('42'));
}

void matchIL$addElement(FlowGraph graph) {
  if (is32BitConfiguration) {
    return;
  }
  graph.dump();
  graph.match([
    match.block('Graph', [
      'c_null' << match.Constant(value: null),
      'c_one' << match.UnboxedConstant(value: 1),
    ]),
    match.block('Function', [
      'list' << match.Parameter(index: 0),
      'value' << match.Parameter(index: 1),
      match.CheckStackOverflow(),
      'list.length' <<
          match.LoadField('list', slot: 'GrowableObjectArray.length'),
      'list.data' << match.LoadField('list', slot: 'GrowableObjectArray.data'),
      'capacity' << match.LoadField('list.data', slot: 'Array.length'),
      'length_unboxed' << match.UnboxInt64('list.length'),
      'capacity_unboxed' << match.UnboxInt64('capacity'),
      match.Branch(
          match.EqualityCompare('length_unboxed', 'capacity_unboxed',
              kind: '=='),
          ifTrue: 'B5',
          ifFalse: 'B6'),
    ]),
    'B5' <<
        match.block('Target', [
          match.StaticCall(),
          match.Goto('B7'),
        ]),
    'B6' <<
        match.block('Target', [
          match.Goto('B7'),
        ]),
    'B7' <<
        match.block('Join', [
          'length_plus_1' << match.BinaryInt64Op('length_unboxed', 'c_one'),
          'length_plus_1_boxed' << match.BoxInt64('length_plus_1'),
          match.StoreField('list', 'length_plus_1_boxed',
              slot: 'GrowableObjectArray.length'),
          // No bounds check here.
          'list.data_v2' <<
              match.LoadField('list',
                  slot: 'GrowableObjectArray.data', skipUntilMatched: false),
          'value_boxed' << match.BoxInt64('value', skipUntilMatched: false),
          match.StoreIndexed('list.data_v2', 'length_unboxed', 'value_boxed'),
          match.DartReturn('c_null'),
        ]),
  ]);
}
