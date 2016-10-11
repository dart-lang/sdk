// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that engines will not infer that [a] is always of type int.

var a = foo();

foo() {
  () => 42;
  if (true) throw 'Sorry';
  return 42;
}

main() {
  try {
    a;
  } catch (e) {
    // Ignore.
  }
  if (a is num) throw 'Test failed';
}
