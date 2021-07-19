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

class AcovCyclicCoBound<X extends FcovCyclicCoBound<Y>, Y extends Function(Y)> {
}

class AconCyclicCoBound<X extends FconCyclicCoBound<Y>, Y extends Function(Y)> {
}

class AinvCyclicCoBound<X extends FinvCyclicCoBound<Y>, Y extends Function(Y)> {
}

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
//^
// [analyzer] unspecified
//                  ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  FcovBound<FutureOr<Object>> x2;
//^
// [analyzer] unspecified
//                            ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  FcovCyclicBound<Object> x3;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<FutureOr<Object>> x4;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<A<Object>> x5;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<A<FutureOr<Object>>> x6;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<A<A<Object>>> x7;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<A<A<FutureOr<Object>>>> x8;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicCoBound<Object> x9;
//^
// [analyzer] unspecified
//                          ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  FcovCyclicCoBound<FutureOr<Object>> x10;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  FcovCyclicCoBound<Function(Function(Object))> x11;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  FcovCyclicCoBound<Function(Function(FutureOr<Object>))> x12;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  CFcov<Object> x13;
//^
// [analyzer] unspecified
//              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<FutureOr<Object>> x14;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<Fcov<Object>> x15;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<Fcov<FutureOr<Object>>> x16;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<Fcov<Fcov<Object>>> x17;
//^
// [analyzer] unspecified
//                          ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<Fcov<Fcov<FutureOr<Object>>>> x18;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcon<Object> x19;
//^
// [analyzer] unspecified
//              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  CFcon<FutureOr<Object>> x20;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  CFinv<Object> x21;
//^
// [analyzer] unspecified
//              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  CFinv<FutureOr<Object>> x22;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  CFunu<Object> x23;
//^
// [analyzer] unspecified
//              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  CFunu<FutureOr<Object>> x24;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  CcovBound<Object> x25;
//^
// [analyzer] unspecified
//                  ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  CcovBound<FutureOr<Object>> x26;
//^
// [analyzer] unspecified
//                            ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  CcovCyclicBound<Object> x27;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<FutureOr<Object>> x28;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<A<Object>> x29;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<A<FutureOr<Object>>> x30;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<A<A<Object>>> x31;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<A<A<FutureOr<Object>>>> x32;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicCoBound<Object> x33;
//^
// [analyzer] unspecified
//                          ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  CcovCyclicCoBound<FutureOr<Object>> x34;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  CcovCyclicCoBound<Function(Function(Object))> x35;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  CcovCyclicCoBound<Function(Function(FutureOr<Object>))> x36;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.

  // --- Same non-super-bounded types in a context.
  A<FcovBound<Object>> x37;
//^
// [analyzer] unspecified
//                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  A<FcovBound<FutureOr<Object>>> x38;
//^
// [analyzer] unspecified
//                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  A<FcovCyclicBound<Object>> x39;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  A<FcovCyclicBound<FutureOr<Object>>> x40;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  A<FcovCyclicBound<A<Object>>> x41;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  A<FcovCyclicBound<A<FutureOr<Object>>>> x42;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  A<FcovCyclicBound<A<A<Object>>>> x43;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  A<FcovCyclicBound<A<A<FutureOr<Object>>>>> x44;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  A<FcovCyclicCoBound<Object>> x45;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  A<FcovCyclicCoBound<FutureOr<Object>>> x46;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  A<FcovCyclicCoBound<Function(Function(Object))>> x47;
//^
// [analyzer] unspecified
//                                                 ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  A<FcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x48;
//^
// [analyzer] unspecified
//                                                           ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  A<CFcov<Object>> x49;
//^
// [analyzer] unspecified
//                 ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  A<CFcov<FutureOr<Object>>> x50;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  A<CFcov<Fcov<Object>>> x51;
//^
// [analyzer] unspecified
//                       ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  A<CFcov<Fcov<FutureOr<Object>>>> x52;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  A<CFcov<Fcov<Fcov<Object>>>> x53;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  A<CFcov<Fcov<Fcov<FutureOr<Object>>>>> x54;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  A<CFcon<Object>> x55;
//^
// [analyzer] unspecified
//                 ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  A<CFcon<FutureOr<Object>>> x56;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  A<CFinv<Object>> x57;
//^
// [analyzer] unspecified
//                 ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  A<CFinv<FutureOr<Object>>> x58;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  A<CFunu<Object>> x59;
//^
// [analyzer] unspecified
//                 ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  A<CFunu<FutureOr<Object>>> x60;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  A<CcovBound<Object>> x61;
//^
// [analyzer] unspecified
//                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  A<CcovBound<FutureOr<Object>>> x62;
//^
// [analyzer] unspecified
//                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  A<CcovCyclicBound<Object>> x63;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  A<CcovCyclicBound<FutureOr<Object>>> x64;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  A<CcovCyclicBound<A<Object>>> x65;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  A<CcovCyclicBound<A<FutureOr<Object>>>> x66;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  A<CcovCyclicBound<A<A<Object>>>> x67;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  A<CcovCyclicBound<A<A<FutureOr<Object>>>>> x68;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  A<CcovCyclicCoBound<Object>> x69;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  A<CcovCyclicCoBound<FutureOr<Object>>> x70;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  A<CcovCyclicCoBound<Function(Function(Object))>> x71;
//^
// [analyzer] unspecified
//                                                 ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  A<CcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x72;
//^
// [analyzer] unspecified
//                                                           ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  FcovBound<Object> Function() x73;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  FcovBound<FutureOr<Object>> Function() x74;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  FcovCyclicBound<Object> Function() x75;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<FutureOr<Object>> Function() x76;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<A<Object>> Function() x77;
//^
// [analyzer] unspecified
//                                      ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<A<FutureOr<Object>>> Function() x78;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<A<A<Object>>> Function() x79;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicBound<A<A<FutureOr<Object>>>> Function() x80;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  FcovCyclicCoBound<Object> Function() x81;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  FcovCyclicCoBound<FutureOr<Object>> Function() x82;
//^
// [analyzer] unspecified
//                                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  FcovCyclicCoBound<Function(Function(Object))> Function() x83;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  FcovCyclicCoBound<Function(Function(FutureOr<Object>))> Function() x84;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  CFcov<Object> Function() x85;
//^
// [analyzer] unspecified
//                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<FutureOr<Object>> Function() x86;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<Fcov<Object>> Function() x87;
//^
// [analyzer] unspecified
//                               ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<Fcov<FutureOr<Object>>> Function() x88;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<Fcov<Fcov<Object>>> Function() x89;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcov<Fcov<Fcov<FutureOr<Object>>>> Function() x90;
//^
// [analyzer] unspecified
//                                               ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  CFcon<Object> Function() x91;
//^
// [analyzer] unspecified
//                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  CFcon<FutureOr<Object>> Function() x92;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  CFinv<Object> Function() x93;
//^
// [analyzer] unspecified
//                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  CFinv<FutureOr<Object>> Function() x94;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  CFunu<Object> Function() x95;
//^
// [analyzer] unspecified
//                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  CFunu<FutureOr<Object>> Function() x96;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  CcovBound<Object> Function() x97;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  CcovBound<FutureOr<Object>> Function() x98;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  CcovCyclicBound<Object> Function() x99;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<FutureOr<Object>> Function() x100;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<A<Object>> Function() x101;
//^
// [analyzer] unspecified
//                                      ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<A<FutureOr<Object>>> Function() x102;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<A<A<Object>>> Function() x103;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicBound<A<A<FutureOr<Object>>>> Function() x104;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  CcovCyclicCoBound<Object> Function() x105;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  CcovCyclicCoBound<FutureOr<Object>> Function() x106;
//^
// [analyzer] unspecified
//                                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  CcovCyclicCoBound<Function(Function(Object))> Function() x107;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  CcovCyclicCoBound<Function(Function(FutureOr<Object>))> Function() x108;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(void Function(FcovBound<Object>)) x109;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function(void Function(FcovBound<FutureOr<Object>>)) x110;
//^
// [analyzer] unspecified
//                                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function(void Function(FcovCyclicBound<Object>)) x111;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(void Function(FcovCyclicBound<FutureOr<Object>>)) x112;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(void Function(FcovCyclicBound<A<Object>>)) x113;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(void Function(FcovCyclicBound<A<FutureOr<Object>>>)) x114;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(void Function(FcovCyclicBound<A<A<Object>>>)) x115;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(void Function(FcovCyclicBound<A<A<FutureOr<Object>>>>)) x116;
//^
// [analyzer] unspecified
//                                                                      ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(void Function(FcovCyclicCoBound<Object>)) x117;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(void Function(FcovCyclicCoBound<FutureOr<Object>>)) x118;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(void Function(FcovCyclicCoBound<Function(Function(Object))>))
//^
// [analyzer] unspecified
      x119;
