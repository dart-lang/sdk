// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We used to have an issue in dart2js where calling a top-level or
// static field wouldn't register the 'call' selector correctly.
var caller = new Caller();

class Caller {
  call(a, b) => a + b;
}

main() {
  if (caller(42, 87) != 42 + 87) {
    throw 'unexpected result';
  }
}
