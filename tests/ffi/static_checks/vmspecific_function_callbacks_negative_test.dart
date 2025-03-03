// Copyright (c) 2019, the Dart project authors.  
// Please see the AUTHORS file for details. 
// All rights reserved. Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with callbacks.

// Formatting can break multitests, so don't format them.
// dart format off

import 'dart:ffi';

final testLibrary = DynamicLibrary.process();

double testExceptionalReturn() {
  // [cfe] Expected: exceptional return must be a valid return type
  Pointer.fromFunction<Double Function()>(returnVoid, 0.0); 

  // [cfe] Expected: void functions do not require exceptional return
  Pointer.fromFunction<Void Function()>(returnVoid); 

  // [cfe] Expected: incorrect type for exceptional return
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, 0.0); 

  return 0.0; // not used
}

void returnVoid() {}

void main() {
  testExceptionalReturn();
}
