// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that vm:align-loops pragma works as expected.
//
// * This test should run without crashing in AOT mode.
// * `align_loops_verify_alignment_test.dart` will AOT compile this test
//   and then verify that [alignedFunction1] and [alignedFunction2] are
//   aligned.

import 'dart:typed_data';

// Having a static call to this function verifies that relocation works
// as expected even when caller needs to be aligned.
@pragma('vm:never-inline')
void printOk() {
  print("ok");
}

@pragma('vm:never-inline')
int foo(Uint8List list) {
  printOk();
  var result = 0;
  for (var i = 0; i < list.length; i++) {
    result ^= list[i];
  }
  printOk();
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:align-loops')
int alignedFunction1(Uint8List list) {
  printOk();
  var result = 0;
  for (var i = 0; i < list.length; i++) {
    result ^= list[i];
  }
  printOk();
  return result;
}

@pragma('vm:never-inline')
int baz(Uint8List list) {
  printOk();
  var result = 1;
  for (var i = 0; i < list.length; i++) {
    result ^= list[i];
  }
  printOk();
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:align-loops')
int alignedFunction2(Uint8List list) {
  printOk();
  var result = 2;
  for (var i = 0; i < list.length; i++) {
    result ^= list[i];
  }
  printOk();
  return result;
}

void main(List<String> args) {
  final v = Uint8List(10);
  foo(v);
  alignedFunction1(v);
  baz(v);
  alignedFunction2(v);
}