//    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(
      void Function(
          FcovCyclicCoBound<Function(Function(FutureOr<Object>))>)) x120;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(void Function(CFcov<Object>)) x121;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(void Function(CFcov<FutureOr<Object>>)) x122;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(void Function(CFcov<Fcov<Object>>)) x123;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(void Function(CFcov<Fcov<FutureOr<Object>>>)) x124;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(void Function(CFcov<Fcov<Fcov<Object>>>)) x125;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(void Function(CFcov<Fcov<Fcov<FutureOr<Object>>>>)) x126;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(void Function(CFcon<Object>)) x127;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function(void Function(CFcon<FutureOr<Object>>)) x128;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function(void Function(CFinv<Object>)) x129;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function(void Function(CFinv<FutureOr<Object>>)) x130;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function(void Function(CFunu<Object>)) x131;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function(void Function(CFunu<FutureOr<Object>>)) x132;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function(void Function(CcovBound<Object>)) x133;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function(void Function(CcovBound<FutureOr<Object>>)) x134;
//^
// [analyzer] unspecified
//                                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function(void Function(CcovCyclicBound<Object>)) x135;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(void Function(CcovCyclicBound<FutureOr<Object>>)) x136;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(void Function(CcovCyclicBound<A<Object>>)) x137;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(void Function(CcovCyclicBound<A<FutureOr<Object>>>)) x138;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(void Function(CcovCyclicBound<A<A<Object>>>)) x139;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(void Function(CcovCyclicBound<A<A<FutureOr<Object>>>>)) x140;
//^
// [analyzer] unspecified
//                                                                      ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(void Function(CcovCyclicCoBound<Object>)) x141;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(void Function(CcovCyclicCoBound<FutureOr<Object>>)) x142;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(void Function(CcovCyclicCoBound<Function(Function(Object))>))
//^
// [analyzer] unspecified
      x143;
//    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(
      void Function(
          CcovCyclicCoBound<Function(Function(FutureOr<Object>))>)) x144;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(FcovBound<Object>) x145;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function(FcovBound<FutureOr<Object>>) x146;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function(FcovCyclicBound<Object>) x147;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<FutureOr<Object>>) x148;
