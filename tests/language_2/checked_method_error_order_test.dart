// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

class Bar {
  foo({int i, String a}) {
    print(i);
    print(a);
  }
}

main() {
  bool checkedMode = false;
  assert((checkedMode = true));
  // Test that in checked mode, we are checking the type of optional parameters
  // in the correct order (aka, don't check the type of parameter 'a' first).
  if (checkedMode) {
    dynamic x = 'e';
    dynamic y = 3;
    Expect.throws(
        () => new Bar().foo(i: x, a: y),
        (e) =>
            e is TypeError &&
            e.message.toString().contains("is not a subtype of type 'int'"));
  }
}
