// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no-enable_asserts --enable_type_checks

// Ensure that enabling of type checks does not automatically enable asserts.

main() {
  assert(false);
  try {
    int i = "String";
    throw "FAIL";
  } on TypeError catch (e) {
    print("PASS");
  }
}
