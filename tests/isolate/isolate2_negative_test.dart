// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that exceptions in other isolates bring down
// the program.

#library('Isolate2NegativeTest');
#import('dart:isolate');
#import('../../lib/unittest/unittest.dart');

void entry() {
  throw "foo";
}

main() {
  test("catch exception from other isolate", () {
    spawnFunction(entry);
  });
}
