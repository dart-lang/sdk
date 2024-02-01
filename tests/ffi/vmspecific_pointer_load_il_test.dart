// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that `Pointer` are not allocated before being passed into a load.

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';
import 'package:vm/testing/il_matchers.dart';

void main() async {
  using((arena) {
    const length = 100;
    final pointer = arena<Int8>(100);
    for (int i = 0; i < length; i++) {
      pointer[i] = i;
    }
    Expect.equals(
      10,
      testOffset(pointer),
    );
    Expect.equals(
      10,
      testAllocate(pointer),
    );
    Expect.equals(
      45,
      testHoist(pointer),
    );
    print(globalVar);
  });
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testOffset(Pointer<Int8> pointer) {
  // `pointer2` is not allocated.
  final pointer2 = pointer + 10;
  return pointer2.value;
}

void matchIL$testOffset(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', [
      'int 10' << match.UnboxedConstant(value: 10),
      'int 0' << match.UnboxedConstant(value: 0),
    ]),
    match.block('Function', [
      'pointer' <<
          match.Parameter(
            index: 0,
          ),
      'pointer.address untagged' <<
          match.LoadField(
            'pointer',
            slot: 'PointerBase.data',
          ),
      'pointer.address int64' <<
          match.IntConverter(
            'pointer.address untagged',
            from: 'untagged',
            to: 'int64',
          ),
      'pointer2.address int64' <<
          match.BinaryInt64Op(
            'pointer.address int64',
            'int 10',
          ),
      // `pointer2` is not allocated.
      'pointer2.address untagged' <<
          match.IntConverter(
            'pointer2.address int64',
            from: 'int64',
            to: 'untagged',
          ),
      'pointer2.value' <<
          match.LoadIndexed(
            'pointer2.address untagged',
            'int 0',
          ),
      match.Return('pointer2.value'),
    ]),
  ]);
}

class A {
  final int i;

  A(this.i);
}

A? globalVar;

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testAllocate(Pointer<Int8> pointer) {
  final pointer2 = pointer + 10;
  globalVar = A(10);
  return pointer2.value;
}

void matchIL$testAllocate(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', [
      'int 10' << match.UnboxedConstant(value: 10),
      'int 0' << match.UnboxedConstant(value: 0),
    ]),
    match.block('Function', [
      'pointer' <<
          match.Parameter(
            index: 0,
          ),
      'pointer.address untagged' <<
          match.LoadField(
            'pointer',
            slot: 'PointerBase.data',
          ),
      'pointer.address int64' <<
          match.IntConverter(
            'pointer.address untagged',
            from: 'untagged',
            to: 'int64',
          ),
      'pointer2.address int64' <<
          match.BinaryInt64Op(
            'pointer.address int64',
            'int 10',
          ),
      'pointer2.address untagged' <<
          match.IntConverter(
            'pointer2.address int64',
            from: 'int64',
            to: 'untagged',
          ),
      // The untagged pointer2.address can live through an allocation
      // even though it is marked `InnerPointerAccess::kMayBeInnerPointer`
      // because its cid is a Pointer cid.
      match.AllocateObject(),
      match.StoreStaticField(match.any),
      'pointer2.value' <<
          match.LoadIndexed(
            'pointer2.address untagged',
            'int 0',
          ),
      match.Return('pointer2.value'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testHoist(Pointer<Int8> pointer) {
  int result = 0;
  for (int i = 0; i < 10; i++) {
    globalVar = A(10);
    // The address load is hoisted out of the loop.
    // The indexed load is _not_ hoisted out of the loop.
    result += pointer[i];
  }
  return result;
}

void matchIL$testHoist(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', [
      'int 0' << match.UnboxedConstant(value: 0),
      'int 10' << match.UnboxedConstant(value: 10),
      'int 1' << match.UnboxedConstant(value: 1),
    ]),
    match.block('Function', [
      'pointer' <<
          match.Parameter(
            index: 0,
          ),
      'pointer.address' <<
          match.LoadField(
            'pointer',
            slot: 'PointerBase.data',
          ),
      match.Goto('B1'),
    ]),
    'B1' <<
        match.block('Join', [
          match.CheckStackOverflow(),
          match.Branch(match.RelationalOp(match.any, match.any, kind: '<'),
              ifTrue: 'B2', ifFalse: 'B3'),
        ]),
    'B2' <<
        match.block('Target', [
          // Do some allocation.
          match.AllocateObject(),
          match.StoreStaticField(match.any),
          // Do a load indexed with the untagged pointer.address that is
          // hoisted out of the loop.
          'pointer[i]' <<
              match.LoadIndexed(
                'pointer.address',
                match.any, // i
              ),
          'result' <<
              match.BinaryInt64Op(
                match.any,
                'pointer[i]',
              ),
          'i' <<
              match.BinaryInt64Op(
                match.any,
                match.any,
              ),
          match.Goto('B1'),
        ]),
    'B3' <<
        match.block('Target', [
          match.Return(match.any),
        ]),
  ]);
}
