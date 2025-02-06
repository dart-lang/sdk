// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that various types cause an error when it violates its bounds and
// is not correctly super-bounded.

import 'dart:async';

class A<X> {}

class B<X extends B<X>> extends A<X> {}

typedef F<X> = void Function<Y extends X>();
F<X> toF<X>(X x) => throw 0;

typedef Fcov<X> = X Function();
typedef Fcon<X> = Function(X);
typedef Finv<X> = X Function(X);
typedef Funu<X> = Function();

typedef FcovBound<X extends num> = X Function();
typedef FconBound<X extends num> = Function(X);
typedef FinvBound<X extends num> = X Function(X);
typedef FunuBound<X extends num> = Function();

typedef FcovCyclicBound<X extends A<X>> = X Function();
typedef FconCyclicBound<X extends A<X>> = Function(X);
typedef FinvCyclicBound<X extends A<X>> = X Function(X);
typedef FunuCyclicBound<X extends A<X>> = Function();

typedef FcovCyclicCoBound<X extends Function(X)> = X Function();
typedef FconCyclicCoBound<X extends Function(X)> = Function(X);
typedef FinvCyclicCoBound<X extends Function(X)> = X Function(X);
typedef FunuCyclicCoBound<X extends Function(X)> = Function();

class AcovCyclicCoBound<
  X extends FcovCyclicCoBound<Y>,
  Y extends Function(Y)
> {}

class AconCyclicCoBound<
  X extends FconCyclicCoBound<Y>,
  Y extends Function(Y)
> {}

class AinvCyclicCoBound<
  X extends FinvCyclicCoBound<Y>,
  Y extends Function(Y)
> {}

class CFcov<X extends Fcov<X>> {}

class CFcon<X extends Fcon<X>> {}

class CFinv<X extends Finv<X>> {}

class CFunu<X extends Funu<X>> {}

class CcovBound<X extends num> {}

class CcovCyclicBound<X extends A<X>> {}

class CcovCyclicCoBound<X extends Function(X)> {}

