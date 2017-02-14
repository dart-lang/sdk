// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 14348.

class A<T> {
  const A();
}

class B<S> extends A<S> {
  const B();
}

class C<U> {
  final A<U> a;

  const C(A<U> this.a);
  const C.optional([A<U> this.a]);
  const C.named({A<U> this.a});
  const C.untyped(this.a);
  const C.subtyped(B<U> this.a);
  const factory C.redirecting(B<U> a) = D;
}

class D extends C {
  const D(B b) : super(b);
}

class E {
  const factory E.redirecting1(var a) = F<int>;
  const factory E.redirecting2(var a) = F<int>.redirecting;
  const factory E.redirecting3(var a) = F<double>.redirecting;
}

class F<V> implements E {
  final V field;

  const F(this.field);
  const factory F.redirecting(V field) = G<int>;
}

class G<W> implements F {
  final W field;
  const G(field) : this.field = field;
}

main() {
  const A<int> a = const B<int>();

  const C c1 = const C(a); /// 01: ok
  const C c2 = const C.optional(a); /// 02: ok
  const C c3 = const C.named(a: a); /// 03: ok
  const C c4 = const C.untyped(a); /// 04: ok
  const C c5 = const C.subtyped(a); /// 05: ok
  const C c5m = const C.redirecting(a); /// 06: ok

  const C c6 = const C<int>(a); /// 07: ok
  const C c7 = const C<int>.optional(a); /// 08: ok
  const C c8 = const C<int>.named(a: a); /// 09: ok
  const C c9 = const C<int>.untyped(a); /// 10: ok
  const C c10 = const C<int>.subtyped(a); /// 11: ok
  const C c10m = const C<int>.redirecting(a); /// 12: ok

  const C c11 = const C<double>(a); /// 13: static type warning, checked mode compile-time error
  const C c12 = const C<double>.optional(a); /// 14: static type warning, checked mode compile-time error
  const C c13 = const C<double>.named(a: a); /// 15: static type warning, checked mode compile-time error
  const C c14 = const C<double>.untyped(a); /// 16: static type warning, checked mode compile-time error
  const C c15 = const C<double>.subtyped(a); /// 17: static type warning, checked mode compile-time error
  const C c15m = const C<double>.redirecting(a); /// 18: static type warning

  const E e1 = const E.redirecting1(0); /// 19: ok
  const E e2 = const E.redirecting1(''); /// 20: checked mode compile-time error
  const E e3 = const E.redirecting2(0); /// 21: ok
  const E e4 = const E.redirecting2(''); /// 22: checked mode compile-time error
  const E e5 = const E.redirecting3(0); /// 23: ok
  const E e6 = const E.redirecting3(''); /// 24: checked mode compile-time error
}