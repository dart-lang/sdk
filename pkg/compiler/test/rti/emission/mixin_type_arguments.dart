// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*class: A:typeArgument*/
class A {}

/*class: B:typeArgument*/
class B {}

/*class: C:typeArgument*/
class C {}

/*class: D:typeArgument*/
class D {}

/*class: E:typeArgument*/
class E {}

/*class: F:typeArgument*/
class F {}

/*class: M1:checks=[]*/
class M1<Tm1> {
  m1() => "M1<$Tm1>";
}

/*class: M2:checks=[]*/
class M2<Tm2> {
  m2() => "M2<$Tm2>";
}

/*class: M3:checks=[]*/
class M3<Tm3> {
  m3() => "M3<$Tm3>";
}

/*class: M4:checks=[]*/
class M4<Tm4> {
  m4() => "M4<$Tm4>";
}

/*class: M5:checks=[]*/
class M5<Tm5> {
  m5() => "M5<$Tm5>";
}

/*class: C1:checks=[],instance*/
class C1 = Object with M1, M2<A>, M3, M4<B>, M5<C>;

/*class: C2:checks=[],instance*/
class C2 = Object with M1<A>, M2<B>, M3<C>, M4<D>, M5<E>;

/*class: C3:checks=[],instance*/
class C3<T> = Object with M1<A>, M2<T>, M3, M4, M5<B>;

/*class: C4:checks=[],instance*/
class C4 extends Object with M1, M2<A>, M3, M4<B>, M5<C> {}

/*class: C5:checks=[],instance*/
class C5 extends Object with M1<A>, M2<B>, M3<C>, M4<D>, M5<E> {}

/*class: C6:checks=[],instance*/
class C6<T> extends Object with M1<A>, M2<T>, M3, M4, M5<B> {}

/*class: C7:checks=[],instance*/
class C7 = Object with M1<A>, M2<A>, M3<A>, M4<A>, M5<A>;

/*class: C8:checks=[],instance*/
class C8 extends Object with M1<A>, M2<A>, M3<A>, M4<A>, M5<A> {}

/*class: C9:checks=[],instance*/
class C9 = Object
    with M1<List<A>>, M2<List<A>>, M3<List<A>>, M4<List<A>>, M5<List<A>>;

/*class: CA:checks=[],instance*/
class CA extends Object
    with M1<List<A>>, M2<List<A>>, M3<List<A>>, M4<List<A>>, M5<List<A>> {}

trace(x) => "${x.m1()}, ${x.m2()}, ${x.m3()}, ${x.m4()}, ${x.m5()}";

main() {
  makeLive("M1<dynamic>, M2<A>, M3<dynamic>, M4<B>, M5<C>" == trace(new C1()));
  makeLive("M1<A>, M2<B>, M3<C>, M4<D>, M5<E>" == trace(new C2()));
  makeLive(
      "M1<A>, M2<dynamic>, M3<dynamic>, M4<dynamic>, M5<B>" == trace(new C3()));
  makeLive(
      "M1<A>, M2<F>, M3<dynamic>, M4<dynamic>, M5<B>" == trace(new C3<F>()));
  makeLive("M1<dynamic>, M2<A>, M3<dynamic>, M4<B>, M5<C>" == trace(new C4()));
  makeLive("M1<A>, M2<B>, M3<C>, M4<D>, M5<E>" == trace(new C5()));
  makeLive(
      "M1<A>, M2<dynamic>, M3<dynamic>, M4<dynamic>, M5<B>" == trace(new C6()));
  makeLive(
      "M1<A>, M2<F>, M3<dynamic>, M4<dynamic>, M5<B>" == trace(new C6<F>()));
  makeLive("M1<A>, M2<A>, M3<A>, M4<A>, M5<A>" == trace(new C7()));
  makeLive("M1<A>, M2<A>, M3<A>, M4<A>, M5<A>" == trace(new C8()));
  makeLive("M1<List<A>>, M2<List<A>>, M3<List<A>>, M4<List<A>>, M5<List<A>>" ==
      trace(new C9()));
  makeLive("M1<List<A>>, M2<List<A>>, M3<List<A>>, M4<List<A>>, M5<List<A>>" ==
      trace(new CA()));
}
