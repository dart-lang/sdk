// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to hit an assertion in the
// container tracer visitor in the presence of cascaded calls.

import "package:expect/expect.dart";

class A {
  var foo;

  add(list) {
    foo = list;
    list.add(2.5);
    return this;
  }

  call(arg) => arg;
}

main() {
  var foo = <dynamic>[42, 0];
  var a = new A();
  var bar = a..add(foo)('WHAT');
  a..foo[0] = new Object();
  Expect.throwsNoSuchMethodError(() => foo[0] + 2);
}
