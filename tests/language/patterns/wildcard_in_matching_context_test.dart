// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that no errors are generated if a wildcard pattern appears inside a
// matching context.

import "package:expect/expect.dart";

void bareUnderscore() {
  if ([0] case [_]) {
    // OK
  } else {
    Expect.fail('Should have matched');
  }
}

void usingFinal() {
  if ([0] case [final _]) {
    // OK
  } else {
    Expect.fail('Should have matched');
  }
}

void usingFinalAndType() {
  if ([0] case [final int _]) {
    // OK
  } else {
    Expect.fail('Should have matched');
  }
}

void usingType() {
  if ([0] case [int _]) {
    // OK
  } else {
    Expect.fail('Should have matched');
  }
}

void usingVar() {
  if ([0] case [var _]) {
    // OK
  } else {
    Expect.fail('Should have matched');
  }
}

main() {
  bareUnderscore();
  usingFinal();
  usingFinalAndType();
  usingType();
  usingVar();
}
