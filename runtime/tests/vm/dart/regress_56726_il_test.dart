// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that List bound check is eliminated in a simple for-loop
// over growable list.

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
void myprint(Object o) {
  print(o);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
useList(List<int> a) {
  for (int i = 0; i < a.length; ++i) {
    final value = a[i];
    myprint(value);
  }
}

main() {
  useList([]);
  useList([100]);
}

void matchIL$useList(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', [
      'c_null' << match.Constant(value: null),
      'c_zero' << match.UnboxedConstant(value: 0),
      'c_one' << match.UnboxedConstant(value: 1),
    ]),
    match.block('Function', [
      'a' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      match.Goto('B5'),
    ]),
    'B5' <<
        match.block('Join', [
          'i' << match.Phi('c_zero', 'i+1'),
          match.CheckStackOverflow(),
          'a.length' <<
              match.LoadField('a', slot: 'GrowableObjectArray.length'),
          if (is32BitConfiguration) ...[
            'i_32a' << match.IntConverter('i', from: 'int64', to: 'int32'),
            'a.length_unboxed' << match.UnboxInt32('a.length'),
          ] else ...[
            'a.length_unboxed' << match.UnboxInt64('a.length'),
          ],
          match.Branch(
              match.RelationalOp(
                  is32BitConfiguration ? 'i_32a' : 'i', 'a.length_unboxed',
                  kind: '<'),
              ifTrue: 'B3',
              ifFalse: 'B4'),
        ]),
    'B3' <<
        match.block('Target', [
          // No bounds check here.
          if (is32BitConfiguration)
            'i_boxed' << match.BoxInt64('i', skipUntilMatched: false),
          'a.data' <<
              match.LoadField('a',
                  slot: 'GrowableObjectArray.data', skipUntilMatched: false),
          'value' <<
              match.LoadIndexed(
                  'a.data', is32BitConfiguration ? 'i_boxed' : 'i',
                  skipUntilMatched: false),
          'value_unboxed' << match.UnboxInt64('value'),
          match.StaticCall('value_unboxed'),
          if (is32BitConfiguration) ...[
            'i_32' << match.IntConverter('i', from: 'int64', to: 'int32'),
            'i+1_32' << match.BinaryInt32Op('i_32', 'c_one', op_kind: '+'),
            'i+1' << match.IntConverter('i+1_32', from: 'int32', to: 'int64'),
          ] else ...[
            'i+1' << match.BinaryInt64Op('i', 'c_one', op_kind: '+'),
          ],
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          match.DartReturn('c_null'),
        ]),
  ]);
}
