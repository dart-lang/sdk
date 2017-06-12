// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for issue http://dartbug.com/6903: dart2js used to
// not generate an interceptor forwarder when a getter call and a
// method call on an intercepted method were both used.

class A {
  get iterator => () => 499;
}

main() {
  var a = [
    new A(),
    [1, 1]
  ];
  Expect.equals(499, a[0].iterator());
  Expect.equals(499, (a[0].iterator)());
  for (var i in a[1]) {
    Expect.equals(1, i);
  }
}
