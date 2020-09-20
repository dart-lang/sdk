// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/
library test;

import 'dart:async';

typedef void Typedef1();
typedef void Typedef2<T>(T o);
typedef Typedef3 = void Function();
typedef Typedef4<T> = void Function(T);
typedef Typedef5<T> = void Function<S>(T, S);

boolType(bool /*normal|limited.bool*/ /*verbose.dart.core::bool*/ o1,
    bool? /*normal|limited.bool?*/ /*verbose.dart.core::bool?*/ o2) {}
numType(num /*normal|limited.num*/ /*verbose.dart.core::num*/ o1,
    num? /*normal|limited.num?*/ /*verbose.dart.core::num?*/ o2) {}
intType(int /*normal|limited.int*/ /*verbose.dart.core::int*/ o1,
    int? /*normal|limited.int?*/ /*verbose.dart.core::int?*/ o2) {}
doubleType(double /*normal|limited.double*/ /*verbose.dart.core::double*/ o1,
    double? /*normal|limited.double?*/ /*verbose.dart.core::double?*/ o2) {}
stringType(String /*normal|limited.String*/ /*verbose.dart.core::String*/ o1,
    String? /*normal|limited.String?*/ /*verbose.dart.core::String?*/ o2) {}
voidType(void /*void*/ o) {}
dynamicType(dynamic /*dynamic*/ o) {}
neverType(Never /*Never*/ o1, Never? /*Never?*/ o2) {}
objectType(Object /*normal|limited.Object*/ /*verbose.dart.core::Object*/ o1,
    Object? /*normal|limited.Object?*/ /*verbose.dart.core::Object?*/ o2) {}
genericType1(
    List<int>
        /*normal|limited.List<int>*/
        /*verbose.dart.core::List<dart.core::int>*/
        o1,
    List<int>?
        /*normal|limited.List<int>?*/
        /*verbose.dart.core::List<dart.core::int>?*/
        o2,
    List<int?>
        /*normal|limited.List<int?>*/
        /*verbose.dart.core::List<dart.core::int?>*/
        o3,
    List<int?>?
        /*normal|limited.List<int?>?*/
        /*verbose.dart.core::List<dart.core::int?>?*/
        o4) {}
genericType2(
    Map<int, String>
        /*normal|limited.Map<int, String>*/
        /*verbose.dart.core::Map<dart.core::int, dart.core::String>*/
        o1,
    Map<int, String?>?
        /*normal|limited.Map<int, String?>?*/
        /*verbose.dart.core::Map<dart.core::int, dart.core::String?>?*/
        o2) {}
futureOrType(
    FutureOr<int>
        /*normal|limited.FutureOr<int>*/
        /*verbose.FutureOr<dart.core::int>*/
        o1,
    FutureOr<int>?
        /*normal|limited.FutureOr<int>?*/
        /*verbose.FutureOr<dart.core::int>?*/
        o2,
    FutureOr<int?>
        /*normal|limited.FutureOr<int?>*/
        /*verbose.FutureOr<dart.core::int?>*/
        o3,
    FutureOr<int?>?
        /*normal|limited.FutureOr<int?>?*/
        /*verbose.FutureOr<dart.core::int?>?*/
        o4) {}
typeVariableType1<T>(T /*T%*/ o1, T? /*T?*/ o2) {}
typeVariableType2<T extends num>(T /*T*/ o1, T? /*T?*/ o2) {}
typeVariableType3<T extends S, S>(
    T /*T%*/ o1, S /*S%*/ p1, T? /*T?*/ o2, S? /*S?*/ p2) {}
typeVariableType4<T, S extends T>(
    T /*T%*/ o1, S /*S%*/ p1, T? /*T?*/ o2, S? /*S?*/ p2) {}
typeVariableType5<T extends Object>(T /*T*/ o1, T? /*T?*/ o2) {}
typeVariableType6<T extends Object?>(T /*T%*/ o1, T? /*T?*/ o2) {}
functionType1(void Function() /*void Function()*/ o1,
    void Function()? /*void Function()?*/ o2) {}
functionType2(
    int Function(int)
        /*normal|limited.int Function(int)*/
        /*verbose.dart.core::int Function(dart.core::int)*/
        o1,
    int? Function(int?)
        /*normal|limited.int? Function(int?)*/
        /*verbose.dart.core::int? Function(dart.core::int?)*/
        o2) {}
functionType3(
    int Function(int, String)
        /*normal|limited.int Function(int, String)*/
        /*verbose.dart.core::int Function(dart.core::int, dart.core::String)*/
        o) {}
functionType4(
    int Function([int])
        /*normal|limited.int Function([int])*/
        /*verbose.dart.core::int Function([dart.core::int])*/
        o1,
    int Function([int?])
        /*normal|limited.int Function([int?])*/
        /*verbose.dart.core::int Function([dart.core::int?])*/
        o2) {}
functionType5(
    int Function([int, String])
        /*normal|limited.int Function([int, String])*/
        /*verbose.dart.core::int Function([dart.core::int, dart.core::String])*/
        o) {}
functionType6(
    int Function({int a})
        /*normal|limited.int Function({a: int})*/
        /*verbose.dart.core::int Function({a: dart.core::int})*/
        o1,
    int Function({int? a})
        /*normal|limited.int Function({a: int?})*/
        /*verbose.dart.core::int Function({a: dart.core::int?})*/
        o2) {}
