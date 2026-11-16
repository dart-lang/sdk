// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for data flow from try blocks into catch blocks
// (ExceptionalInput instructions and catch block parameters).

void foo() {}

void nestedTry(int a, int b) {
  var x = 0;
  try {
    x = a;
    try {
      foo();
      x = b;
      foo();
    } catch (e) {
      print(x);
      x = 3;
      foo();
    }
    foo();
  } catch (e) {
    print(x);
  }
}

void loopInTry(int n) {
  var i = 0;
  var d = 0.0;
  try {
    for (; i < n; ++i) {
      d += 1.5;
      foo();
    }
  } catch (e) {
    print(i);
    print(d);
  }
}

void catchParameterLiveAcrossAssignment(int a) {
  var x = a;
  try {
    foo();
    x = a + 1;
    foo();
  } catch (e) {
    final y = x;
    try {
      x = 2;
      foo();
    } catch (e) {
      print(x);
    }
    print(y);
  }
}

void main() {}
