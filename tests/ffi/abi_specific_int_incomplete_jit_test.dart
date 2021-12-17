// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

// We want at least 1 mapping to satisfy the static checks.
const notTestingOn = Abi.fuchsiaArm64;

@AbiSpecificIntegerMapping({
  notTestingOn: Int8(),
})
class Incomplete extends AbiSpecificInteger {
  const Incomplete();
}

void main() {
  if (Abi.current() == notTestingOn) {
    return;
  }
  testSizeOf();
  testStoreLoad();
  testStoreLoadIndexed();
  testStruct();
  testInlineArray();
  testInlineArray2();
  testAsFunction();
  testFromFunction();
}

void testSizeOf() {
  Expect.throws(() {
    sizeOf<Incomplete>();
  });
}

void testStoreLoad() {
  final p = calloc<Int64>().cast<Incomplete>();
  Expect.throws(() {
    p.value = 10;
  });
  Expect.throws(() {
    p.value;
  });
  calloc.free(p);
}

void testStoreLoadIndexed() {
  final p = calloc<Int64>().cast<Incomplete>();
  Expect.throws(() {
    p[0] = 10;
  });
  Expect.throws(() {
    p[1];
  });
  calloc.free(p);
}

class IncompleteStruct extends Struct {
  @Incomplete()
  external int a0;

  @Incomplete()
  external int a1;
}

void testStruct() {
  final p = calloc<Int64>(2).cast<IncompleteStruct>();
  Expect.throws(() {
    p.ref.a0 = 1;
  });
  Expect.throws(() {
    p.ref.a0;
  });
  calloc.free(p);
}

class IncompleteArrayStruct extends Struct {
  @Array(100)
  external Array<Incomplete> a0;
}

void testInlineArray() {
  final p = calloc<Int64>(100).cast<IncompleteArrayStruct>();
  final array = p.ref.a0;
  Expect.throws(() {
    array[3] = 4;
  });
  Expect.throws(() {
    array[3];
  });
  calloc.free(p);
}

const _dim1 = 8;
const _dim2 = 4;

class IncompleteArrayArrayStruct extends Struct {
  @Array(_dim1, _dim2)
  external Array<Array<Incomplete>> a0;
}

void testInlineArray2() {
  final p = calloc<Int64>(100).cast<IncompleteArrayArrayStruct>();
  Expect.throws(() {
    p.elementAt(3);
  });
  calloc.free(p);
}

void testAsFunction() {
  Expect.throws(() {
    nullptr
        .cast<NativeFunction<Int32 Function(Incomplete)>>()
        .asFunction<int Function(int)>();
  });
  Expect.throws(() {
    nullptr
        .cast<NativeFunction<Incomplete Function(Int32)>>()
        .asFunction<int Function(int)>();
  });
  Expect.throws(() {
    nullptr
        .cast<NativeFunction<Int32 Function(IncompleteArrayStruct)>>()
        .asFunction<int Function(IncompleteArrayStruct)>();
  });
  Expect.throws(() {
    nullptr
        .cast<NativeFunction<IncompleteArrayStruct Function()>>()
        .asFunction<IncompleteArrayStruct Function()>();
  });
}

int myIncr(int a) => a + 1;

IncompleteArrayStruct myIncompleteReturn() =>
    nullptr.cast<IncompleteArrayStruct>().ref;

int myIncompleteArg(IncompleteArrayStruct a) => 5;

void testFromFunction() {
  Expect.throws(() {
    Pointer.fromFunction<Incomplete Function(Int32)>(myIncr, 3);
  });
  Expect.throws(() {
    Pointer.fromFunction<Int32 Function(Incomplete)>(myIncr, 3);
  });
  Expect.throws(() {
    Pointer.fromFunction<IncompleteArrayStruct Function()>(myIncompleteReturn);
  });
  Expect.throws(() {
    Pointer.fromFunction<Int32 Function(IncompleteArrayStruct)>(
        myIncompleteArg, 3);
  });
}