void testCovariantSuperboundError<N extends Null>() {
  // --- Near-top type in a covariant position, not super-bounded.
  FcovBound<Object> x1;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovBound<FutureOr<Object>> x2;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<Object> x3;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<FutureOr<Object>> x4;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<A<Object>> x5;
  // [error column 3]
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<A<FutureOr<Object>>> x6;
  // [error column 3]
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<A<A<Object>>> x7;
  // [error column 3]
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<A<A<FutureOr<Object>>>> x8;
  // [error column 3]
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicCoBound<Object> x9;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicCoBound<FutureOr<Object>> x10;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicCoBound<Function(Function(Object))> x11;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicCoBound<Function(Function(FutureOr<Object>))> x12;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Object> x13;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<FutureOr<Object>> x14;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Fcov<Object>> x15;
  // [error column 3]
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Fcov<FutureOr<Object>>> x16;
  // [error column 3]
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Fcov<Fcov<Object>>> x17;
  // [error column 3]
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Fcov<Fcov<FutureOr<Object>>>> x18;
  // [error column 3]
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcon<Object> x19;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcon<FutureOr<Object>> x20;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFinv<Object> x21;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFinv<FutureOr<Object>> x22;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFunu<Object> x23;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFunu<FutureOr<Object>> x24;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovBound<Object> x25;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovBound<FutureOr<Object>> x26;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<Object> x27;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<FutureOr<Object>> x28;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<A<Object>> x29;
  // [error column 3]
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<A<FutureOr<Object>>> x30;
  // [error column 3]
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<A<A<Object>>> x31;
  // [error column 3]
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<A<A<FutureOr<Object>>>> x32;
  // [error column 3]
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicCoBound<Object> x33;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicCoBound<FutureOr<Object>> x34;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicCoBound<Function(Function(Object))> x35;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicCoBound<Function(Function(FutureOr<Object>))> x36;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  // --- Same non-super-bounded types in a context.
  A<FcovBound<Object>> x37;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovBound<FutureOr<Object>>> x38;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicBound<Object>> x39;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicBound<FutureOr<Object>>> x40;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicBound<A<Object>>> x41;
  //^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicBound<A<FutureOr<Object>>>> x42;
  //^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicBound<A<A<Object>>>> x43;
  //^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicBound<A<A<FutureOr<Object>>>>> x44;
  //^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicCoBound<Object>> x45;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicCoBound<FutureOr<Object>>> x46;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicCoBound<Function(Function(Object))>> x47;
  //^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x48;
  //^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFcov<Object>> x49;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFcov<FutureOr<Object>>> x50;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFcov<Fcov<Object>>> x51;
  //^
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //      ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFcov<Fcov<FutureOr<Object>>>> x52;
  //^
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //      ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFcov<Fcov<Fcov<Object>>>> x53;
  //^
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //      ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFcov<Fcov<Fcov<FutureOr<Object>>>>> x54;
  //^
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFcon<Object>> x55;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFcon<FutureOr<Object>>> x56;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFinv<Object>> x57;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFinv<FutureOr<Object>>> x58;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFunu<Object>> x59;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CFunu<FutureOr<Object>>> x60;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovBound<Object>> x61;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovBound<FutureOr<Object>>> x62;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicBound<Object>> x63;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicBound<FutureOr<Object>>> x64;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicBound<A<Object>>> x65;
  //^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicBound<A<FutureOr<Object>>>> x66;
  //^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicBound<A<A<Object>>>> x67;
  //^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicBound<A<A<FutureOr<Object>>>>> x68;
  //^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicCoBound<Object>> x69;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicCoBound<FutureOr<Object>>> x70;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicCoBound<Function(Function(Object))>> x71;
  //^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<CcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x72;
  //^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovBound<Object> Function() x73;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovBound<FutureOr<Object>> Function() x74;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<Object> Function() x75;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<FutureOr<Object>> Function() x76;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<A<Object>> Function() x77;
  // [error column 3]
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<A<FutureOr<Object>>> Function() x78;
  // [error column 3]
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<A<A<Object>>> Function() x79;
  // [error column 3]
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicBound<A<A<FutureOr<Object>>>> Function() x80;
  // [error column 3]
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicCoBound<Object> Function() x81;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicCoBound<FutureOr<Object>> Function() x82;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicCoBound<Function(Function(Object))> Function() x83;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FcovCyclicCoBound<Function(Function(FutureOr<Object>))> Function() x84;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Object> Function() x85;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<FutureOr<Object>> Function() x86;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Fcov<Object>> Function() x87;
  // [error column 3]
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Fcov<FutureOr<Object>>> Function() x88;
  // [error column 3]
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Fcov<Fcov<Object>>> Function() x89;
  // [error column 3]
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcov<Fcov<Fcov<FutureOr<Object>>>> Function() x90;
  // [error column 3]
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcon<Object> Function() x91;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFcon<FutureOr<Object>> Function() x92;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFinv<Object> Function() x93;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFinv<FutureOr<Object>> Function() x94;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFunu<Object> Function() x95;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CFunu<FutureOr<Object>> Function() x96;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovBound<Object> Function() x97;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovBound<FutureOr<Object>> Function() x98;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<Object> Function() x99;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<FutureOr<Object>> Function() x100;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<A<Object>> Function() x101;
  // [error column 3]
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<A<FutureOr<Object>>> Function() x102;
  // [error column 3]
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<A<A<Object>>> Function() x103;
  // [error column 3]
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicBound<A<A<FutureOr<Object>>>> Function() x104;
  // [error column 3]
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicCoBound<Object> Function() x105;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicCoBound<FutureOr<Object>> Function() x106;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicCoBound<Function(Function(Object))> Function() x107;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  CcovCyclicCoBound<Function(Function(FutureOr<Object>))> Function() x108;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovBound<Object>)) x109;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                                    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovBound<FutureOr<Object>>)) x110;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                                    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicBound<Object>)) x111;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicBound<FutureOr<Object>>)) x112;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicBound<A<Object>>)) x113;
  //                          ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicBound<A<FutureOr<Object>>>)) x114;
  //                          ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicBound<A<A<Object>>>)) x115;
  //                          ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicBound<A<A<FutureOr<Object>>>>)) x116;
  //                          ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicCoBound<Object>)) x117;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicCoBound<FutureOr<Object>>)) x118;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FcovCyclicCoBound<Function(Function(Object))>))
  //                          ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x119;
  void Function(
    void Function(FcovCyclicCoBound<Function(Function(FutureOr<Object>))>),
    //            ^
    // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
    //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  )
  x120;
  void Function(void Function(CFcov<Object>)) x121;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFcov<FutureOr<Object>>)) x122;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFcov<Fcov<Object>>)) x123;
  //                          ^
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                                ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFcov<Fcov<FutureOr<Object>>>)) x124;
  //                          ^
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                                ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFcov<Fcov<Fcov<Object>>>)) x125;
  //                          ^
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                                ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFcov<Fcov<Fcov<FutureOr<Object>>>>)) x126;
  //                          ^
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFcon<Object>)) x127;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFcon<FutureOr<Object>>)) x128;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFinv<Object>)) x129;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFinv<FutureOr<Object>>)) x130;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFunu<Object>)) x131;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CFunu<FutureOr<Object>>)) x132;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovBound<Object>)) x133;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                                    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovBound<FutureOr<Object>>)) x134;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                                    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicBound<Object>)) x135;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicBound<FutureOr<Object>>)) x136;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicBound<A<Object>>)) x137;
  //                          ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicBound<A<FutureOr<Object>>>)) x138;
  //                          ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicBound<A<A<Object>>>)) x139;
  //                          ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicBound<A<A<FutureOr<Object>>>>)) x140;
  //                          ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicCoBound<Object>)) x141;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicCoBound<FutureOr<Object>>)) x142;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(CcovCyclicCoBound<Function(Function(Object))>))
  //                          ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x143;
  void Function(
    void Function(CcovCyclicCoBound<Function(Function(FutureOr<Object>))>),
    //            ^
    // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
    //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  )
  x144;
  void Function(FcovBound<Object>) x145;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovBound<FutureOr<Object>>) x146;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<Object>) x147;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<FutureOr<Object>>) x148;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<A<Object>>) x149;
  //            ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<A<FutureOr<Object>>>) x150;
  //            ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<A<A<Object>>>) x151;
  //            ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<A<A<FutureOr<Object>>>>) x152;
  //            ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicCoBound<Object>) x153;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicCoBound<FutureOr<Object>>) x154;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicCoBound<Function(Function(Object))>) x155;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicCoBound<Function(Function(FutureOr<Object>))>) x156;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Object>) x157;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<FutureOr<Object>>) x158;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Fcov<Object>>) x159;
  //            ^
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Fcov<FutureOr<Object>>>) x160;
  //            ^
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Fcov<Fcov<Object>>>) x161;
  //            ^
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Fcov<Fcov<FutureOr<Object>>>>) x162;
  //            ^
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcon<Object>) x163;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcon<FutureOr<Object>>) x164;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFinv<Object>) x165;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFinv<FutureOr<Object>>) x166;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFunu<Object>) x167;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFunu<FutureOr<Object>>) x168;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovBound<Object>) x169;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovBound<FutureOr<Object>>) x170;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<Object>) x171;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<FutureOr<Object>>) x172;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<A<Object>>) x173;
  //            ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<A<FutureOr<Object>>>) x174;
  //            ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<A<A<Object>>>) x175;
  //            ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<A<A<FutureOr<Object>>>>) x176;
  //            ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicCoBound<Object>) x177;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicCoBound<FutureOr<Object>>) x178;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicCoBound<Function(Function(Object))>) x179;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicCoBound<Function(Function(FutureOr<Object>))>) x180;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovBound<Object>) Function() x181;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovBound<FutureOr<Object>>) Function() x182;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<Object>) Function() x183;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<FutureOr<Object>>) Function() x184;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<A<Object>>) Function() x185;
  //            ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<A<FutureOr<Object>>>) Function() x186;
  //            ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<A<A<Object>>>) Function() x187;
  //            ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicBound<A<A<FutureOr<Object>>>>) Function() x188;
  //            ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicCoBound<Object>) Function() x189;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicCoBound<FutureOr<Object>>) Function() x190;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicCoBound<Function(Function(Object))>) Function() x191;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FcovCyclicCoBound<Function(Function(FutureOr<Object>))>)
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Function()
  x192;
  void Function(CFcov<Object>) Function() x193;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<FutureOr<Object>>) Function() x194;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Fcov<Object>>) Function() x195;
  //            ^
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Fcov<FutureOr<Object>>>) Function() x196;
  //            ^
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Fcov<Fcov<Object>>>) Function() x197;
  //            ^
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcov<Fcov<Fcov<FutureOr<Object>>>>) Function() x198;
  //            ^
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcon<Object>) Function() x199;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFcon<FutureOr<Object>>) Function() x200;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFinv<Object>) Function() x201;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFinv<FutureOr<Object>>) Function() x202;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFunu<Object>) Function() x203;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CFunu<FutureOr<Object>>) Function() x204;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovBound<Object>) Function() x205;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovBound<FutureOr<Object>>) Function() x206;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<Object>) Function() x207;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<FutureOr<Object>>) Function() x208;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<A<Object>>) Function() x209;
  //            ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<A<FutureOr<Object>>>) Function() x210;
  //            ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<A<A<Object>>>) Function() x211;
  //            ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicBound<A<A<FutureOr<Object>>>>) Function() x212;
  //            ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicCoBound<Object>) Function() x213;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicCoBound<FutureOr<Object>>) Function() x214;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicCoBound<Function(Function(Object))>) Function() x215;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(CcovCyclicCoBound<Function(Function(FutureOr<Object>))>)
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Function()
  x216;
  void Function<Y extends FcovBound<Object>>() x217;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovBound<FutureOr<Object>>>() x218;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicBound<Object>>() x219;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicBound<FutureOr<Object>>>() x220;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicBound<A<Object>>>() x221;
  //                      ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                      ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicBound<A<FutureOr<Object>>>>() x222;
  //                      ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicBound<A<A<Object>>>>() x223;
  //                      ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                      ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicBound<A<A<FutureOr<Object>>>>>() x224;
  //                      ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicCoBound<Object>>() x225;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicCoBound<FutureOr<Object>>>() x226;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FcovCyclicCoBound<Function(Function(Object))>>() x227;
  //                      ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void
  Function<Y extends FcovCyclicCoBound<Function(Function(FutureOr<Object>))>>()
  //                 ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x228;
  void Function<Y extends CFcov<Object>>() x229;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFcov<FutureOr<Object>>>() x230;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFcov<Fcov<Object>>>() x231;
  //                      ^
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFcov<Fcov<FutureOr<Object>>>>() x232;
  //                      ^
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFcov<Fcov<Fcov<Object>>>>() x233;
  //                      ^
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                            ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFcov<Fcov<Fcov<FutureOr<Object>>>>>() x234;
  //                      ^
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFcon<Object>>() x235;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFcon<FutureOr<Object>>>() x236;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFinv<Object>>() x237;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFinv<FutureOr<Object>>>() x238;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFunu<Object>>() x239;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CFunu<FutureOr<Object>>>() x240;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovBound<Object>>() x241;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovBound<FutureOr<Object>>>() x242;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicBound<Object>>() x243;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicBound<FutureOr<Object>>>() x244;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicBound<A<Object>>>() x245;
  //                      ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                      ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicBound<A<FutureOr<Object>>>>() x246;
  //                      ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicBound<A<A<Object>>>>() x247;
  //                      ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                      ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicBound<A<A<FutureOr<Object>>>>>() x248;
  //                      ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicCoBound<Object>>() x249;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicCoBound<FutureOr<Object>>>() x250;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends CcovCyclicCoBound<Function(Function(Object))>>() x251;
  //                      ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void
  Function<Y extends CcovCyclicCoBound<Function(Function(FutureOr<Object>))>>()
  //                 ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x252;
  void Function<Y extends A<FcovBound<Object>>>() x253;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovBound<FutureOr<Object>>>>() x254;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //                                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicBound<Object>>>() x255;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicBound<FutureOr<Object>>>>() x256;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicBound<A<Object>>>>() x257;
  //                        ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                        ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicBound<A<FutureOr<Object>>>>>() x258;
  //                        ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicBound<A<A<Object>>>>>() x259;
  //                        ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicBound<A<A<FutureOr<Object>>>>>>() x260;
  //                        ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicCoBound<Object>>>() x261;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicCoBound<FutureOr<Object>>>>() x262;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FcovCyclicCoBound<Function(Function(Object))>>>()
  //                        ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x263;
  void Function<
    Y extends A<FcovCyclicCoBound<Function(Function(FutureOr<Object>))>>
    //          ^
    // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
    //                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  >()
  x264;
  void Function<Y extends A<CFcov<Object>>>() x265;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFcov<FutureOr<Object>>>>() x266;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFcov<Fcov<Object>>>>() x267;
  //                        ^
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFcov<Fcov<FutureOr<Object>>>>>() x268;
  //                        ^
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFcov<Fcov<Fcov<Object>>>>>() x269;
  //                        ^
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                              ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFcov<Fcov<Fcov<FutureOr<Object>>>>>>() x270;
  //                        ^
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFcon<Object>>>() x271;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFcon<FutureOr<Object>>>>() x272;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFinv<Object>>>() x273;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFinv<FutureOr<Object>>>>() x274;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFunu<Object>>>() x275;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CFunu<FutureOr<Object>>>>() x276;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovBound<Object>>>() x277;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovBound<FutureOr<Object>>>>() x278;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //                                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicBound<Object>>>() x279;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicBound<FutureOr<Object>>>>() x280;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicBound<A<Object>>>>() x281;
  //                        ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                        ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicBound<A<FutureOr<Object>>>>>() x282;
  //                        ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicBound<A<A<Object>>>>>() x283;
  //                        ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicBound<A<A<FutureOr<Object>>>>>>() x284;
  //                        ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicCoBound<Object>>>() x285;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicCoBound<FutureOr<Object>>>>() x286;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<CcovCyclicCoBound<Function(Function(Object))>>>()
  //                        ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x287;
  void Function<
    Y extends A<CcovCyclicCoBound<Function(Function(FutureOr<Object>))>>
    //          ^
    // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
    //                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  >()
  x288;
  Finv<FcovBound<Object>> x289;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovBound<FutureOr<Object>>> x290;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicBound<Object>> x291;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicBound<FutureOr<Object>>> x292;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicBound<A<Object>>> x293;
  //   ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicBound<A<FutureOr<Object>>>> x294;
  //   ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicBound<A<A<Object>>>> x295;
  //   ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicBound<A<A<FutureOr<Object>>>>> x296;
  //   ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicCoBound<Object>> x297;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicCoBound<FutureOr<Object>>> x298;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicCoBound<Function(Function(Object))>> x299;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x300;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFcov<Object>> x301;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFcov<FutureOr<Object>>> x302;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFcov<Fcov<Object>>> x303;
  //   ^
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFcov<Fcov<FutureOr<Object>>>> x304;
  //   ^
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFcov<Fcov<Fcov<Object>>>> x305;
  //   ^
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFcov<Fcov<Fcov<FutureOr<Object>>>>> x306;
  //   ^
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFcon<Object>> x307;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFcon<FutureOr<Object>>> x308;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFinv<Object>> x309;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFinv<FutureOr<Object>>> x310;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFunu<Object>> x311;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CFunu<FutureOr<Object>>> x312;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovBound<Object>> x313;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovBound<FutureOr<Object>>> x314;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicBound<Object>> x315;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicBound<FutureOr<Object>>> x316;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicBound<A<Object>>> x317;
  //   ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicBound<A<FutureOr<Object>>>> x318;
  //   ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicBound<A<A<Object>>>> x319;
  //   ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicBound<A<A<FutureOr<Object>>>>> x320;
  //   ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicCoBound<Object>> x321;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicCoBound<FutureOr<Object>>> x322;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicCoBound<Function(Function(Object))>> x323;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<CcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x324;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovBound<Object>> x325;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovBound<FutureOr<Object>>> x326;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicBound<Object>> x327;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicBound<FutureOr<Object>>> x328;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicBound<A<Object>>> x329;
  //   ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicBound<A<FutureOr<Object>>>> x330;
  //   ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicBound<A<A<Object>>>> x331;
  //   ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicBound<A<A<FutureOr<Object>>>>> x332;
  //   ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicCoBound<Object>> x333;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicCoBound<FutureOr<Object>>> x334;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicCoBound<Function(Function(Object))>> x335;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x336;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFcov<Object>> x337;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFcov<FutureOr<Object>>> x338;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFcov<Fcov<Object>>> x339;
  //   ^
  // [cfe] Type argument 'Fcov<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFcov<Fcov<FutureOr<Object>>>> x340;
  //   ^
  // [cfe] Type argument 'Fcov<FutureOr<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFcov<Fcov<Fcov<Object>>>> x341;
  //   ^
  // [cfe] Type argument 'Fcov<Fcov<Object>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFcov<Fcov<Fcov<FutureOr<Object>>>>> x342;
  //   ^
  // [cfe] Type argument 'Fcov<Fcov<FutureOr<Object>>>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  //         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFcon<Object>> x343;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFcon<FutureOr<Object>>> x344;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFinv<Object>> x345;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFinv<FutureOr<Object>>> x346;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFunu<Object>> x347;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CFunu<FutureOr<Object>>> x348;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  //         ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovBound<Object>> x349;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovBound<FutureOr<Object>>> x350;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicBound<Object>> x351;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicBound<FutureOr<Object>>> x352;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicBound<A<Object>>> x353;
  //   ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicBound<A<FutureOr<Object>>>> x354;
  //   ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicBound<A<A<Object>>>> x355;
  //   ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicBound<A<A<FutureOr<Object>>>>> x356;
  //   ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicCoBound<Object>> x357;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicCoBound<FutureOr<Object>>> x358;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicCoBound<Function(Function(Object))>> x359;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<CcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x360;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}

