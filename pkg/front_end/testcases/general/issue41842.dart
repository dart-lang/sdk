// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './issue41842_lib.dart' as lib;

class A<T> {
  A();
  factory A.foo1(int x) = B<T>; // Ok.
  factory A.foo2(int x) = B.foo<T>; // Error.
  factory A.foo3(int x) = B<T>.foo; // Ok.
  factory A.foo5(int x) = B.bar<T>; // Error.
  factory A.foo6(int x) = B<T>.bar; // Ok.
  factory A.foo4(int x) = lib.Foo<T>; // Ok.
  factory A.foo7(int x) = lib.Bar<T>; // Ok.
  factory A.foo8(int x) = lib.Foo.foo<T>; // Error. Not allowed by parser.
  factory A.foo9(int x) = lib.Foo<T>.foo; // Ok.
  factory A.foo10(int x) = lib.Foo.bar<T>; // Error. Not allowed by parser.
  factory A.foo11(int x) = lib.Foo<T>.bar; // Ok.
  factory A.foo12(int x) = B<T>.foo<T>; // Error. Not allowed by parser.
  factory A.foo13(int x) = B<T>.bar<T>; // Error. Not allowed by parser.
}

class B<T> extends A<T> {
  B(int x);
  B.foo(int x);
  factory B.bar(int x) => B.foo(x);
}

void main() {
  new B.foo<int>(24); // Error.
}