//^
// [analyzer] unspecified
//                                                 ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<A<Object>>) x149;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<A<FutureOr<Object>>>) x150;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<A<A<Object>>>) x151;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<A<A<FutureOr<Object>>>>) x152;
//^
// [analyzer] unspecified
//                                                       ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicCoBound<Object>) x153;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(FcovCyclicCoBound<FutureOr<Object>>) x154;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(FcovCyclicCoBound<Function(Function(Object))>) x155;
//^
// [analyzer] unspecified
//                                                             ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(FcovCyclicCoBound<Function(Function(FutureOr<Object>))>) x156;
//^
// [analyzer] unspecified
//                                                                       ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(CFcov<Object>) x157;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<FutureOr<Object>>) x158;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<Fcov<Object>>) x159;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<Fcov<FutureOr<Object>>>) x160;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<Fcov<Fcov<Object>>>) x161;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<Fcov<Fcov<FutureOr<Object>>>>) x162;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcon<Object>) x163;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function(CFcon<FutureOr<Object>>) x164;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function(CFinv<Object>) x165;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function(CFinv<FutureOr<Object>>) x166;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function(CFunu<Object>) x167;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function(CFunu<FutureOr<Object>>) x168;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function(CcovBound<Object>) x169;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function(CcovBound<FutureOr<Object>>) x170;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function(CcovCyclicBound<Object>) x171;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<FutureOr<Object>>) x172;
//^
// [analyzer] unspecified
//                                                 ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<A<Object>>) x173;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<A<FutureOr<Object>>>) x174;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<A<A<Object>>>) x175;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<A<A<FutureOr<Object>>>>) x176;
//^
// [analyzer] unspecified
//                                                       ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicCoBound<Object>) x177;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(CcovCyclicCoBound<FutureOr<Object>>) x178;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(CcovCyclicCoBound<Function(Function(Object))>) x179;
//^
// [analyzer] unspecified
//                                                             ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(CcovCyclicCoBound<Function(Function(FutureOr<Object>))>) x180;
//^
// [analyzer] unspecified
//                                                                       ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(FcovBound<Object>) Function() x181;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function(FcovBound<FutureOr<Object>>) Function() x182;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function(FcovCyclicBound<Object>) Function() x183;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<FutureOr<Object>>) Function() x184;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<A<Object>>) Function() x185;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<A<FutureOr<Object>>>) Function() x186;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<A<A<Object>>>) Function() x187;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicBound<A<A<FutureOr<Object>>>>) Function() x188;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function(FcovCyclicCoBound<Object>) Function() x189;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(FcovCyclicCoBound<FutureOr<Object>>) Function() x190;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(FcovCyclicCoBound<Function(Function(Object))>) Function() x191;
//^
// [analyzer] unspecified
//                                                                        ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(FcovCyclicCoBound<Function(Function(FutureOr<Object>))>)
//^
// [analyzer] unspecified
      Function() x192;
//               ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function(CFcov<Object>) Function() x193;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<FutureOr<Object>>) Function() x194;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<Fcov<Object>>) Function() x195;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<Fcov<FutureOr<Object>>>) Function() x196;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<Fcov<Fcov<Object>>>) Function() x197;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcov<Fcov<Fcov<FutureOr<Object>>>>) Function() x198;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function(CFcon<Object>) Function() x199;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function(CFcon<FutureOr<Object>>) Function() x200;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function(CFinv<Object>) Function() x201;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function(CFinv<FutureOr<Object>>) Function() x202;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function(CFunu<Object>) Function() x203;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function(CFunu<FutureOr<Object>>) Function() x204;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function(CcovBound<Object>) Function() x205;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function(CcovBound<FutureOr<Object>>) Function() x206;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function(CcovCyclicBound<Object>) Function() x207;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<FutureOr<Object>>) Function() x208;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<A<Object>>) Function() x209;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<A<FutureOr<Object>>>) Function() x210;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<A<A<Object>>>) Function() x211;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicBound<A<A<FutureOr<Object>>>>) Function() x212;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function(CcovCyclicCoBound<Object>) Function() x213;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(CcovCyclicCoBound<FutureOr<Object>>) Function() x214;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(CcovCyclicCoBound<Function(Function(Object))>) Function() x215;
//^
// [analyzer] unspecified
//                                                                        ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function(CcovCyclicCoBound<Function(Function(FutureOr<Object>))>)
//^
// [analyzer] unspecified
      Function() x216;
//               ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function<Y extends FcovBound<Object>>() x217;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function<Y extends FcovBound<FutureOr<Object>>>() x218;
//^
// [analyzer] unspecified
//                                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function<Y extends FcovCyclicBound<Object>>() x219;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends FcovCyclicBound<FutureOr<Object>>>() x220;
//^
// [analyzer] unspecified
//                                                             ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends FcovCyclicBound<A<Object>>>() x221;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends FcovCyclicBound<A<FutureOr<Object>>>>() x222;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends FcovCyclicBound<A<A<Object>>>>() x223;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends FcovCyclicBound<A<A<FutureOr<Object>>>>>() x224;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends FcovCyclicCoBound<Object>>() x225;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function<Y extends FcovCyclicCoBound<FutureOr<Object>>>() x226;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function<Y extends FcovCyclicCoBound<Function(Function(Object))>>() x227;
//^
// [analyzer] unspecified
//                                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function<
      Y extends FcovCyclicCoBound<Function(Function(FutureOr<Object>))>>() x228;
//^
// [analyzer] unspecified
//                                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function<Y extends CFcov<Object>>() x229;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends CFcov<FutureOr<Object>>>() x230;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends CFcov<Fcov<Object>>>() x231;
//^
// [analyzer] unspecified
//                                               ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends CFcov<Fcov<FutureOr<Object>>>>() x232;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends CFcov<Fcov<Fcov<Object>>>>() x233;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends CFcov<Fcov<Fcov<FutureOr<Object>>>>>() x234;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends CFcon<Object>>() x235;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function<Y extends CFcon<FutureOr<Object>>>() x236;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function<Y extends CFinv<Object>>() x237;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function<Y extends CFinv<FutureOr<Object>>>() x238;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function<Y extends CFunu<Object>>() x239;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function<Y extends CFunu<FutureOr<Object>>>() x240;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function<Y extends CcovBound<Object>>() x241;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function<Y extends CcovBound<FutureOr<Object>>>() x242;
//^
// [analyzer] unspecified
//                                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function<Y extends CcovCyclicBound<Object>>() x243;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends CcovCyclicBound<FutureOr<Object>>>() x244;
//^
// [analyzer] unspecified
//                                                             ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends CcovCyclicBound<A<Object>>>() x245;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends CcovCyclicBound<A<FutureOr<Object>>>>() x246;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends CcovCyclicBound<A<A<Object>>>>() x247;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends CcovCyclicBound<A<A<FutureOr<Object>>>>>() x248;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends CcovCyclicCoBound<Object>>() x249;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function<Y extends CcovCyclicCoBound<FutureOr<Object>>>() x250;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function<Y extends CcovCyclicCoBound<Function(Function(Object))>>() x251;
//^
// [analyzer] unspecified
//                                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function<
      Y extends CcovCyclicCoBound<Function(Function(FutureOr<Object>))>>() x252;