functionType7(
    int Function({int a, String b})
        /*normal|limited.int Function({a: int, b: String})*/
        /*verbose.dart.core::int Function({a: dart.core::int, b: dart.core::String})*/
        o) {}
functionType8(
    int Function(int, {String b})
        /*normal|limited.int Function(int, {b: String})*/
        /*verbose.dart.core::int Function(dart.core::int, {b: dart.core::String})*/
        o) {}
functionType9(
    int Function({required int a, String b})
        /*normal|limited.int Function({required a: int, b: String})*/
        /*verbose.dart.core::int Function({required a: dart.core::int, b: dart.core::String})*/
        o) {}
functionType10(
    int Function({int a, required String b})
        /*normal|limited.int Function({a: int, required b: String})*/
        /*verbose.dart.core::int Function({a: dart.core::int, required b: dart.core::String})*/
        o) {}
functionType11(
    int Function({required int a, required String b})
        /*normal|limited.int Function({required a: int, required b: String})*/
        /*verbose.dart.core::int Function({required a: dart.core::int, required b: dart.core::String})*/
        o) {}
genericFunctionType1(void Function<T>() /*void Function<T>()*/ o) {}
genericFunctionType2(T Function<T>(T, T?) /*T% Function<T>(T%, T?)*/ o) {}
genericFunctionType3(
    T Function<T, S>(T, S, T?, S?) /*T% Function<T, S>(T%, S%, T?, S?)*/ o) {}
genericFunctionType4(
    T Function<T extends num>([T, T?])
        /*normal|limited.T Function<T extends num>([T, T?])*/
        /*verbose.T Function<T extends dart.core::num>([T, T?])*/
        o) {}
// TODO(johnniwinther): Support interdependent function type variables.
//genericFunctionType5(T Function<T, S extends T>([T, S]) o) {}
//genericFunctionType6(T Function<T extends S, S>([T, S]) o) {}
typedefType1(
    Typedef1 /*normal|limited.Typedef1*/ /*verbose.test::Typedef1*/ o) {}
typedefType2(
    Typedef2
        /*normal|limited.Typedef2<dynamic>*/
        /*verbose.test::Typedef2<dynamic>*/
        o) {}
typedefType3(
    Typedef2<int>
        /*normal|limited.Typedef2<int>*/
        /*verbose.test::Typedef2<dart.core::int>*/
        o1,
    Typedef2<int?>
        /*normal|limited.Typedef2<int?>*/
        /*verbose.test::Typedef2<dart.core::int?>*/
        o2) {}
typedefType4(
    Typedef3 /*normal|limited.Typedef3*/ /*verbose.test::Typedef3*/ o) {}
typedefType5(
    Typedef4
        /*normal|limited.Typedef4<dynamic>*/
/*verbose.test::Typedef4<dynamic>*/
        o) {}
typedefType7(
    Typedef4<int>
        /*normal|limited.Typedef4<int>*/
        /*verbose.test::Typedef4<dart.core::int>*/
        o1,
    Typedef4<int>?
        /*normal|limited.Typedef4<int>?*/
        /*verbose.test::Typedef4<dart.core::int>?*/
        o2) {}
typedefType8(
    Typedef5
        /*normal|limited.Typedef5<dynamic>*/
        /*verbose.test::Typedef5<dynamic>*/
        o) {}
typedefType9(
    Typedef5<int>
        /*normal|limited.Typedef5<int>*/
        /*verbose.test::Typedef5<dart.core::int>*/
        o1,
    Typedef5<int?>?
        /*normal|limited.Typedef5<int?>?*/
        /*verbose.test::Typedef5<dart.core::int?>?*/
        o2) {}

method() {
  var /*dynamic Function<T>(T%, T?)*/ o1 =
      /*normal|limited.typeVariableType1*/
      /*verbose.test::typeVariableType1*/
      typeVariableType1;
  var /*normal|limited.dynamic Function<T extends num>(T, T?)*/
      /*verbose.dynamic Function<T extends dart.core::num>(T, T?)*/ o2 =
      /*normal|limited.typeVariableType2*/
      /*verbose.test::typeVariableType2*/
      typeVariableType2;
  var /*dynamic Function<T extends S%, S>(T%, S%, T?, S?)*/ o3 =
      /*normal|limited.typeVariableType3*/
      /*verbose.test::typeVariableType3*/
      typeVariableType3;
  var /*dynamic Function<T, S extends T%>(T%, S%, T?, S?)*/ o4 =
      /*normal|limited.typeVariableType4*/
      /*verbose.test::typeVariableType4*/
      typeVariableType4;
  var /*normal|limited.dynamic Function<T extends Object>(T, T?)*/
      /*verbose.dynamic Function<T extends dart.core::Object>(T, T?)*/ o5 =
      /*normal|limited.typeVariableType5*/
      /*verbose.test::typeVariableType5*/
      typeVariableType5;
  var /*normal|limited.dynamic Function<T extends Object?>(T%, T?)*/
      /*verbose.dynamic Function<T extends dart.core::Object?>(T%, T?)*/ o6 =
      /*normal|limited.typeVariableType6*/
      /*verbose.test::typeVariableType6*/
      typeVariableType6;

  var /*Never*/ bottom1 = throw '';
  var /*Never Function()*/ bottom2 = () => throw '';
}
