// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that the full stacktrace in an error object matches the stacktrace
// handed to the catch clause.
library test.error_stacktrace;

import "package:expect/expect.dart";

class C {
  // operator*(o) is missing to trigger a noSuchMethodError when a C object
  // is used in the multiplication below.
}

bar(c) => c * 4;
foo(c) => bar(c);

main() {
  try {
    var a = foo(new C());
  } catch (e, s) {
    print(e);
    print("###");
    print(e.stackTrace);
    print("###");
    print(s);
    print("###");
    Expect.isTrue(e is NoSuchMethodError);
    Expect.stringEquals(e.stackTrace.toString(), s.toString());
  }
}
