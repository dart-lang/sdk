// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/36590.
//
// This test verifies that compiler does not crash if OSR occurs at
// CheckStack bytecode instruction which is not at the beginning of a join
// block in bytecode (if the end of the "loop" body is unreachable and hence
// there is no backward jump).
//
// VMOptions=--deterministic

var var6 = [1, 2, 3];

void bar() {}

var cond_true = true;

void foo() {
  for (int i = 0; i < 9995; ++i) {
    var6[0] += 1;
  }
  if (cond_true) {
    var6[0] += 1;
    for (var loc1 in var6) {
      break;
    }
  }
  if (cond_true) {
    var6[0] += 1;
    for (var loc1 in var6) {
      break;
    }
  }
  if (cond_true) {
    var6[0] += 1;
    for (var loc1 in var6) {
      break;
    }
  }
  if (cond_true) {
    var6[0] += 1;
    for (var loc1 in var6) {
      break;
    }
  }
  if (cond_true) {
    var6[0] += 1;
    for (var loc1 in var6) {
      break;
    }
  }
}

main() {
  foo();
}
