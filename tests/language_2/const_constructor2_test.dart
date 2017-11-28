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
  const factory C.redirecting(B<U> a) = D<U>;
}

class D<U> extends C<U> {
  const D(B<U> b) : super(b);
}

class E {
  const factory E.redirecting1(var a) = F<int>;
  const factory E.redirecting2(var a) = F<int>.redirecting;
  const factory E.redirecting3(var a) = F<double>.redirecting;
}

class F<V> implements E {
  final V field;

  const F(this.field);
  const factory F.redirecting(V field) = G<V>;
}

class G<W> implements F<W> {
  final W field;
  const G(W field) : this.field = field;
}

main() {
  const A<int> a = const B<int>();

  const C(a); //# 01: ok
  const C.optional(a); //# 02: ok
  const C.named(a: a); //# 03: ok
  const C.untyped(a); //# 04: ok

  // Can't infer type argument U for C since a has type A and the argument has
  // type B<U>, not A<U>. So tries to assign A<int> to B<dynamic> which fails.
  const C.subtyped(a); //# 05: compile-time error
  const C.redirecting(a); //# 06: compile-time error

  const C<int>(a); //# 07: ok
  const C<int>.optional(a); //# 08: ok
  const C<int>.named(a: a); //# 09: ok
  const C<int>.untyped(a); //# 10: ok
  const C<int>.subtyped(a); //# 11: ok
  const C<int>.redirecting(a); //# 12: ok

  const C<double>(a); //# 13: compile-time error
  const C<double>.optional(a); //# 14: compile-time error
  const C<double>.named(a: a); //# 15: compile-time error
  const C<double>.untyped(a); //# 16: compile-time error
  const C<double>.subtyped(a); //# 17: compile-time error
  const C<double>.redirecting(a); //# 18: compile-time error

  const E.redirecting1(0); //# 19: ok
  const E.redirecting1(''); //# 20: compile-time error
  const E.redirecting2(0); //# 21: ok
  const E.redirecting2(''); //# 22: compile-time error
  const E.redirecting3(0.0); //# 23: ok
  const E.redirecting3(''); //# 24: compile-time error
}
