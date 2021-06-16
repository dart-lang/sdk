// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi primitive data pointers.
//
// SharedObjects=ffi_test_functions

// @dart = 2.9

import 'dart:ffi';

import "package:expect/expect.dart";

void main() {
  testPointer();
  testStruct();
}

Expando<int> expando = Expando('myExpando');

void testPointer() {
  final pointer = Pointer<Int8>.fromAddress(0xdeadbeef);
  Expect.throws(() {
    expando[pointer];
  });
  Expect.throws(() {
    expando[pointer] = 1234;
  });
}

class MyStruct extends Struct {
  Pointer notEmpty;
}

void testStruct() {
  final pointer = Pointer<MyStruct>.fromAddress(0xdeadbeef);
  final struct = pointer.ref;
  Expect.throws(() {
    expando[struct];
  });
  Expect.throws(() {
    expando[struct] = 1234;
  });
}