//^
// [analyzer] unspecified
//                                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function<Y extends A<FcovBound<Object>>>() x253;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function<Y extends A<FcovBound<FutureOr<Object>>>>() x254;
//^
// [analyzer] unspecified
//                                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  void Function<Y extends A<FcovCyclicBound<Object>>>() x255;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends A<FcovCyclicBound<FutureOr<Object>>>>() x256;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends A<FcovCyclicBound<A<Object>>>>() x257;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends A<FcovCyclicBound<A<FutureOr<Object>>>>>() x258;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends A<FcovCyclicBound<A<A<Object>>>>>() x259;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends A<FcovCyclicBound<A<A<FutureOr<Object>>>>>>() x260;
//^
// [analyzer] unspecified
//                                                                      ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  void Function<Y extends A<FcovCyclicCoBound<Object>>>() x261;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function<Y extends A<FcovCyclicCoBound<FutureOr<Object>>>>() x262;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function<Y extends A<FcovCyclicCoBound<Function(Function(Object))>>>()
//^
// [analyzer] unspecified
      x263;
//    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function<
      Y extends A<
          FcovCyclicCoBound<Function(Function(FutureOr<Object>))>>>() x264;
//^
// [analyzer] unspecified
//                                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  void Function<Y extends A<CFcov<Object>>>() x265;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends A<CFcov<FutureOr<Object>>>>() x266;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends A<CFcov<Fcov<Object>>>>() x267;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends A<CFcov<Fcov<FutureOr<Object>>>>>() x268;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends A<CFcov<Fcov<Fcov<Object>>>>>() x269;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends A<CFcov<Fcov<Fcov<FutureOr<Object>>>>>>() x270;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  void Function<Y extends A<CFcon<Object>>>() x271;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function<Y extends A<CFcon<FutureOr<Object>>>>() x272;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  void Function<Y extends A<CFinv<Object>>>() x273;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function<Y extends A<CFinv<FutureOr<Object>>>>() x274;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  void Function<Y extends A<CFunu<Object>>>() x275;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function<Y extends A<CFunu<FutureOr<Object>>>>() x276;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  void Function<Y extends A<CcovBound<Object>>>() x277;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function<Y extends A<CcovBound<FutureOr<Object>>>>() x278;
//^
// [analyzer] unspecified
//                                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  void Function<Y extends A<CcovCyclicBound<Object>>>() x279;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends A<CcovCyclicBound<FutureOr<Object>>>>() x280;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends A<CcovCyclicBound<A<Object>>>>() x281;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends A<CcovCyclicBound<A<FutureOr<Object>>>>>() x282;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends A<CcovCyclicBound<A<A<Object>>>>>() x283;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends A<CcovCyclicBound<A<A<FutureOr<Object>>>>>>() x284;
//^
// [analyzer] unspecified
//                                                                      ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  void Function<Y extends A<CcovCyclicCoBound<Object>>>() x285;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function<Y extends A<CcovCyclicCoBound<FutureOr<Object>>>>() x286;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function<Y extends A<CcovCyclicCoBound<Function(Function(Object))>>>()
//^
// [analyzer] unspecified
      x287;
//    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  void Function<
      Y extends A<
          CcovCyclicCoBound<Function(Function(FutureOr<Object>))>>>() x288;
//^
// [analyzer] unspecified
//                                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  Finv<FcovBound<Object>> x289;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  Finv<FcovBound<FutureOr<Object>>> x290;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  Finv<FcovCyclicBound<Object>> x291;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Finv<FcovCyclicBound<FutureOr<Object>>> x292;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Finv<FcovCyclicBound<A<Object>>> x293;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Finv<FcovCyclicBound<A<FutureOr<Object>>>> x294;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Finv<FcovCyclicBound<A<A<Object>>>> x295;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Finv<FcovCyclicBound<A<A<FutureOr<Object>>>>> x296;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Finv<FcovCyclicCoBound<Object>> x297;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  Finv<FcovCyclicCoBound<FutureOr<Object>>> x298;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  Finv<FcovCyclicCoBound<Function(Function(Object))>> x299;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  Finv<FcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x300;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  Finv<CFcov<Object>> x301;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Finv<CFcov<FutureOr<Object>>> x302;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Finv<CFcov<Fcov<Object>>> x303;
//^
// [analyzer] unspecified
//                          ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Finv<CFcov<Fcov<FutureOr<Object>>>> x304;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Finv<CFcov<Fcov<Fcov<Object>>>> x305;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Finv<CFcov<Fcov<Fcov<FutureOr<Object>>>>> x306;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Finv<CFcon<Object>> x307;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  Finv<CFcon<FutureOr<Object>>> x308;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  Finv<CFinv<Object>> x309;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  Finv<CFinv<FutureOr<Object>>> x310;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  Finv<CFunu<Object>> x311;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  Finv<CFunu<FutureOr<Object>>> x312;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  Finv<CcovBound<Object>> x313;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  Finv<CcovBound<FutureOr<Object>>> x314;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  Finv<CcovCyclicBound<Object>> x315;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Finv<CcovCyclicBound<FutureOr<Object>>> x316;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Finv<CcovCyclicBound<A<Object>>> x317;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Finv<CcovCyclicBound<A<FutureOr<Object>>>> x318;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Finv<CcovCyclicBound<A<A<Object>>>> x319;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Finv<CcovCyclicBound<A<A<FutureOr<Object>>>>> x320;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Finv<CcovCyclicCoBound<Object>> x321;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  Finv<CcovCyclicCoBound<FutureOr<Object>>> x322;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  Finv<CcovCyclicCoBound<Function(Function(Object))>> x323;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  Finv<CcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x324;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  Funu<FcovBound<Object>> x325;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  Funu<FcovBound<FutureOr<Object>>> x326;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FcovBound'.
  Funu<FcovCyclicBound<Object>> x327;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Funu<FcovCyclicBound<FutureOr<Object>>> x328;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Funu<FcovCyclicBound<A<Object>>> x329;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Funu<FcovCyclicBound<A<FutureOr<Object>>>> x330;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Funu<FcovCyclicBound<A<A<Object>>>> x331;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Funu<FcovCyclicBound<A<A<FutureOr<Object>>>>> x332;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FcovCyclicBound'.
  Funu<FcovCyclicCoBound<Object>> x333;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  Funu<FcovCyclicCoBound<FutureOr<Object>>> x334;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  Funu<FcovCyclicCoBound<Function(Function(Object))>> x335;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  Funu<FcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x336;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FcovCyclicCoBound'.
  Funu<CFcov<Object>> x337;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Funu<CFcov<FutureOr<Object>>> x338;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Funu<CFcov<Fcov<Object>>> x339;
