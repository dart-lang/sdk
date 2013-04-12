// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to not compile null methods
// in the presence of typed selectors.

import "package:expect/expect.dart";

class C {
  foo(s) {
    return s.hashCode;
  }
}

main() {
  var c = new C();
  Expect.isNotNull(c.foo('foo'));
  Expect.isNotNull(c.foo(null));
}
