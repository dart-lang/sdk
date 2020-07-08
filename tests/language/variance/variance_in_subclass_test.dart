// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests subclass usage for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

typedef CovFunction<T> = T Function();
typedef ContraFunction<T> = void Function(T);

class Covariant<out T> {}
class Contravariant<in T> {}
mixin MContravariant<in T> {}

class A<in T> extends Contravariant<T> {}
class B<in T> implements Contravariant<T> {}
class C<in T> with MContravariant<T> {}

class D<in T> extends Covariant<Contravariant<T>> {}
class E<in T> extends Contravariant<Covariant<T>> {}

class F<in T> extends Covariant<ContraFunction<T>> {}
class G<in T> extends Covariant<ContraFunction<CovFunction<T>>> {}
class H<in T> extends Covariant<CovFunction<ContraFunction<T>>> {}

class I<in T> extends Covariant<ContraFunction<Covariant<T>>> {}

class J<in T> extends Contravariant<Contravariant<Contravariant<T>>> {}

class K<in T> = Contravariant<T> with MContravariant<T>;
class L<in T> = Covariant<Contravariant<T>> with MContravariant<T>;
class M<in T> = Contravariant<T> with MContravariant<Covariant<T>>;

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
}
