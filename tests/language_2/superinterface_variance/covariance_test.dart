// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<X> = X Function();
typedef G<X> = void Function(void Function(X));

class A<X> {}

class B01<X> extends A<F<X>> {}

class B02<X> extends A<G<X>> {}

class B03<X> extends A<X Function()> {}

class B04<X> extends A<void Function(void Function(X))> {}

class B05<X> extends Object with A<F<X>> {}

class B06<X> extends Object with A<G<X>> {}

class B07<X> extends Object with A<X Function()> {}

class B08<X> extends Object with A<void Function(void Function(X))> {}

class B09<X> implements A<F<X>> {}

class B10<X> implements A<G<X>> {}

class B11<X> implements A<X Function()> {}

class B12<X> implements A<void Function(void Function(X))> {}

abstract class B13<X> extends A<A<F<X>>> {}

abstract class B14<X> extends A<A<G<X>>> {}

abstract class B15<X> extends A<A<X Function()>> {}

abstract class B16<X> extends A<A<void Function(void Function(X))>> {}

abstract class B17<X> extends Object with A<A<F<X>>> {}

abstract class B18<X> extends Object with A<A<G<X>>> {}

abstract class B19<X> extends Object with A<A<X Function()>> {}

abstract class B20<X> extends Object
    with A<A<void Function(void Function(X))>> {}

abstract class B21<X> implements A<A<F<X>>> {}

abstract class B22<X> implements A<A<G<X>>> {}

abstract class B23<X> implements A<A<X Function()>> {}

abstract class B24<X> implements A<A<void Function(void Function(X))>> {}

main() {
  A();

  B01();
  B02();
  B03();
  B04();
  B05();
  B06();
  B07();
  B08();
  B09();
  B10();
  B11();
  B12();

  B13 b13;
  B14 b14;
  B15 b15;
  B16 b16;
  B17 b17;
  B18 b18;
  B19 b19;
  B20 b20;
  B21 b21;
  B22 b22;
  B23 b23;
  B24 b24;
}