void testInvariantSuperboundError<N extends Null>() {
  // --- Near-top type in an invariant position, not super-bounded.
  FinvBound<Object> x1;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvBound<FutureOr<Object>> x2;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<Object> x3;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<FutureOr<Object>> x4;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<A<Object>> x5;
  // [error column 3]
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<A<FutureOr<Object>>> x6;
  // [error column 3]
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<A<A<Object>>> x7;
  // [error column 3]
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<A<A<FutureOr<Object>>>> x8;
  // [error column 3]
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicCoBound<Object> x9;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicCoBound<FutureOr<Object>> x10;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicCoBound<Function(Function(Object))> x11;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicCoBound<Function(Function(FutureOr<Object>))> x12;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  // --- Same non-super-bounded types in a context.
  A<FinvBound<Object>> x13;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvBound<FutureOr<Object>>> x14;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicBound<Object>> x15;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicBound<FutureOr<Object>>> x16;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicBound<A<Object>>> x17;
  //^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicBound<A<FutureOr<Object>>>> x18;
  //^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicBound<A<A<Object>>>> x19;
  //^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicBound<A<A<FutureOr<Object>>>>> x20;
  //^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicCoBound<Object>> x21;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicCoBound<FutureOr<Object>>> x22;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicCoBound<Function(Function(Object))>> x23;
  //^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FinvCyclicCoBound<Function(Function(FutureOr<Object>))>> x24;
  //^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvBound<Object> Function() x25;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvBound<FutureOr<Object>> Function() x26;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<Object> Function() x27;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<FutureOr<Object>> Function() x28;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<A<Object>> Function() x29;
  // [error column 3]
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<A<FutureOr<Object>>> Function() x30;
  // [error column 3]
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<A<A<Object>>> Function() x31;
  // [error column 3]
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicBound<A<A<FutureOr<Object>>>> Function() x32;
  // [error column 3]
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicCoBound<Object> Function() x33;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicCoBound<FutureOr<Object>> Function() x34;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicCoBound<Function(Function(Object))> Function() x35;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FinvCyclicCoBound<Function(Function(FutureOr<Object>))> Function() x36;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvBound<Object>)) x37;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                                    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvBound<FutureOr<Object>>)) x38;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                                    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicBound<Object>)) x39;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicBound<FutureOr<Object>>)) x40;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicBound<A<Object>>)) x41;
  //                          ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicBound<A<FutureOr<Object>>>)) x42;
  //                          ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicBound<A<A<Object>>>)) x43;
  //                          ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicBound<A<A<FutureOr<Object>>>>)) x44;
  //                          ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicCoBound<Object>)) x45;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicCoBound<FutureOr<Object>>)) x46;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FinvCyclicCoBound<Function(Function(Object))>))
  //                          ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x47;
  void Function(
    void Function(FinvCyclicCoBound<Function(Function(FutureOr<Object>))>),
    //            ^
    // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
    //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  )
  x48;
  void Function(FinvBound<Object>) x49;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvBound<FutureOr<Object>>) x50;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<Object>) x51;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<FutureOr<Object>>) x52;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<A<Object>>) x53;
  //            ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<A<FutureOr<Object>>>) x54;
  //            ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<A<A<Object>>>) x55;
  //            ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<A<A<FutureOr<Object>>>>) x56;
  //            ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicCoBound<Object>) x57;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicCoBound<FutureOr<Object>>) x58;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicCoBound<Function(Function(Object))>) x59;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicCoBound<Function(Function(FutureOr<Object>))>) x60;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvBound<Object>) Function() x61;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvBound<FutureOr<Object>>) Function() x62;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<Object>) Function() x63;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<FutureOr<Object>>) Function() x64;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<A<Object>>) Function() x65;
  //            ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<A<FutureOr<Object>>>) Function() x66;
  //            ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<A<A<Object>>>) Function() x67;
  //            ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicBound<A<A<FutureOr<Object>>>>) Function() x68;
  //            ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicCoBound<Object>) Function() x69;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicCoBound<FutureOr<Object>>) Function() x70;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicCoBound<Function(Function(Object))>) Function() x71;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FinvCyclicCoBound<Function(Function(FutureOr<Object>))>)
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Function()
  x72;
  void Function<Y extends FinvBound<Object>>() x73;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvBound<FutureOr<Object>>>() x74;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicBound<Object>>() x75;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicBound<FutureOr<Object>>>() x76;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicBound<A<Object>>>() x77;
  //                      ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                      ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicBound<A<FutureOr<Object>>>>() x78;
  //                      ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicBound<A<A<Object>>>>() x79;
  //                      ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                      ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicBound<A<A<FutureOr<Object>>>>>() x80;
  //                      ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicCoBound<Object>>() x81;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicCoBound<FutureOr<Object>>>() x82;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FinvCyclicCoBound<Function(Function(Object))>>() x83;
  //                      ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void
  Function<Y extends FinvCyclicCoBound<Function(Function(FutureOr<Object>))>>()
  //                 ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x84;
  void Function<Y extends A<FinvBound<Object>>>() x85;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvBound<FutureOr<Object>>>>() x86;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //                                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicBound<Object>>>() x87;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicBound<FutureOr<Object>>>>() x88;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicBound<A<Object>>>>() x89;
  //                        ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                        ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicBound<A<FutureOr<Object>>>>>() x90;
  //                        ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicBound<A<A<Object>>>>>() x91;
  //                        ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicBound<A<A<FutureOr<Object>>>>>>() x92;
  //                        ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicCoBound<Object>>>() x93;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicCoBound<FutureOr<Object>>>>() x94;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FinvCyclicCoBound<Function(Function(Object))>>>()
  //                        ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x95;
  void Function<
    Y extends A<FinvCyclicCoBound<Function(Function(FutureOr<Object>))>>
    //          ^
    // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
    //                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  >()
  x96;
  Finv<FinvBound<Object>> x97;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvBound<FutureOr<Object>>> x98;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicBound<Object>> x99;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicBound<FutureOr<Object>>> x100;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicBound<A<Object>>> x101;
  //   ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicBound<A<FutureOr<Object>>>> x102;
  //   ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicBound<A<A<Object>>>> x103;
  //   ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicBound<A<A<FutureOr<Object>>>>> x104;
  //   ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicCoBound<Object>> x105;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicCoBound<FutureOr<Object>>> x106;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicCoBound<Function(Function(Object))>> x107;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FinvCyclicCoBound<Function(Function(FutureOr<Object>))>> x108;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvBound<Object>> x109;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvBound<FutureOr<Object>>> x110;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicBound<Object>> x111;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicBound<FutureOr<Object>>> x112;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicBound<A<Object>>> x113;
  //   ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicBound<A<FutureOr<Object>>>> x114;
  //   ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicBound<A<A<Object>>>> x115;
  //   ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicBound<A<A<FutureOr<Object>>>>> x116;
  //   ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicCoBound<Object>> x117;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicCoBound<FutureOr<Object>>> x118;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicCoBound<Function(Function(Object))>> x119;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FinvCyclicCoBound<Function(Function(FutureOr<Object>))>> x120;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}

