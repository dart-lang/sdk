// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for
// https://code.google.com/p/dart/issues/detail?id=9090.
// Parameters used to be passed in the wrong order in a constructor in the
// presence of parameter checks.

import 'package:expect/expect.dart';

class A {
  A(expect1, expect2, value1, value2, {layers, serviceUrl}) {
    Expect.equals(expect1, ?layers);
    Expect.equals(expect2, ?serviceUrl);
    Expect.equals(value1, layers);
    Expect.equals(value2, serviceUrl);
  }
}

main() {
  new A(false, false, null, null);
  new A(true, false, 42, null, layers: 42);
  new A(false, true, null, 43, serviceUrl: 43);
  new A(true, true, 42, 43, layers: 42, serviceUrl: 43);
  new A(true, true, 42, 43, serviceUrl: 43, layers: 42);
}
