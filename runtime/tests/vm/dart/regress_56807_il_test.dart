// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that List bound check is eliminated in a loop
// using iterator over growable list.

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
void myprint(Object o) {
  print(o);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
useList2(List<int> a) {
  for (final iter = MyIter(a); iter.moveNext();) {
    final value = iter.current;
    myprint(value);
  }
}

class MyIter<E> implements Iterator<E> {
  final List<E> _list;
  int _index = 0;
  E? _current;

  MyIter(this._list);

  E get current => _current as E;

  bool moveNext() {
    int length = _list.length;
    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _list[_index];
    _index++;
    return true;
  }
}

main() {
  useList2([]);
  useList2([30, 40]);
}

void matchIL$useList2(FlowGraph graph) {
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
          'a.length_unboxed' << match.UnboxInt64('a.length'),
          if (is32BitConfiguration)
            'i_ext' << match.IntConverter('i', from: 'int32', to: 'int64'),
          match.Branch(
              match.RelationalOp(
                  is32BitConfiguration ? 'i_ext' : 'i', 'a.length_unboxed',
                  kind: '>='),
              ifTrue: 'B4',
              ifFalse: 'B10'),
        ]),
    'B4' <<
        match.block('Target', [
          match.DartReturn('c_null'),
        ]),
    'B10' <<
        match.block('Target', [
          // No bounds check here.
          'a.data' <<
              match.LoadField('a',
                  slot: 'GrowableObjectArray.data', skipUntilMatched: false),
          if (is32BitConfiguration)
            'i_boxed' << match.BoxInt32('i', skipUntilMatched: false),
          'value' <<
              match.LoadIndexed(
                  'a.data', is32BitConfiguration ? 'i_boxed' : 'i',
                  skipUntilMatched: false),
          if (is32BitConfiguration)
            'i+1' << match.BinaryInt32Op('i', 'c_one', op_kind: '+')
          else
            'i+1' << match.BinaryInt64Op('i', 'c_one', op_kind: '+'),
          'value_unboxed' << match.UnboxInt64('value'),
          match.StaticCall('value_unboxed'),
          match.Goto('B5'),
        ]),
  ]);
}
