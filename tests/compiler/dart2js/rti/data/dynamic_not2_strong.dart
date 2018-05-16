// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*strong.class: A:explicit=[A]*/
class A {
  /*element: A.instanceMethod:deps=[B.instanceMethod]*/
  instanceMethod<T>(t) => t;
}

class B {
  /*element: B.instanceMethod:*/
  instanceMethod<T>(A a, t) => a.instanceMethod<T>(t);
}

main() {
  var b = new B();
  b.instanceMethod<int>(new A(), 0);
}
