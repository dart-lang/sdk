// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that we assign proper type to LoadIndexed() which ends up in a graph
// after multiple layer of inlining.

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int forInListOfInt(List<int> list) {
  var result = 0;
  for (var e in list) {
    result ^= e;
  }
  return result;
}

void matchIL$forInListOfInt(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'int 0' << match.UnboxedConstant(),
      'int 1' << match.UnboxedConstant(),
    ]),
    match.block('Function', [
      'list' << match.Parameter(index: 0),
      'list.data' << match.LoadField('list', slot: 'GrowableObjectArray.data'),
      match.Goto('B14'),
    ]),
    'B14' <<
        match.block('Join', [
          'result' << match.Phi('int 0', 'result^e'),
          'index' << match.Phi('int 0', 'index+1'),
          match.Branch(match.RelationalOp(match.any, match.any, kind: '>=')),
        ]),
    'B4' << match.block('Target'),
    'B10' <<
        match.block('Target', [
          if (is32BitConfiguration) 'box(index)' << match.BoxInt64('index'),
          'e' <<
              match.LoadIndexed(
                  'list.data', is32BitConfiguration ? 'box(index)' : 'index'),
          'index+1' << match.BinaryInt64Op('index', 'int 1'),
          'unbox(e)' << match.UnboxInt64('e'),
          'result^e' << match.BinaryInt64Op('result', 'unbox(e)'),
          match.Goto('B14'),
        ]),
  ]);
}

void main() {
  print(forInListOfInt([1]));
  print(forInListOfInt([2]));
}
