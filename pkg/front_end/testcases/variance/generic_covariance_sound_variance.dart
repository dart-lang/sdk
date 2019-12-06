// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef ContraFunction<T> = void Function(T);
typedef InvFunction<T> = T Function(T);
class Contravariant<in T> {}
class Invariant<inout T> {}

class A<in T, out U, V> {
  final void Function(T) field = null;
  void method(T t, void Function(U) u, V v) {}
  void method2(T x, [T y]) {}
  void set x(T t) {}
  Map<U, Contravariant<V>> get mapContra => new Map<U, Contravariant<V>>();
  Map<U, ContraFunction<V>> get mapContraFn => new Map<U, ContraFunction<V>>();
  Map<U, Invariant<V>> get mapInv => new Map<U, Invariant<V>>();
  Map<U, InvFunction<V>> get mapInvFn => new Map<U, InvFunction<V>>();
}

class B<inout T> {
  T x;
  T method(T x) => x;
  void set y(T x) {}
}

class C<in T> {
  final void Function(T) field = null;
  void method(T x, [T y]) {}
  void set x(T t) {}
}

abstract class D<T> {
  int method(T x);
}

class E<inout T> {
  final void Function(T) f;
  E(this.f);
  int method(T x) {
    f(x);
  }
}

class F<inout T> extends E<T> implements D<T> {
  F(void Function(T) f) : super(f);
}

class NoSuchMethod<inout T> implements B<T> {
  noSuchMethod(_) => 3;
}

main() {
  A<int, num, String> a = new A();
  expect(null, a.field);
  a.method(3, (num) {}, "test");
  a.method2(3);
  a.x = 3;
  Map<num, Contravariant<String>> mapContra = a.mapContra;
  Map<num, ContraFunction<String>> mapContraFn = a.mapContraFn;
  Map<num, Invariant<String>> mapInv = a.mapInv;
  Map<num, InvFunction<String>> mapInvFn = a.mapInvFn;

  B<int> b = new B();
  b.x = 3;
  expect(3, b.x);
  expect(3, b.method(3));
  b.y = 3;

  C<int> c = new C();
  expect(null, c.field);
  c.method(3, 2);
  c.x = 3;

  D<Object> d = new F<String>((String s) {});
  d.method("test");

  NoSuchMethod<num> nsm = new NoSuchMethod<num>();
  expect(3, nsm.method(3));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}
