// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that compiler infers correct type from call via getter.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

typedef String IntFunctionType(int _);

String functionImpl(int a) => 'abc';

class Box {
  IntFunctionType get fun => functionImpl;
}

var box = new Box();

void foo() {
  Expect.isFalse(box.fun(42) is Function);
  Expect.isTrue(box.fun(42) is String);
}

void main() {
  for (int i = 0; i < 20; ++i) {
    foo();
  }
}
