// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that exceptions in other isolates bring down
// the program.

#library('Isolate2NegativeTest');
#import('dart:isolate');
#import('TestFramework.dart');

class Isolate2NegativeTest extends Isolate {
  Isolate2NegativeTest() : super();

  void main() {
    throw "foo";
  }
}

void test(TestExpectation expect) {
  // We will never call 'expect.succeeded'. This test fails with a timeout.
  expect.completes(new Isolate2NegativeTest().spawn());
}

main() {
  runTests([test]);
}
