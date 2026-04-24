// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  A();
  factory A.foo(X x) = B;
}

class B<X> extends A<X> {
  B(X x);
}

class C<Y> {
  C();
  factory C.bar({required Y y}) = D;
}

class D<Y> extends C<Y> {
  D({required Y y});
}

test() {
  new A<int>.foo(0);
  new C<bool>.bar(y: false);
}
