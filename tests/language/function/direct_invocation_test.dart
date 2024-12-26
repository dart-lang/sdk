// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test using TFA's direct-call metadata in function invocations.

import "package:expect/expect.dart";

int f(int x, [int? y]) => x;

// Calls `f` directly.
int test1(int cb(int a)) => cb(1);

class A {
  int f(int x, [int? y]) => x;
}

// Calls `A.f` directly.
int test2(int cb(int a)) => cb(2);

class B {
  int nested() {
    int cb1(int x, [int? y]) => x;
    return test3(cb1);
  }
}

// Calls the nested closure `cb1` directly.
int test3(int cb(int a)) => cb(3);

void main() {
  Expect.equals(test1(f), 1);
  Expect.equals(test2(A().f), 2);
  Expect.equals(B().nested(), 3);
}