//^
// [analyzer] unspecified
//                          ^
// [cfe] Type argument 'Object Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Funu<CFcov<Fcov<FutureOr<Object>>>> x340;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'FutureOr<Object> Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Funu<CFcov<Fcov<Fcov<Object>>>> x341;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Funu<CFcov<Fcov<Fcov<FutureOr<Object>>>>> x342;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object> Function() Function()' doesn't conform to the bound 'X Function()' of the type variable 'X' on 'CFcov'.
  Funu<CFcon<Object>> x343;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  Funu<CFcon<FutureOr<Object>>> x344;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CFcon'.
  Funu<CFinv<Object>> x345;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  Funu<CFinv<FutureOr<Object>>> x346;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'X Function(X)' of the type variable 'X' on 'CFinv'.
  Funu<CFunu<Object>> x347;
//^
// [analyzer] unspecified
//                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  Funu<CFunu<FutureOr<Object>>> x348;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function()' of the type variable 'X' on 'CFunu'.
  Funu<CcovBound<Object>> x349;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  Funu<CcovBound<FutureOr<Object>>> x350;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'CcovBound'.
  Funu<CcovCyclicBound<Object>> x351;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Funu<CcovCyclicBound<FutureOr<Object>>> x352;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Funu<CcovCyclicBound<A<Object>>> x353;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Funu<CcovCyclicBound<A<FutureOr<Object>>>> x354;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Funu<CcovCyclicBound<A<A<Object>>>> x355;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Funu<CcovCyclicBound<A<A<FutureOr<Object>>>>> x356;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'CcovCyclicBound'.
  Funu<CcovCyclicCoBound<Object>> x357;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  Funu<CcovCyclicCoBound<FutureOr<Object>>> x358;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  Funu<CcovCyclicCoBound<Function(Function(Object))>> x359;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
  Funu<CcovCyclicCoBound<Function(Function(FutureOr<Object>))>> x360;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'CcovCyclicCoBound'.
}

void testInvariantSuperboundError<N extends Null>() {
  // --- Near-top type in an invariant position, not super-bounded.
  FinvBound<Object> x1;
//^
// [analyzer] unspecified
//                  ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  FinvBound<FutureOr<Object>> x2;
//^
// [analyzer] unspecified
//                            ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  FinvCyclicBound<Object> x3;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<FutureOr<Object>> x4;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<A<Object>> x5;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<A<FutureOr<Object>>> x6;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<A<A<Object>>> x7;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<A<A<FutureOr<Object>>>> x8;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicCoBound<Object> x9;
//^
// [analyzer] unspecified
//                          ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  FinvCyclicCoBound<FutureOr<Object>> x10;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  FinvCyclicCoBound<Function(Function(Object))> x11;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  FinvCyclicCoBound<Function(Function(FutureOr<Object>))> x12;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.

  // --- Same non-super-bounded types in a context.
  A<FinvBound<Object>> x13;
//^
// [analyzer] unspecified
//                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  A<FinvBound<FutureOr<Object>>> x14;
//^
// [analyzer] unspecified
//                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  A<FinvCyclicBound<Object>> x15;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  A<FinvCyclicBound<FutureOr<Object>>> x16;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  A<FinvCyclicBound<A<Object>>> x17;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  A<FinvCyclicBound<A<FutureOr<Object>>>> x18;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  A<FinvCyclicBound<A<A<Object>>>> x19;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  A<FinvCyclicBound<A<A<FutureOr<Object>>>>> x20;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  A<FinvCyclicCoBound<Object>> x21;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  A<FinvCyclicCoBound<FutureOr<Object>>> x22;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  A<FinvCyclicCoBound<Function(Function(Object))>> x23;
//^
// [analyzer] unspecified
//                                                 ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  A<FinvCyclicCoBound<Function(Function(FutureOr<Object>))>> x24;
//^
// [analyzer] unspecified
//                                                           ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  FinvBound<Object> Function() x25;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  FinvBound<FutureOr<Object>> Function() x26;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  FinvCyclicBound<Object> Function() x27;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<FutureOr<Object>> Function() x28;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<A<Object>> Function() x29;
//^
// [analyzer] unspecified
//                                      ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<A<FutureOr<Object>>> Function() x30;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<A<A<Object>>> Function() x31;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicBound<A<A<FutureOr<Object>>>> Function() x32;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  FinvCyclicCoBound<Object> Function() x33;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  FinvCyclicCoBound<FutureOr<Object>> Function() x34;
//^
// [analyzer] unspecified
//                                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  FinvCyclicCoBound<Function(Function(Object))> Function() x35;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  FinvCyclicCoBound<Function(Function(FutureOr<Object>))> Function() x36;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(void Function(FinvBound<Object>)) x37;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function(void Function(FinvBound<FutureOr<Object>>)) x38;
//^
// [analyzer] unspecified
//                                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function(void Function(FinvCyclicBound<Object>)) x39;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(void Function(FinvCyclicBound<FutureOr<Object>>)) x40;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(void Function(FinvCyclicBound<A<Object>>)) x41;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(void Function(FinvCyclicBound<A<FutureOr<Object>>>)) x42;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(void Function(FinvCyclicBound<A<A<Object>>>)) x43;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(void Function(FinvCyclicBound<A<A<FutureOr<Object>>>>)) x44;
//^
// [analyzer] unspecified
//                                                                      ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(void Function(FinvCyclicCoBound<Object>)) x45;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(void Function(FinvCyclicCoBound<FutureOr<Object>>)) x46;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(void Function(FinvCyclicCoBound<Function(Function(Object))>))
//^
// [analyzer] unspecified
      x47;
//    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(
      void Function(
          FinvCyclicCoBound<Function(Function(FutureOr<Object>))>)) x48;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(FinvBound<Object>) x49;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function(FinvBound<FutureOr<Object>>) x50;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function(FinvCyclicBound<Object>) x51;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<FutureOr<Object>>) x52;
