// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/21166/
// Fails when compiling with --checked.

var a = [];

void doStuff() {
  if (a.length) {
    // This triggers a TypeConversion to bool in checked mode.
    var element = a[0]; // This triggers a bounds check but a.length will have
    a.remove(element); // type [empty].
  }
}

main() {
  a.add(1);
  a.add(2);
  try {
    doStuff(); // This is expected to fail but not crash the compiler.
  } catch (_) {}
}
