// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 12118 which caused a crash in dart2js.

const X = 42;

class A {
  final x;
  A({this.x: X});
}

class B extends A {}

void main() {
  if (new B().x != 42) {
    throw 'Test failed';
  }
}
