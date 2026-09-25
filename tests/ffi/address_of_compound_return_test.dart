// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=90
// VMOptions=--use-slow-path

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';

final class Small extends Struct {
  @Float()
  external double a;

  @Int32()
  external int b;
}

final class Large extends Struct {
  @Int64()
  external int a;

  @Int64()
  external int b;

  @Int64()
  external int c;
}

final class IntegerOrDouble extends Union {
  @Int64()
  external int integer;

  @Double()
  external double floating;
}

final class Input extends Struct {
  @Uint8()
  external int value;

  @Array(2)
  external Array<Uint8> values;
}

@Native<Small Function(Pointer<Uint8>)>(
  symbol: 'ReturnSmallFromPointer',
  isLeaf: true,
)
external Small small(Pointer<Uint8> value);

@Native<Large Function(Pointer<Uint8>)>(
  symbol: 'ReturnLargeFromPointer',
  isLeaf: true,
)
external Large large(Pointer<Uint8> value);

class NativeFunctions {
  @Native<IntegerOrDouble Function(Pointer<Uint8>)>(
    symbol: 'ReturnUnionFromPointer',
    isLeaf: true,
  )
  external static IntegerOrDouble union(Pointer<Uint8> value);
}

void checkSmall(Small result, int expected) {
  Expect.equals(expected.toDouble(), result.a);
  Expect.equals(42, result.b);
}

void checkLarge(Large result, int expected) {
  Expect.equals(expected, result.a);
  Expect.equals(42, result.b);
  Expect.equals(43, result.c);
}

void main() {
  dlopenGlobalPlatformSpecific('ffi_test_functions');
  for (var i = 0; i < 100; i++) {
    testReturns();
  }
}

void testReturns() {
  final data = Uint8List.fromList([9, 10, 11]);
  checkSmall(small(data.address), 9);
  // The native functions increment the input to prove they actually ran.
  Expect.equals(10, data[0]);
  checkLarge(large(data.address), 10);
  Expect.equals(11, data[0]);
  // The union is only returned through .address calls, so its constructor
  // must survive AOT tree shaking without an ordinary Pointer call.
  Expect.equals(11, NativeFunctions.union(data.address).integer);
  Expect.equals(12, data[0]);

  final view = Uint8List.sublistView(data, 1);
  checkSmall(small(view.address), 10);
  Expect.equals(11, data[1]);
  checkLarge(large(view.address), 11);
  Expect.equals(12, data[1]);

  // Element addresses use the compound/offset specialization.
  checkSmall(small(data[2].address), 11);
  checkLarge(large(data[2].address), 12);
  Expect.equals(13, data[2]);
  checkSmall(small(data.address.cast()), 12);
  Expect.equals(13, data[0]);

  final input = Struct.create<Input>();
  input.value = 20;
  checkSmall(small(input.address.cast()), 20);
  checkLarge(large(input.value.address), 21);
  Expect.equals(22, input.value);
  input.values[1] = 30;
  checkSmall(small(input.values[1].address), 30);
  checkLarge(large(input.values[1].address), 31);
  Expect.equals(32, input.values[1]);

  // Keep exercising the original wrappers with ordinary Pointer arguments.
  final pointer = calloc<Uint8>()..value = 40;
  try {
    checkSmall(small(pointer), 40);
    checkLarge(large(pointer), 41);
    Expect.equals(42, pointer.value);
  } finally {
    calloc.free(pointer);
  }
}
