// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends A<X>?> {}

class D<X extends num> {}

extension Extension1<X extends A<X>?> on A<X> {
  void method1<Y extends A<Y>?>(A<Y> a, A<A<Null>>? b) {
    A<Y>? c;
    A<A<Null>>? d;
  }

  void method2<Y extends String>(D<Y> a, D<String>? b) {
    D<Y>? c;
    D<String>? d;
  }
}

extension ext2<X extends A<Null>?> on A<X> {}

class B<X extends A<Null>?> implements A<X> {
  void method1<Y extends A<Null>?>(A<Y> a, A<A<Null>>? b) {
    A<Y>? c;
    A<A<Null>>? d;
  }

  void method2<Y extends String>(D<Y> a, D<String>? b) {
    D<Y>? c;
    D<String>? d;
  }
}

class C {
  factory C.redirect(A<A<Null>>? a) = C.internal;

  factory C.fact(A<A<Null>>? a) {
    A<A<Null>>? b;
    D<String>? c;
    return new C.internal(a);
  }

  C.internal(_) {
    A<A<Null>>? a;
    D<String>? b;
  }
}

test() {
  var a = new A<Null>();
}

main() {}
