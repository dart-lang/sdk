// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import '../../static_type_helper.dart';

// For the motivational issue, see
// https://github.com/dart-lang/language/issues/1194

import 'dart:async';

class A {}

class A2 extends A {}

extension type EA(A? it) {}

class B<X> {}

T foo1<T extends Object>(T? t, dynamic r) => r as T;
bar1(FutureOr<Object?> x) => foo1(x, "")..expectStaticType<Exactly<Object>>();
//                           ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'FutureOr<Object?>' doesn't conform to the bound 'Object' of the type variable 'T' on 'foo1'.
//                                        ^
// [cfe] Type argument 'Object Function(Object)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                                         ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

T foo2<T extends num>(T? t, dynamic r) => r as T;
bar2(Null x) => foo2(x, 0)..expectStaticType<Exactly<num>>();
//              ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'Null' doesn't conform to the bound 'num' of the type variable 'T' on 'foo2'.
//                          ^
// [cfe] Type argument 'num Function(num)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                           ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

T foo3<T extends Object>(T? t, dynamic r) => r as T;
bar3(EA x) => foo3(x, false)..expectStaticType<Exactly<Object>>();
//            ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'EA' doesn't conform to the bound 'Object' of the type variable 'T' on 'foo3'.
//                            ^
// [cfe] Type argument 'Object Function(Object)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                             ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

T foo4<T extends A>(T? t, dynamic r) => r as T;
bar4<S extends A?>(S x) => foo4(x, A())..expectStaticType<Exactly<A>>();
//                         ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'S' doesn't conform to the bound 'A' of the type variable 'T' on 'foo4'.
//                                       ^
// [cfe] Type argument 'A Function(A)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                                        ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

T foo5<T extends B<S>, S>(T? t, dynamic r) => r as T;
bar5<U extends B<U>?>(U x) =>
    foo5(x, B<Never>())..expectStaticType<Exactly<B<U>>>();
//  ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'U' doesn't conform to the bound 'B<S>' of the type variable 'T' on 'foo5'.
//                       ^
// [cfe] Type argument 'B<U> Function(B<U>)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                        ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

// The following test case checks that the implementations use `Object?` as the
// covariant replacement in the greatest closure of a type.
T foo6<T extends B<S>, S>(T? t, dynamic r) => r as T;
bar6(Null x) => foo6(x, B<Never>())..expectStaticType<Exactly<B<Object?>>>();
//              ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'Null' doesn't conform to the bound 'B<S>' of the type variable 'T' on 'foo6'.
//                                   ^
// [cfe] Type argument 'B<Object?> Function(B<Object?>)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                                    ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

T foo7<T extends B<Function(S)>, S>(T? t, dynamic r) => r as T;
bar7<U extends B<Function(U)>?>(U x) =>
    foo7(x, B<Never>())..expectStaticType<Exactly<B<Function(U)>>>();
//  ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'U' doesn't conform to the bound 'B<dynamic Function(S)>' of the type variable 'T' on 'foo7'.
//                       ^
// [cfe] Type argument 'B<dynamic Function(U)> Function(B<dynamic Function(U)>)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                        ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

// The following test case checks that the implementations use `Never` as the
// covariant replacement in the greatest closure of a type.p
T foo8<T extends B<Function(S)>, S extends A2>(T? t, dynamic r) => r as T;
bar8<U extends B<Function(A)>?>(U? x) =>
    foo8(x, B<Never>())..expectStaticType<Exactly<B<Function(A)>>>();
//  ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'U' doesn't conform to the bound 'B<dynamic Function(S)>' of the type variable 'T' on 'foo8'.
//                       ^
// [cfe] Type argument 'B<dynamic Function(A)> Function(B<dynamic Function(A)>)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                        ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

T foo9<T extends Object>(T? t, dynamic r) => r as T;
bar9<S extends num?>(S? x) => foo9(x, 0)..expectStaticType<Exactly<num>>();
//                            ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'S' doesn't conform to the bound 'Object' of the type variable 'T' on 'foo9'.
//                                        ^
// [cfe] Type argument 'num Function(num)' doesn't conform to the bound 'T Function(T)' of the type variable 'R' on 'StaticType|expectStaticType'.
//                                                         ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

// The following checks that the trivial case of the absent bound of the
// variable being inferred isn't affected.
T foo10<T>(T? t, dynamic r) => r as T;
bar10<U extends B<U>?>(U? x) => foo10(x, B<Never>());

main() {
  bar1(null);
  bar1("");
  bar1(0);

  bar2(null);

  bar3(EA(null));
  bar3(EA(A()));

  bar4(null);
  bar4(A());

  bar5(null);
  bar5(B<Never>());
  bar5(B<B<Never>>());

  bar6(null);

  bar7(null);
  bar7(B<Function(Object?)>());
  bar7(B<Function(B<Function(Never)>)>());

  bar8(null);
  bar8(B<Function(A)>());
  bar8(B<Function(Object?)>());

  bar9(null);
  bar9(0);
  bar9(.1);
}
