// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A {
  late B<int> b;
}

class B<T> {
  B(T x);
}

var t1 = new A()..b = new B(1);
var t2 = <B<int>>[new B(2)];

main() {}
