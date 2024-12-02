// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart' show Expect;

@pragma("vm:entry-point") // Prevent obfuscation
class A {}

@pragma("vm:entry-point") // Prevent obfuscation
class B {}

@pragma("vm:entry-point") // Prevent obfuscation
class C {}

@pragma("vm:entry-point") // Prevent obfuscation
class D {}

@pragma("vm:entry-point") // Prevent obfuscation
class E {}

@pragma("vm:entry-point") // Prevent obfuscation
class F {}

@pragma("vm:entry-point") // Prevent obfuscation
mixin M1<Tm1> {
  Type m1() => M1<Tm1>;
}

@pragma("vm:entry-point") // Prevent obfuscation
mixin M2<Tm2> {
  Type m2() => M2<Tm2>;
}

@pragma("vm:entry-point") // Prevent obfuscation
mixin M3<Tm3> {
  Type m3() => M3<Tm3>;
}

@pragma("vm:entry-point") // Prevent obfuscation
mixin M4<Tm4> {
  Type m4() => M4<Tm4>;
}

@pragma("vm:entry-point") // Prevent obfuscation
mixin M5<Tm5> {
  Type m5() => M5<Tm5>;
}

class C1 = Object with M1, M2<A>, M3, M4<B>, M5<C>;

class C2 = Object with M1<A>, M2<B>, M3<C>, M4<D>, M5<E>;

class C3<T> = Object with M1<A>, M2<T>, M3, M4, M5<B>;

class C4 extends Object with M1, M2<A>, M3, M4<B>, M5<C> {}

class C5 extends Object with M1<A>, M2<B>, M3<C>, M4<D>, M5<E> {}

class C6<T> extends Object with M1<A>, M2<T>, M3, M4, M5<B> {}

class C7 = Object with M1<A>, M2<A>, M3<A>, M4<A>, M5<A>;

class C8 extends Object with M1<A>, M2<A>, M3<A>, M4<A>, M5<A> {}

class C9 = Object
    with M1<List<A>>, M2<List<A>>, M3<List<A>>, M4<List<A>>, M5<List<A>>;

class CA extends Object
    with M1<List<A>>, M2<List<A>>, M3<List<A>>, M4<List<A>>, M5<List<A>> {}

List<Type> trace(x) => [x.m1(), x.m2(), x.m3(), x.m4(), x.m5()];

main() {
  Expect.listEquals(
      [M1<dynamic>, M2<A>, M3<dynamic>, M4<B>, M5<C>], trace(new C1()));
  Expect.listEquals([M1<A>, M2<B>, M3<C>, M4<D>, M5<E>], trace(new C2()));
  Expect.listEquals(
      [M1<A>, M2<dynamic>, M3<dynamic>, M4<dynamic>, M5<B>], trace(new C3()));
  Expect.listEquals(
      [M1<A>, M2<F>, M3<dynamic>, M4<dynamic>, M5<B>], trace(new C3<F>()));
  Expect.listEquals(
      [M1<dynamic>, M2<A>, M3<dynamic>, M4<B>, M5<C>], trace(new C4()));
  Expect.listEquals([M1<A>, M2<B>, M3<C>, M4<D>, M5<E>], trace(new C5()));
  Expect.listEquals(
      [M1<A>, M2<dynamic>, M3<dynamic>, M4<dynamic>, M5<B>], trace(new C6()));
  Expect.listEquals(
      [M1<A>, M2<F>, M3<dynamic>, M4<dynamic>, M5<B>], trace(new C6<F>()));
  Expect.listEquals([M1<A>, M2<A>, M3<A>, M4<A>, M5<A>], trace(new C7()));
  Expect.listEquals([M1<A>, M2<A>, M3<A>, M4<A>, M5<A>], trace(new C8()));
  Expect.listEquals(
      [M1<List<A>>, M2<List<A>>, M3<List<A>>, M4<List<A>>, M5<List<A>>],
      trace(new C9()));
  Expect.listEquals(
      [M1<List<A>>, M2<List<A>>, M3<List<A>>, M4<List<A>>, M5<List<A>>],
      trace(new CA()));
}