void testVarianceLessSuperboundError<N extends Null>() {
  // --- Near-top type in a variance-less position, not super-bounded.
  FunuBound<Object> x1;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuBound<FutureOr<Object>> x2;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<Object> x3;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<FutureOr<Object>> x4;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<A<Object>> x5;
  // [error column 3]
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<A<FutureOr<Object>>> x6;
  // [error column 3]
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<A<A<Object>>> x7;
  // [error column 3]
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<A<A<FutureOr<Object>>>> x8;
  // [error column 3]
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<Object> x9;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<FutureOr<Object>> x10;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<Function(Function(Object))> x13;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<Function(Function(FutureOr<Object>))> x14;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  // --- Same non-super-bounded types in a context.
  A<FunuBound<Object>> x19;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuBound<FutureOr<Object>>> x20;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicBound<Object>> x21;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicBound<FutureOr<Object>>> x22;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicBound<A<Object>>> x23;
  //^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicBound<A<FutureOr<Object>>>> x24;
  //^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicBound<A<A<Object>>>> x25;
  //^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicBound<A<A<FutureOr<Object>>>>> x26;
  //^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicCoBound<Object>> x27;
  //^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicCoBound<FutureOr<Object>>> x28;
  //^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicCoBound<Function(Function(Object))>> x31;
  //^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  A<FunuCyclicCoBound<Function(Function(FutureOr<Object>))>> x32;
  //^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuBound<Object> Function() x37;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuBound<FutureOr<Object>> Function() x38;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<Object> Function() x39;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<FutureOr<Object>> Function() x40;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<A<Object>> Function() x41;
  // [error column 3]
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<A<FutureOr<Object>>> Function() x42;
  // [error column 3]
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<A<A<Object>>> Function() x43;
  // [error column 3]
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicBound<A<A<FutureOr<Object>>>> Function() x44;
  // [error column 3]
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<Object> Function() x45;
  // [error column 3]
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<FutureOr<Object>> Function() x46;
  // [error column 3]
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<Function(Function(Object))> Function() x49;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<Function(Function(FutureOr<Object>))> Function() x50;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuBound<Object>)) x55;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                                    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuBound<FutureOr<Object>>)) x56;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                                    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicBound<Object>)) x57;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicBound<FutureOr<Object>>)) x58;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicBound<A<Object>>)) x59;
  //                          ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicBound<A<FutureOr<Object>>>)) x60;
  //                          ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicBound<A<A<Object>>>)) x61;
  //                          ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicBound<A<A<FutureOr<Object>>>>)) x62;
  //                          ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicCoBound<Object>)) x63;
  //                          ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicCoBound<FutureOr<Object>>)) x64;
  //                          ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(void Function(FunuCyclicCoBound<Function(Function(Object))>))
  //                          ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x67;
  void Function(
    void Function(FunuCyclicCoBound<Function(Function(FutureOr<Object>))>),
    //            ^
    // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
    //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  )
  x68;
  void Function(FunuBound<Object>) x73;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuBound<FutureOr<Object>>) x74;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<Object>) x75;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<FutureOr<Object>>) x76;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<A<Object>>) x77;
  //            ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<A<FutureOr<Object>>>) x78;
  //            ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<A<A<Object>>>) x79;
  //            ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<A<A<FutureOr<Object>>>>) x80;
  //            ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicCoBound<Object>) x81;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicCoBound<FutureOr<Object>>) x82;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicCoBound<Function(Function(Object))>) x85;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicCoBound<Function(Function(FutureOr<Object>))>) x86;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuBound<Object>) Function() x91;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuBound<FutureOr<Object>>) Function() x92;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<Object>) Function() x93;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<FutureOr<Object>>) Function() x94;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<A<Object>>) Function() x95;
  //            ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<A<FutureOr<Object>>>) Function() x96;
  //            ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<A<A<Object>>>) Function() x97;
  //            ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicBound<A<A<FutureOr<Object>>>>) Function() x98;
  //            ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicCoBound<Object>) Function() x99;
  //            ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicCoBound<FutureOr<Object>>) Function() x100;
  //            ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicCoBound<Function(Function(Object))>) Function() x103;
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function(FunuCyclicCoBound<Function(Function(FutureOr<Object>))>)
  //            ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Function()
  x104;
  void Function<Y extends FunuBound<Object>>() x109;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                                ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuBound<FutureOr<Object>>>() x110;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                                ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicBound<Object>>() x111;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicBound<FutureOr<Object>>>() x112;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicBound<A<Object>>>() x113;
  //                      ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                      ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicBound<A<FutureOr<Object>>>>() x114;
  //                      ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicBound<A<A<Object>>>>() x115;
  //                      ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                      ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicBound<A<A<FutureOr<Object>>>>>() x116;
  //                      ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                      ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicCoBound<Object>>() x117;
  //                      ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicCoBound<FutureOr<Object>>>() x118;
  //                      ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends FunuCyclicCoBound<Function(Function(Object))>>() x121;
  //                      ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void
  Function<Y extends FunuCyclicCoBound<Function(Function(FutureOr<Object>))>>()
  //                 ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x122;
  void Function<Y extends A<FunuBound<Object>>>() x127;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuBound<FutureOr<Object>>>>() x128;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //                                  ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicBound<Object>>>() x129;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicBound<FutureOr<Object>>>>() x130;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicBound<A<Object>>>>() x131;
  //                        ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                        ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicBound<A<FutureOr<Object>>>>>() x132;
  //                        ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicBound<A<A<Object>>>>>() x133;
  //                        ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicBound<A<A<FutureOr<Object>>>>>>() x134;
  //                        ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicCoBound<Object>>>() x135;
  //                        ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicCoBound<FutureOr<Object>>>>() x136;
  //                        ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                          ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  void Function<Y extends A<FunuCyclicCoBound<Function(Function(Object))>>>()
  //                        ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  x139;
  void Function<
    Y extends A<FunuCyclicCoBound<Function(Function(FutureOr<Object>))>>
    //          ^
    // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
    //                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  >()
  x140;
  Finv<FunuBound<Object>> x145;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuBound<FutureOr<Object>>> x146;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicBound<Object>> x147;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicBound<FutureOr<Object>>> x148;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicBound<A<Object>>> x149;
  //   ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicBound<A<FutureOr<Object>>>> x150;
  //   ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicBound<A<A<Object>>>> x151;
  //   ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicBound<A<A<FutureOr<Object>>>>> x152;
  //   ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicCoBound<Object>> x153;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicCoBound<FutureOr<Object>>> x154;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicCoBound<Function(Function(Object))>> x157;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Finv<FunuCyclicCoBound<Function(Function(FutureOr<Object>))>> x158;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuBound<Object>> x163;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuBound<FutureOr<Object>>> x164;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicBound<Object>> x165;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicBound<FutureOr<Object>>> x166;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicBound<A<Object>>> x167;
  //   ^
  // [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicBound<A<FutureOr<Object>>>> x168;
  //   ^
  // [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicBound<A<A<Object>>>> x169;
  //   ^
  // [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicBound<A<A<FutureOr<Object>>>>> x170;
  //   ^
  // [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicCoBound<Object>> x171;
  //   ^
  // [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicCoBound<FutureOr<Object>>> x172;
  //   ^
  // [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicCoBound<Function(Function(Object))>> x175;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Funu<FunuCyclicCoBound<Function(Function(FutureOr<Object>))>> x176;
  //   ^
  // [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}

