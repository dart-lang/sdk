// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// In the classes below the function type is cloned when the anonymous mixin
// application is desugared into a named mixin application, in order to re-bind
// the type builders for its subterms.

// The case 'm1' covers function types with some missing parts.

class Am1<X, Y> {}

class Bm1<Z> extends Object with Am1<Function(int), Z> {}

class Cm1<Z> extends Object with Am1<Function(int x), Z> {}

class Dm1<Z> extends Object with Am1<int Function(), Z> {}

class Em1<Z> extends Object with Am1<Function(), Z> {}

// Compile-time error: Named parameters should have names.
class Fm1<Z> extends Object with Am1<Function({int}), Z> {}

class Gm1<Z> extends Object with Am1<Function({int x}), Z> {}

class Hm1<Z> extends Object with Am1<Function([int]), Z> {}

class Im1<Z> extends Object with Am1<Function([int x]), Z> {}

class Jm1<Z> extends Object with Am1<Function, Z> {}

class Km1<Z> extends Object with Am1<Function(Function Function), Z> {}

class Lm1<Z> extends Object
    with Am1<Function(Function Function() Function) Function(), Z> {}

class Mm1<Z> = Object with Am1<Function(int), Z>;

class Nm1<Z> = Object with Am1<Function(int x), Z>;

class Om1<Z> = Object with Am1<int Function(), Z>;

class Pm1<Z> = Object with Am1<Function(), Z>;

// Compile-time error: Named parameters should have names.
class Qm1<Z> = Object with Am1<Function({int}), Z>;

class Rm1<Z> = Object with Am1<Function({int x}), Z>;

class Sm1<Z> = Object with Am1<Function([int]), Z>;

class Tm1<Z> = Object with Am1<Function([int x]), Z>;

class Um1<Z> = Object with Am1<Function, Z>;

class Vm1<Z> = Object with Am1<Function(Function Function), Z>;

class Wm1<Z> = Object
    with Am1<Function(Function Function() Function) Function(), Z>;

// The case 'm2' covers function types with some missing parts that should be
// checked against a bound.

class Am2<X extends Function(), Y> {}

// Compile-time error: type argument is not a subtype.
class Bm2<Z> extends Object with Am2<Function(int), Z> {}

// Compile-time error: type argument is not a subtype.
class Cm2<Z> extends Object with Am2<Function(int x), Z> {}

class Dm2<Z> extends Object with Am2<int Function(), Z> {}

class Em2<Z> extends Object with Am2<Function(), Z> {}

// Compile-time error: Named parameters should have names.
class Fm2<Z> extends Object with Am2<Function({int}), Z> {}

class Gm2<Z> extends Object with Am2<Function({int x}), Z> {}

class Hm2<Z> extends Object with Am2<Function([int]), Z> {}

class Im2<Z> extends Object with Am2<Function([int x]), Z> {}

// Compile-time error: type argument is not a subtype.
class Jm2<Z> extends Object with Am2<Function, Z> {}

// Compile-time error: type argument is not a subtype.
class Km2<Z> extends Object with Am2<Function(Function Function), Z> {}

class Lm2<Z> extends Object
    with Am2<Function(Function Function() Function) Function(), Z> {}

// Compile-time error: type argument is not a subtype.
class Mm2<Z> = Object with Am2<Function(int), Z>;

// Compile-time error: type argument is not a subtype.
class Nm2<Z> = Object with Am2<Function(int x), Z>;

class Om2<Z> = Object with Am2<int Function(), Z>;

class Pm2<Z> = Object with Am2<Function(), Z>;

// Compile-time error: Named parameters should have names.
class Qm2<Z> = Object with Am2<Function({int}), Z>;

class Rm2<Z> = Object with Am2<Function({int x}), Z>;

class Sm2<Z> = Object with Am2<Function([int]), Z>;

class Tm2<Z> = Object with Am2<Function([int x]), Z>;

// Compile-time error: type argument is not a subtype.
class Um2<Z> = Object with Am2<Function, Z>;

// Compile-time error: type argument is not a subtype.
class Vm2<Z> = Object with Am2<Function(Function Function), Z>;

class Wm2<Z> = Object
    with Am2<Function(Function Function() Function) Function(), Z>;

// The case 'm3' covers function types with some missing parts defined via
// typedefs.

typedef TdB = Function(int);

typedef TdC = Function(int x);

typedef TdD = int Function();

typedef TdE = Function();

// Compile-time error: Named parameters should have names.
typedef TdF = Function({int});

typedef TdG = Function({int x});

typedef TdH = Function([int]);

typedef TdI = Function([int x]);

typedef TdJ = Function(Function Function);

typedef TdK = Function(Function Function() Function) Function();

class Am3<L, Y> {}

class Bm3<Z> extends Object with Am3<TdB, Z> {}

class Cm3<Z> extends Object with Am3<TdC, Z> {}

class Dm3<Z> extends Object with Am3<TdD, Z> {}

class Em3<Z> extends Object with Am3<TdE, Z> {}

class Fm3<Z> extends Object with Am3<TdF, Z> {}

class Gm3<Z> extends Object with Am3<TdG, Z> {}

class Hm3<Z> extends Object with Am3<TdH, Z> {}

class Im3<Z> extends Object with Am3<TdI, Z> {}

class Jm3<Z> extends Object with Am3<TdJ, Z> {}

class Km3<Z> extends Object with Am3<TdK, Z> {}

// In case cloning will not be used in the examples above, here are some
// examples that should utilize cloning of type builders and that should cover
// some of the cases above.  Here, type variables of the class are cloned for
// its factories, including the bounds that are type builders.

class Af1<X extends Function(int)> {
  factory Af1.foo() => null;
}

class Bf1<X extends Function(int x)> {
  factory Bf1.foo() => null;
}

class Cf1<X extends int Function()> {
  factory Cf1.foo() => null;
}

class Df1<X extends Function()> {
  factory Df1.foo() => null;
}

// Compile-time error: Named parameters should have names.
class Ef1<X extends Function({int})> {
  factory Ef1.foo() => null;
}

class Ff1<X extends Function({int x})> {
  factory Ff1.foo() => null;
}

class Gf1<X extends Function([int])> {
  factory Gf1.foo() => null;
}

class Hf1<X extends Function([int x])> {
  factory Hf1.foo() => null;
}

class If1<X extends Function> {
  factory If1.foo() => null;
}

class Jf1<X extends Function(Function Function)> {
  factory Jf1.foo() => null;
}

class Kf1<X extends Function(Function Function() Function) Function()> {
  factory Kf1.foo() => null;
}

class Bf2<X extends TdB> {
  factory Bf2.foo() => null;
}

class Cf2<X extends TdC> {
  factory Cf2.foo() => null;
}

class Df2<X extends TdD> {
  factory Df2.foo() => null;
}

class Ef2<X extends TdE> {
  factory Ef2.foo() => null;
}

class Ff2<X extends TdF> {
  factory Ff2.foo() => null;
}

class Gf2<X extends TdG> {
  factory Gf2.foo() => null;
}

class Hf2<X extends TdH> {
  factory Hf2.foo() => null;
}

class If2<X extends TdI> {
  factory If2.foo() => null;
}

class Jf2<X extends TdJ> {
  factory Jf2.foo() => null;
}

class Kf2<X extends TdK> {
  factory Kf2.foo() => null;
}

main() {}
