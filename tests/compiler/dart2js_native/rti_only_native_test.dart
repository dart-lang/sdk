// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for a bug that was caused by uninstantiated classes being
// added to emitted classes by runtime-type system.
// See my explanation in https://codereview.chromium.org/14018036/.
//   -- ahe

import "dart:_js_helper";

@Native("A")
class A {
  // Just making sure the field name is unique.
  var rti_only_native_test_field;
}

typedef fisk();

main() {
  void foo(A x) {}
  var map = { 'a': 0, 'b': main };
  try {
    map.values.forEach((x) => x.rti_only_native_test_field);
  } finally {
    print(main is fisk);
    return;
  }
}