//^
// [analyzer] unspecified
//                                                 ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<A<Object>>) x53;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<A<FutureOr<Object>>>) x54;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<A<A<Object>>>) x55;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<A<A<FutureOr<Object>>>>) x56;
//^
// [analyzer] unspecified
//                                                       ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicCoBound<Object>) x57;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(FinvCyclicCoBound<FutureOr<Object>>) x58;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(FinvCyclicCoBound<Function(Function(Object))>) x59;
//^
// [analyzer] unspecified
//                                                             ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(FinvCyclicCoBound<Function(Function(FutureOr<Object>))>) x60;
//^
// [analyzer] unspecified
//                                                                       ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(FinvBound<Object>) Function() x61;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function(FinvBound<FutureOr<Object>>) Function() x62;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function(FinvCyclicBound<Object>) Function() x63;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<FutureOr<Object>>) Function() x64;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<A<Object>>) Function() x65;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<A<FutureOr<Object>>>) Function() x66;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<A<A<Object>>>) Function() x67;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicBound<A<A<FutureOr<Object>>>>) Function() x68;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function(FinvCyclicCoBound<Object>) Function() x69;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(FinvCyclicCoBound<FutureOr<Object>>) Function() x70;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(FinvCyclicCoBound<Function(Function(Object))>) Function() x71;
//^
// [analyzer] unspecified
//                                                                        ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function(FinvCyclicCoBound<Function(Function(FutureOr<Object>))>)
//^
// [analyzer] unspecified
      Function() x72;
//               ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function<Y extends FinvBound<Object>>() x73;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function<Y extends FinvBound<FutureOr<Object>>>() x74;
//^
// [analyzer] unspecified
//                                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function<Y extends FinvCyclicBound<Object>>() x75;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends FinvCyclicBound<FutureOr<Object>>>() x76;
//^
// [analyzer] unspecified
//                                                             ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends FinvCyclicBound<A<Object>>>() x77;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends FinvCyclicBound<A<FutureOr<Object>>>>() x78;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends FinvCyclicBound<A<A<Object>>>>() x79;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends FinvCyclicBound<A<A<FutureOr<Object>>>>>() x80;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends FinvCyclicCoBound<Object>>() x81;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function<Y extends FinvCyclicCoBound<FutureOr<Object>>>() x82;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function<Y extends FinvCyclicCoBound<Function(Function(Object))>>() x83;
//^
// [analyzer] unspecified
//                                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function<
      Y extends FinvCyclicCoBound<Function(Function(FutureOr<Object>))>>() x84;
//^
// [analyzer] unspecified
//                                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function<Y extends A<FinvBound<Object>>>() x85;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function<Y extends A<FinvBound<FutureOr<Object>>>>() x86;
//^
// [analyzer] unspecified
//                                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  void Function<Y extends A<FinvCyclicBound<Object>>>() x87;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends A<FinvCyclicBound<FutureOr<Object>>>>() x88;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends A<FinvCyclicBound<A<Object>>>>() x89;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends A<FinvCyclicBound<A<FutureOr<Object>>>>>() x90;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends A<FinvCyclicBound<A<A<Object>>>>>() x91;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends A<FinvCyclicBound<A<A<FutureOr<Object>>>>>>() x92;
//^
// [analyzer] unspecified
//                                                                      ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  void Function<Y extends A<FinvCyclicCoBound<Object>>>() x93;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function<Y extends A<FinvCyclicCoBound<FutureOr<Object>>>>() x94;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function<Y extends A<FinvCyclicCoBound<Function(Function(Object))>>>()
//^
// [analyzer] unspecified
      x95;
//    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  void Function<
      Y extends A<
          FinvCyclicCoBound<Function(Function(FutureOr<Object>))>>>() x96;
//^
// [analyzer] unspecified
//                                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  Finv<FinvBound<Object>> x97;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  Finv<FinvBound<FutureOr<Object>>> x98;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  Finv<FinvCyclicBound<Object>> x99;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Finv<FinvCyclicBound<FutureOr<Object>>> x100;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Finv<FinvCyclicBound<A<Object>>> x101;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Finv<FinvCyclicBound<A<FutureOr<Object>>>> x102;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Finv<FinvCyclicBound<A<A<Object>>>> x103;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Finv<FinvCyclicBound<A<A<FutureOr<Object>>>>> x104;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Finv<FinvCyclicCoBound<Object>> x105;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  Finv<FinvCyclicCoBound<FutureOr<Object>>> x106;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  Finv<FinvCyclicCoBound<Function(Function(Object))>> x107;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  Finv<FinvCyclicCoBound<Function(Function(FutureOr<Object>))>> x108;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  Funu<FinvBound<Object>> x109;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  Funu<FinvBound<FutureOr<Object>>> x110;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FinvBound'.
  Funu<FinvCyclicBound<Object>> x111;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Funu<FinvCyclicBound<FutureOr<Object>>> x112;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Funu<FinvCyclicBound<A<Object>>> x113;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Funu<FinvCyclicBound<A<FutureOr<Object>>>> x114;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Funu<FinvCyclicBound<A<A<Object>>>> x115;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Funu<FinvCyclicBound<A<A<FutureOr<Object>>>>> x116;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FinvCyclicBound'.
  Funu<FinvCyclicCoBound<Object>> x117;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  Funu<FinvCyclicCoBound<FutureOr<Object>>> x118;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  Funu<FinvCyclicCoBound<Function(Function(Object))>> x119;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
  Funu<FinvCyclicCoBound<Function(Function(FutureOr<Object>))>> x120;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
}

