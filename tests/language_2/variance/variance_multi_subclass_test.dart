// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests variance usage multiple type parameters.

// SharedOptions=--enable-experiment=variance

typedef CovFunction<T> = T Function();
typedef ContraFunction<T> = void Function(T);

class Covariant<out T> {}
class Contravariant<in T> {}

class A<in T, out U> {}
class B<in T, out U, inout V> {}

class C<inout T, in U, out V> extends A<T, V> {}
class D<inout T, in U, out V> extends B<U, V, T> {}
class E<inout T, in U, out V> extends B<T, T, T> {}

class F<inout T, in U, out V> extends A<Contravariant<V>, Contravariant<U>> {}
class G<inout T, in U, out V> extends A<Covariant<Contravariant<V>>, Contravariant<Covariant<U>>> {}
class H<inout T, in U, out V> extends B<Covariant<U>, Covariant<V>, Covariant<T>> {}

class I<inout T, in U, out V> extends A<ContraFunction<V>, ContraFunction<U>> {}
class J<inout T, in U, out V> extends A<CovFunction<ContraFunction<V>>, ContraFunction<CovFunction<U>>> {}
class K<inout T, in U, out V> extends B<CovFunction<U>, CovFunction<V>, CovFunction<T>> {}

main() {
  A<num, bool> a = A();
  B<num, bool, String> b = B();
  C<num, bool, String> c = C();
  D<num, bool, String> d = D();
  E<num, bool, String> e = E();
  F<num, bool, String> f = F();
  G<num, bool, String> g = G();
  H<num, bool, String> h = H();
  I<num, bool, String> i = I();
  J<num, bool, String> j = J();
  K<num, bool, String> k = K();
}
