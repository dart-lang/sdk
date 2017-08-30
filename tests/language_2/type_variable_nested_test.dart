// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for
// http://code.google.com/p/dart/issues/detail?id=9050.

import 'package:expect/expect.dart';

class A<T> {}

class B<T> {
  var _copy;
  B() {
    // We used to not register the dependency between List and B.
    _copy = new List<A<T>>();
  }
}

main() {
  var a = new B();
  Expect.isFalse(a._copy is List<int>);
  Expect.isTrue(a._copy is List<A>);
  Expect.isFalse(a._copy is List<A<int>>); //# 01: ok

  a = new B<String>();
  Expect.isFalse(a._copy is List<String>);
  Expect.isTrue(a._copy is List<A>);
  Expect.isTrue(a._copy is List<A<String>>);
  Expect.isTrue(a._copy is List<A<Object>>);
  Expect.isFalse(a._copy is List<A<int>>);
}
