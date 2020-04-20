// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:deps=[B],exp,needsArgs*/
class A<T> {
  method1() => T;
}

/*class: B:needsArgs*/
class B<S> {
  method2() => new A<S>().method1();
}

main() {
  var b = new B<int>();
  b.method2();
}
