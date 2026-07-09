// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subclass usage for the `inout` variance modifier.

// SharedOptions=--enable-experiment=variance

typedef CovFunction<T> = T Function();
typedef ContraFunction<T> = void Function(T);
typedef InvFunction<T> = T Function(T);

class LegacyCovariant<T> {}
class Invariant<inout T>{}
class Covariant<out T> {}
class Contravariant<in T> {}
mixin MLegacyCovariant<T> {}
mixin MContravariant<in T> {}
mixin MCovariant<out T> {}
mixin MInvariant<inout T> {}

class A<inout T> extends LegacyCovariant<T> {}
class B<inout T> extends Invariant<T> {}
class C<inout T> extends Covariant<T> {}
class D<inout T> extends Contravariant<T> {}

class E<inout T> implements LegacyCovariant<T> {}
class F<inout T> implements Invariant<T> {}
class G<inout T> implements Covariant<T> {}
class H<inout T> implements Contravariant<T> {}

class I<inout T> with MLegacyCovariant<T> {}
class J<inout T> with MInvariant<T> {}
class K<inout T> with MCovariant<T> {}
class L<inout T> with MContravariant<T> {}

class M<inout T> extends Covariant<Contravariant<T>> {}
class N<inout T> extends Contravariant<Covariant<T>> {}
class O<inout T> extends Covariant<ContraFunction<T>> {}
class P<inout T> extends Covariant<ContraFunction<CovFunction<T>>> {}
class Q<inout T> extends Covariant<CovFunction<ContraFunction<T>>> {}
class R<inout T> extends Covariant<ContraFunction<Covariant<T>>> {}
class S<inout T> extends Contravariant<Contravariant<Contravariant<T>>> {}

class T<inout X> extends Covariant<Covariant<X>> {}
class U<inout T> extends Contravariant<Contravariant<T>> {}
class V<inout T> extends Covariant<CovFunction<T>> {}
class W<inout T> extends Covariant<ContraFunction<ContraFunction<T>>> {}
class X<inout T> extends Contravariant<CovFunction<Contravariant<T>>> {}
class Y<inout T> extends Covariant<CovFunction<Covariant<T>>> {}
class Z<inout T> extends Covariant<Covariant<Covariant<T>>> {}

class AA<inout T> extends Covariant<InvFunction<T>> {}

class AB<inout T> = Invariant<T> with MInvariant<T>;
class AC<inout T> = Covariant<T> with MCovariant<T>;
class AD<inout T> = Contravariant<T> with MContravariant<T>;

main() {
  A<num> a = A();
  B<num> b = B();
  C<num> c = C();
  D<num> d = D();
  E<num> e = E();
  F<num> f = F();
  G<num> g = G();
  H<num> h = H();
  I<num> i = I();
  J<num> j = J();
  K<num> k = K();
  L<num> l = L();
  M<num> m = M();
  N<num> n = N();
  O<num> o = O();
  P<num> p = P();
  Q<num> q = Q();
  R<num> r = R();
  S<num> s = S();
  T<num> t = T();
  U<num> u = U();
  V<num> v = V();
  W<num> w = W();
  X<num> x = X();
  Y<num> y = Y();
  Z<num> z = Z();
  AA<num> aa = AA();
  AB<num> ab = AB();
  AC<num> ac = AC();
  AD<num> ad = AD();
}
