// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to make sure dart2js does not try to use the same
// BoundClosureClass between an intercepted method and a
// non-intercepted method.

import "package:expect/expect.dart";

class A {
  // Make dart2js try to share a bound closure for [foo] with a bound
  // closure for [List.add], by having same number of arguments.
  foo(a) => a;
}

main() {
  var array = <dynamic>[[], new A()];
  var method = array[0].add;
  method(42);

  method = array[1].foo;
  Expect.equals(42, method(42));

  Expect.equals(1, array[0].length);
  Expect.isTrue(array[0].contains(42));
}
