// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subclass usage for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

typedef CovFunction<T> = T Function();
typedef ContraFunction<T> = void Function(T);

class LegacyCovariant<T> {}
class Covariant<out T> {}
class Contravariant<in T> {}
mixin MLegacyCovariant<T> {}
mixin MCovariant<out T> {}

class A<out T> extends LegacyCovariant<T> {}
class B<out T> implements LegacyCovariant<T> {}
class C<out T> with MLegacyCovariant<T> {}

class D<out T> extends Covariant<T> {}
class E<out T> implements Covariant<T> {}
class F<out T> with MCovariant<T> {}

class G<out T> extends Covariant<Covariant<T>> {}
class H<out T> extends Contravariant<Contravariant<T>> {}

class I<out T> extends Covariant<CovFunction<T>> {}
class J<out T> extends Covariant<ContraFunction<ContraFunction<T>>> {}
class K<out T> extends Contravariant<CovFunction<Contravariant<T>>> {}

class L<out T> extends Covariant<CovFunction<Covariant<T>>> {}

class M<out T> extends Covariant<Covariant<Covariant<T>>> {}

class N<out T> = Covariant<T> with MCovariant<T>;
class O<out T> = Contravariant<Contravariant<T>> with MCovariant<T>;
class P<out T> = Covariant<T> with MCovariant<Covariant<T>>;

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
}
