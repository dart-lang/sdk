// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/109261.
// Varifies that uninitialized final late local variable can be correctly
// used in a catch block.

import 'package:expect/expect.dart';

void testWriteToUninitialized() {
  late final int computationResult;

  try {
    throw 'bye';
  } catch (e, s) {
    computationResult = 42;
  }

  Expect.equals(42, computationResult);
}

void testWriteToInitialized() {
  Expect.throws(() {
    late final int computationResult;

    try {
      computationResult = 10;
      throw 'bye';
    } catch (e, s) {
      computationResult = 42;
    }
  });
}

void testReadFromUninitialized() {
  Expect.throws(() {
    late final int computationResult;

    try {
      if (int.parse('1') == 2) {
        // Unreachable, just to avoid compile-time error "Late variable '...'
        // without initializer is definitely unassigned."
        computationResult = 10;
      }
      throw 'bye';
    } catch (e, s) {
      print(computationResult);
    }
  });
}

void testReadFromInitialized() {
  late final int computationResult;

  try {
    computationResult = 10;
    throw 'bye';
  } catch (e, s) {
    Expect.equals(10, computationResult);
  }
}

main() {
  testWriteToUninitialized();
  testWriteToInitialized();
  testReadFromUninitialized();
  testReadFromInitialized();
}
