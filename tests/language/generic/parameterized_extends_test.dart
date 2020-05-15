// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test verifying that generic extends are processed correctly.

import "package:expect/expect.dart";

class A<T> {}

class B<T1, T2 extends A<T1>> {}

class C<T1 extends A<T2>, T2> {}

main() {
  var a = new A<String>();
  var b = new B<String, A<String>>();
  var c = new C<A<String>, String>();
  Expect.isTrue(a is Object);
  Expect.isTrue(a is A<Object>);
  Expect.isTrue(a is A<String>);
  Expect.isTrue(a is! A<int>);
  Expect.isTrue(b is Object);
  Expect.isTrue(b is B<Object, A<Object>>);
  Expect.isTrue(b is B<String, A<String>>);
  Expect.isTrue(b is! B<int, A<int>>);
  Expect.isTrue(c is Object);
  Expect.isTrue(c is C<A<Object>, Object>);
  Expect.isTrue(c is C<A<String>, String>);
  Expect.isTrue(c is! C<A<int>, int>);
}