void testVarianceLessSuperboundError<N extends Null>() {
  // --- Near-top type in a variance-less position, not super-bounded.
  FunuBound<Object> x1;
//^
// [analyzer] unspecified
//                  ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  FunuBound<FutureOr<Object>> x2;
//^
// [analyzer] unspecified
//                            ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  FunuCyclicBound<Object> x3;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<FutureOr<Object>> x4;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<A<Object>> x5;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<A<FutureOr<Object>>> x6;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<A<A<Object>>> x7;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<A<A<FutureOr<Object>>>> x8;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicCoBound<Object> x9;
//^
// [analyzer] unspecified
//                          ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  FunuCyclicCoBound<FutureOr<Object>> x10;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  FunuCyclicCoBound<Function(Function(Object))> x13;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  FunuCyclicCoBound<Function(Function(FutureOr<Object>))> x14;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.

  // --- Same non-super-bounded types in a context.
  A<FunuBound<Object>> x19;
//^
// [analyzer] unspecified
//                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  A<FunuBound<FutureOr<Object>>> x20;
//^
// [analyzer] unspecified
//                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  A<FunuCyclicBound<Object>> x21;
//^
// [analyzer] unspecified
//                           ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  A<FunuCyclicBound<FutureOr<Object>>> x22;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  A<FunuCyclicBound<A<Object>>> x23;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  A<FunuCyclicBound<A<FutureOr<Object>>>> x24;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  A<FunuCyclicBound<A<A<Object>>>> x25;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  A<FunuCyclicBound<A<A<FutureOr<Object>>>>> x26;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  A<FunuCyclicCoBound<Object>> x27;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  A<FunuCyclicCoBound<FutureOr<Object>>> x28;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  A<FunuCyclicCoBound<Function(Function(Object))>> x31;
//^
// [analyzer] unspecified
//                                                 ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  A<FunuCyclicCoBound<Function(Function(FutureOr<Object>))>> x32;
//^
// [analyzer] unspecified
//                                                           ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  FunuBound<Object> Function() x37;
//^
// [analyzer] unspecified
//                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  FunuBound<FutureOr<Object>> Function() x38;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  FunuCyclicBound<Object> Function() x39;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<FutureOr<Object>> Function() x40;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<A<Object>> Function() x41;
//^
// [analyzer] unspecified
//                                      ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<A<FutureOr<Object>>> Function() x42;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<A<A<Object>>> Function() x43;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicBound<A<A<FutureOr<Object>>>> Function() x44;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  FunuCyclicCoBound<Object> Function() x45;
//^
// [analyzer] unspecified
//                                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  FunuCyclicCoBound<FutureOr<Object>> Function() x46;
//^
// [analyzer] unspecified
//                                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  FunuCyclicCoBound<Function(Function(Object))> Function() x49;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  FunuCyclicCoBound<Function(Function(FutureOr<Object>))> Function() x50;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(void Function(FunuBound<Object>)) x55;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function(void Function(FunuBound<FutureOr<Object>>)) x56;
//^
// [analyzer] unspecified
//                                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function(void Function(FunuCyclicBound<Object>)) x57;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(void Function(FunuCyclicBound<FutureOr<Object>>)) x58;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(void Function(FunuCyclicBound<A<Object>>)) x59;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(void Function(FunuCyclicBound<A<FutureOr<Object>>>)) x60;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(void Function(FunuCyclicBound<A<A<Object>>>)) x61;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(void Function(FunuCyclicBound<A<A<FutureOr<Object>>>>)) x62;
//^
// [analyzer] unspecified
//                                                                      ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(void Function(FunuCyclicCoBound<Object>)) x63;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(void Function(FunuCyclicCoBound<FutureOr<Object>>)) x64;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(void Function(FunuCyclicCoBound<Function(Function(Object))>))
//^
// [analyzer] unspecified
      x67;
//    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(
      void Function(
          FunuCyclicCoBound<Function(Function(FutureOr<Object>))>)) x68;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(FunuBound<Object>) x73;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function(FunuBound<FutureOr<Object>>) x74;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function(FunuCyclicBound<Object>) x75;
//^
// [analyzer] unspecified
//                                       ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<FutureOr<Object>>) x76;
//^
// [analyzer] unspecified
//                                                 ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<A<Object>>) x77;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<A<FutureOr<Object>>>) x78;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<A<A<Object>>>) x79;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<A<A<FutureOr<Object>>>>) x80;
//^
// [analyzer] unspecified
//                                                       ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicCoBound<Object>) x81;
//^
// [analyzer] unspecified
//                                         ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(FunuCyclicCoBound<FutureOr<Object>>) x82;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(FunuCyclicCoBound<Function(Function(Object))>) x85;
//^
// [analyzer] unspecified
//                                                             ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(FunuCyclicCoBound<Function(Function(FutureOr<Object>))>) x86;
//^
// [analyzer] unspecified
//                                                                       ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(FunuBound<Object>) Function() x91;
//^
// [analyzer] unspecified
//                                            ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function(FunuBound<FutureOr<Object>>) Function() x92;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function(FunuCyclicBound<Object>) Function() x93;
//^
// [analyzer] unspecified
//                                                  ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<FutureOr<Object>>) Function() x94;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<A<Object>>) Function() x95;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<A<FutureOr<Object>>>) Function() x96;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<A<A<Object>>>) Function() x97;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicBound<A<A<FutureOr<Object>>>>) Function() x98;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function(FunuCyclicCoBound<Object>) Function() x99;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(FunuCyclicCoBound<FutureOr<Object>>) Function() x100;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(FunuCyclicCoBound<Function(Function(Object))>) Function() x103;
//^
// [analyzer] unspecified
//                                                                        ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function(FunuCyclicCoBound<Function(Function(FutureOr<Object>))>)
//^
// [analyzer] unspecified
      Function() x104;
//               ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function<Y extends FunuBound<Object>>() x109;
//^
// [analyzer] unspecified
//                                             ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function<Y extends FunuBound<FutureOr<Object>>>() x110;
//^
// [analyzer] unspecified
//                                                       ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function<Y extends FunuCyclicBound<Object>>() x111;
//^
// [analyzer] unspecified
//                                                   ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends FunuCyclicBound<FutureOr<Object>>>() x112;
//^
// [analyzer] unspecified
//                                                             ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends FunuCyclicBound<A<Object>>>() x113;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends FunuCyclicBound<A<FutureOr<Object>>>>() x114;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends FunuCyclicBound<A<A<Object>>>>() x115;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends FunuCyclicBound<A<A<FutureOr<Object>>>>>() x116;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends FunuCyclicCoBound<Object>>() x117;
//^
// [analyzer] unspecified
//                                                     ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function<Y extends FunuCyclicCoBound<FutureOr<Object>>>() x118;
//^
// [analyzer] unspecified
//                                                               ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function<Y extends FunuCyclicCoBound<Function(Function(Object))>>() x121;
//^
// [analyzer] unspecified
//                                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function<
      Y extends FunuCyclicCoBound<Function(Function(FutureOr<Object>))>>() x122;
