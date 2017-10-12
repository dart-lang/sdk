// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T extends num> {}

class B<T> {
  test() {
    new A() as A<T>; /*@compile-error=unspecified*/
  }
}

main() {
  var b = new B<String>();
  Expect.throws(() => b.test());
}
