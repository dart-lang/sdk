// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final class Struct9Uint8 extends Struct {
  @Uint8()
  external int a0;

  @Uint8()
  external int a1;

  @Uint8()
  external int a2;

  @Uint8()
  external int a3;

  @Uint8()
  external int a4;

  @Uint8()
  external int a5;

  @Uint8()
  external int a6;

  @Uint8()
  external int a7;

  @Uint8()
  external int a8;

  String toString() =>
      '(${a0}, ${a1}, ${a2}, ${a3}, ${a4}, ${a5}, ${a6}, ${a7}, ${a8})';
}

typedef Callback = Struct9Uint8 Function(Pointer<Struct9Uint8> s9);
Struct9Uint8 returnStruct9(Pointer<Struct9Uint8> s9) {
  return s9.ref;
}

void main() {
  final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');
  final alloc = ffiTestFunctions.lookupFunction<
    Pointer<Struct9Uint8> Function(),
    Pointer<Struct9Uint8> Function()
  >('AllocStruct9Uint8');
  final sum = ffiTestFunctions
      .lookupFunction<Int64 Function(Struct9Uint8), int Function(Struct9Uint8)>(
        'SumStruct9Uint8',
      );
  final sumReturnStruct9 = ffiTestFunctions.lookupFunction<
    Int64 Function(Pointer<NativeFunction<Callback>>, Pointer<Struct9Uint8>),
    int Function(Pointer<NativeFunction<Callback>>, Pointer<Struct9Uint8>)
  >('SumReturnStruct9Uint8');
  final free = ffiTestFunctions.lookupFunction<
    Void Function(Pointer<Struct9Uint8>),
    void Function(Pointer<Struct9Uint8>)
  >('FreeStruct9Uint8');

  final array = alloc();
  Struct9Uint8 s9 = array[64 * 1024 - 1]; // At the end of a page.
  Pointer<Struct9Uint8> s9Pointer = array + 64 * 1024 - 1;

  s9.a0 = 1;
  s9.a1 = 2;
  s9.a2 = 3;
  s9.a3 = 4;
  s9.a4 = 5;
  s9.a5 = 6;
  s9.a6 = 7;
  s9.a7 = 8;
  s9.a8 = 9;

  // sizeof and alignof Struct9Uint8 are not a multiple of the word size. The
  // marshaller must not access the last member as a full word load, which could
  // fault.
  int result = sum(s9);
  Expect.equals(45, result);

  // Also on the return path.
  final callback = Pointer.fromFunction<Callback>(returnStruct9);
  result = sumReturnStruct9(callback, s9Pointer);
  Expect.equals(45, result);

  free(array);
}
