// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that all checks are optimized out in a for-in loop over built-in
// list with Iterable<String> static type.

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool foobar(String token, Iterable<String> values) {
  for (String tokenValue in values) {
    if (identical(tokenValue, token)) {
      return true;
    }
  }
  return false;
}

void matchIL$foobar(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'int 0' << match.UnboxedConstant(value: 0),
      'int 1' << match.UnboxedConstant(value: 1),
    ]),
    match.block('Function', [
      'token' << match.Parameter(index: 0),
      'values' << match.Parameter(index: 1),
      'values.length' <<
          match.LoadField('values', slot: 'GrowableObjectArray.length'),
      'values.length_unboxed' << match.UnboxInt64('values.length'),
      'values.data' <<
          match.LoadField('values', slot: 'GrowableObjectArray.data'),
      match.Goto('B16'),
    ]),
    'B16' <<
        match.block('Join', [
          'i' << match.Phi('int 0', 'i+1'),
          if (is32BitConfiguration)
            'i_64' << match.IntConverter('i', from: 'int32', to: 'int64'),
          match.Branch(
              match.RelationalOp(
                  is32BitConfiguration ? 'i_64' : 'i', 'values.length_unboxed',
                  kind: '>='),
              ifTrue: 'B4',
              ifFalse: 'B12'),
        ]),
    'B4' <<
        match.block('Target', [
          match.DartReturn(match.any),
        ]),
    'B12' <<
        match.block('Target', [
          if (is32BitConfiguration) 'i_boxed' << match.BoxInt32('i'),
          'tokenValue' <<
              match.LoadIndexed(
                  'values.data', is32BitConfiguration ? 'i_boxed' : 'i'),
          if (is32BitConfiguration)
            'i+1' << match.BinaryInt32Op('i', 'int 1')
          else
            'i+1' << match.BinaryInt64Op('i', 'int 1'),
          match.Branch(match.StrictCompare('tokenValue', 'token', kind: '==='),
              ifTrue: 'B5', ifFalse: 'B6'),
        ]),
    'B5' <<
        match.block('Target', [
          match.DartReturn(match.any),
        ]),
    'B6' <<
        match.block('Target', [
          match.Goto('B16'),
        ]),
  ]);
}

main() {
  print(foobar('a', ['a', 'b', 'c']));
  print(foobar('b', ['b', 'c']));
}