//^
// [analyzer] unspecified
//                                                                         ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function<Y extends A<FunuBound<Object>>>() x127;
//^
// [analyzer] unspecified
//                                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function<Y extends A<FunuBound<FutureOr<Object>>>>() x128;
//^
// [analyzer] unspecified
//                                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  void Function<Y extends A<FunuCyclicBound<Object>>>() x129;
//^
// [analyzer] unspecified
//                                                      ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends A<FunuCyclicBound<FutureOr<Object>>>>() x130;
//^
// [analyzer] unspecified
//                                                                ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends A<FunuCyclicBound<A<Object>>>>() x131;
//^
// [analyzer] unspecified
//                                                         ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends A<FunuCyclicBound<A<FutureOr<Object>>>>>() x132;
//^
// [analyzer] unspecified
//                                                                   ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends A<FunuCyclicBound<A<A<Object>>>>>() x133;
//^
// [analyzer] unspecified
//                                                            ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends A<FunuCyclicBound<A<A<FutureOr<Object>>>>>>() x134;
//^
// [analyzer] unspecified
//                                                                      ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  void Function<Y extends A<FunuCyclicCoBound<Object>>>() x135;
//^
// [analyzer] unspecified
//                                                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function<Y extends A<FunuCyclicCoBound<FutureOr<Object>>>>() x136;
//^
// [analyzer] unspecified
//                                                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function<Y extends A<FunuCyclicCoBound<Function(Function(Object))>>>()
//^
// [analyzer] unspecified
      x139;
//    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  void Function<
      Y extends A<
          FunuCyclicCoBound<Function(Function(FutureOr<Object>))>>>() x140;
//^
// [analyzer] unspecified
//                                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  Finv<FunuBound<Object>> x145;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  Finv<FunuBound<FutureOr<Object>>> x146;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  Finv<FunuCyclicBound<Object>> x147;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Finv<FunuCyclicBound<FutureOr<Object>>> x148;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Finv<FunuCyclicBound<A<Object>>> x149;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Finv<FunuCyclicBound<A<FutureOr<Object>>>> x150;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Finv<FunuCyclicBound<A<A<Object>>>> x151;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Finv<FunuCyclicBound<A<A<FutureOr<Object>>>>> x152;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Finv<FunuCyclicCoBound<Object>> x153;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  Finv<FunuCyclicCoBound<FutureOr<Object>>> x154;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  Finv<FunuCyclicCoBound<Function(Function(Object))>> x157;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  Finv<FunuCyclicCoBound<Function(Function(FutureOr<Object>))>> x158;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  Funu<FunuBound<Object>> x163;
//^
// [analyzer] unspecified
//                        ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  Funu<FunuBound<FutureOr<Object>>> x164;
//^
// [analyzer] unspecified
//                                  ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'num' of the type variable 'X' on 'FunuBound'.
  Funu<FunuCyclicBound<Object>> x165;
//^
// [analyzer] unspecified
//                              ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Funu<FunuCyclicBound<FutureOr<Object>>> x166;
//^
// [analyzer] unspecified
//                                        ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Funu<FunuCyclicBound<A<Object>>> x167;
//^
// [analyzer] unspecified
//                                 ^
// [cfe] Type argument 'A<Object>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Funu<FunuCyclicBound<A<FutureOr<Object>>>> x168;
//^
// [analyzer] unspecified
//                                           ^
// [cfe] Type argument 'A<FutureOr<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Funu<FunuCyclicBound<A<A<Object>>>> x169;
//^
// [analyzer] unspecified
//                                    ^
// [cfe] Type argument 'A<A<Object>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Funu<FunuCyclicBound<A<A<FutureOr<Object>>>>> x170;
//^
// [analyzer] unspecified
//                                              ^
// [cfe] Type argument 'A<A<FutureOr<Object>>>' doesn't conform to the bound 'A<X>' of the type variable 'X' on 'FunuCyclicBound'.
  Funu<FunuCyclicCoBound<Object>> x171;
//^
// [analyzer] unspecified
//                                ^
// [cfe] Type argument 'Object' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  Funu<FunuCyclicCoBound<FutureOr<Object>>> x172;
//^
// [analyzer] unspecified
//                                          ^
// [cfe] Type argument 'FutureOr<Object>' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  Funu<FunuCyclicCoBound<Function(Function(Object))>> x175;
//^
// [analyzer] unspecified
//                                                    ^
// [cfe] Type argument 'dynamic Function(dynamic Function(Object))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  Funu<FunuCyclicCoBound<Function(Function(FutureOr<Object>))>> x176;
//^
// [analyzer] unspecified
//                                                              ^
// [cfe] Type argument 'dynamic Function(dynamic Function(FutureOr<Object>))' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
}

void testVarianceLessSuperbound<N extends Never>() {
  FunuCyclicCoBound<Function(Never)> x1;
//^
// [analyzer] unspecified
//                                   ^
// [cfe] Type argument 'dynamic Function(Never)' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
  FunuCyclicCoBound<Function(N)> x2;
//^
// [analyzer] unspecified
//                               ^
// [cfe] Type argument 'dynamic Function(N)' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FunuCyclicCoBound'.
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
//       ^
// [analyzer] unspecified
//                         ^
// [cfe] Type argument 'dynamic Function(Never)' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
// [cfe] Inferred type argument 'dynamic Function(Never)' doesn't conform to the bound 'dynamic Function(Y)' of the type variable 'Y' on 'AinvCyclicCoBound'.

    // We do not use `source` in further tests, because the type of `source`
    // is an error, and we do not generally test error-on-error situations.
  }
}

void testNested() {
  void f(B<AinvCyclicCoBound> source) {
//       ^
// [analyzer] unspecified
//                            ^
// [cfe] Type argument 'AinvCyclicCoBound<dynamic Function(Never) Function(dynamic Function(Never)), dynamic Function(Never)>' doesn't conform to the bound 'B<X>' of the type variable 'X' on 'B'.
// [cfe] Type argument 'dynamic Function(Never)' doesn't conform to the bound 'dynamic Function(X)' of the type variable 'X' on 'FinvCyclicCoBound'.
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
