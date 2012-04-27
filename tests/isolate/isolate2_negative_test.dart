// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that exceptions in other isolates bring down
// the program.

#library('Isolate2NegativeTest');
#import('dart:isolate');
#import('../../lib/unittest/unittest.dart');

class Isolate2NegativeTest extends Isolate {
  Isolate2NegativeTest() : super();

  void main() {
    throw "foo";
  }
}

main() {
  test("catch exception from other isolate", () {
    // Calling 'then' ensures the test framework is aware that there is a
    // pending callback, so it can fail quickly.
    new Isolate2NegativeTest().spawn().then(expectAsync1((a) => null));
  });
}
