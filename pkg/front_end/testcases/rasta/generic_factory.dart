// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class C1 {}

class C2 {}

class C3 {}

class A<T> {
  A.internal();

  factory A.a() = B<T>.a;
  factory A.b() = B<C1>.a;
  factory A.c() = Missing;
}

class B<S> extends A<S> {
  B.internal() : super.internal();

  factory B.a() = C<S>;
  factory B.b() = C<C2>;
}

class C<U> extends B<U> {
  C() : super.internal();
}

main() {
  new A<C3>.a();
  new A<C3>.b();
  new B<C3>.a();
  new B<C3>.b();
  new A<C3>.c();
}