void testVarianceLessSuperbound<N extends Never>() {
  FunuCyclicCoBound<Function(Never)> x1;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(Never)' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  FunuCyclicCoBound<Function(N)> x2;
  // [error column 3]
  // [cfe] Type argument 'dynamic Function(N)' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  //                ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}

void testTypeAliasAsTypeArgument() {
  // I2b: Use bounds (FinvCyclicCoBound<Y>, Function(Y)), then break cycle {Y}
  // by replacing contravariant occurrence of `Y` in
  // `AinvCyclicCoBound<_, Function(Y)>` by `Never`; then replace invariant
  // occurrence of `Y` in `AinvCyclicCoBound<FinvCyclicCoBound<Y>, _>` by `Y`s
  // value `Function(Never)`.
  // Resulting type
  // `AinvCyclicCoBound<FinvCyclicCoBound<Function(Never)>, Function(Never)>>`
  // looks regular-bounded, but contains `FinvCyclicCoBound<Function(Never)>`
  // which is not well-bounded.
  void f(AinvCyclicCoBound source) {
    //   ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
    // [cfe] Inferred type argument 'dynamic Function(Never)' doesn't conform to the bound 'dynamic Function(Y)' of the type variable 'Y' on 'AinvCyclicCoBound'.

    // We do not use `source` in further tests, because the type of `source`
    // is an error, and we do not generally test error-on-error situations.
  }
}

void testNested() {
  void f(B<AinvCyclicCoBound> source) {
    //   ^
    // [cfe] Type argument 'AinvCyclicCoBound<FinvCyclicCoBound<dynamic Function(Never)>, dynamic Function(Never)>' doesn't conform to the bound 'B<X>' of the type variable 'X' on 'B'.
    //     ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
    // [cfe] Inferred type argument 'dynamic Function(Never)' doesn't conform to the bound 'dynamic Function(Y)' of the type variable 'Y' on 'AinvCyclicCoBound'.

    // We do not use `source` in further tests, because the type of `source`
    // is an error, and we do not generally test error-on-error situations.
  }
}

void main() {
  testCovariantSuperboundError<Null>();
  testInvariantSuperboundError<Null>();
  testVarianceLessSuperboundError<Null>();
  testVarianceLessSuperbound();
  testTypeAliasAsTypeArgument();
  testNested();
}
