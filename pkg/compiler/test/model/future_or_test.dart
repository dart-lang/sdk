// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

main() {
  asyncTest(() async {
    var env = await TypeEnvironment.create("""
import 'dart:async';

Future<num> futureNum() async => null;
FutureOr<num> futureOrNum() async => null;

Future<int> futureInt() async => null;
FutureOr<int> futureOrInt() async => null;

Future<List<num>> futureListNum() async => null;
FutureOr<List<num>> futureOrListNum() async => null;

Future<Future<num>> futureFutureNum() async => null;
FutureOr<FutureOr<num>> futureOrFutureOrNum() async => null;

Future<Null> futureNull() async => null;
FutureOr<Null> futureOrNull() async => null;

void returnVoid() {}

class C<T> {
  Future<T> futureT() async => null;
  FutureOr<T> futureOrT() async => null;
}

main() {
  futureNum();
  futureOrNum();
  futureInt();
  futureOrInt();
  futureListNum();
  futureOrListNum();
  futureFutureNum();
  futureOrFutureOrNum();
  futureNull();
  futureOrNull();
  new C().futureT();
  new C().futureOrT();
}
""", options: [Flags.noSoundNullSafety]);
    FunctionType getFunctionType(String name, String expectedType,
        [ClassEntity cls]) {
      FunctionType type = env.getMemberType(name, cls);
      Expect.isNotNull(type,
          "Member $name not found${cls != null ? ' in class $cls' : ''}.");
      Expect.equals(
          expectedType,
          env.printType(type),
          "Unexpected type for $name"
          "${cls != null ? ' in class $cls' : ''}.");
      return type;
    }

    DartType getReturnType(String name, String expectedType,
        [ClassEntity cls]) {
      FunctionType type = env.getMemberType(name, cls);
      Expect.isNotNull(type,
          "Member $name not found${cls != null ? ' in class $cls' : ''}.");
      DartType returnType = type.returnType.withoutNullability;
      Expect.equals(
          expectedType,
          env.printType(returnType),
          "Unexpected return type for $name"
          "${cls != null ? ' in class $cls' : ''}.");
      return returnType;
    }

    DartType Object_ = env['Object'];

    DartType futureNum = getReturnType('futureNum', 'Future<num>');
    FutureOrType futureOrNum = getReturnType('futureOrNum', 'FutureOr<num>');
    DartType num_ = futureOrNum.typeArgument;

    DartType futureInt = getReturnType('futureInt', 'Future<int>');
    FutureOrType futureOrInt = getReturnType('futureOrInt', 'FutureOr<int>');
    DartType int_ = futureOrInt.typeArgument;

    DartType futureListNum =
        getReturnType('futureListNum', 'Future<List<num>>');
    FutureOrType futureOrListNum =
        getReturnType('futureOrListNum', 'FutureOr<List<num>>');
    DartType ListNum = futureOrListNum.typeArgument;

    DartType futureFutureNum =
        getReturnType('futureFutureNum', 'Future<Future<num>>');
    FutureOrType futureOrFutureOrNum =
        getReturnType('futureOrFutureOrNum', 'FutureOr<FutureOr<num>>');

    DartType futureNull = getReturnType('futureNull', 'Future<Null>');
    InterfaceType futureOrNull = getReturnType('futureOrNull', 'Future<Null>');
    DartType Null_ = futureOrNull.typeArguments.single;

    ClassEntity C = env.getClass('C');
    DartType futureT = getReturnType('futureT', 'Future<C.T>', C);
    FutureOrType futureOrT = getReturnType('futureOrT', 'FutureOr<C.T>', C);
    DartType T = futureOrT.typeArgument.withoutNullability;
    Expect.isTrue(futureOrT.containsTypeVariables);
    futureOrT.forEachTypeVariable((t) => Expect.equals(T, t));

    DartType returnVoid = getFunctionType('returnVoid', 'void Function()');
    DartType returnFutureNull =
        getFunctionType('futureOrNull', 'Future<Null>? Function()');

    List<DartType> all = [
      Object_,
      num_,
      int_,
      Null_,
      ListNum,
      T,
      futureNum,
      futureOrNum,
      futureInt,
      futureNull,
      futureListNum,
      futureT,
      futureOrInt,
      futureOrNull,
      futureOrListNum,
      futureFutureNum,
      futureOrFutureOrNum,
      futureOrT,
      returnVoid,
      returnFutureNull,
    ];

    Map<DartType, List<DartType>> expectedSubtypesMap = {
      num_: [futureOrNum, futureOrFutureOrNum],
      int_: [num_, futureOrInt, futureOrNum, futureOrFutureOrNum],
      ListNum: [futureOrListNum],
      T: [futureOrT],
      futureNum: [futureOrNum, futureOrFutureOrNum],
      futureInt: [futureNum, futureOrNum, futureOrInt, futureOrFutureOrNum],
      futureNull: [
        futureOrNull,
        futureNum,
        futureOrNum,
        futureInt,
        futureOrInt,
        futureListNum,
        futureOrListNum,
        futureFutureNum,
        futureOrFutureOrNum,
        futureT,
        futureOrT,
      ],
      futureListNum: [futureOrListNum],
      futureT: [futureOrT],
      futureFutureNum: [futureOrFutureOrNum],
      futureOrNum: [futureOrFutureOrNum],
      futureOrInt: [futureOrNum, futureOrFutureOrNum],
      futureOrNull: [
        futureNull,
        futureNum,
        futureOrNum,
        futureInt,
        futureOrInt,
        futureListNum,
        futureOrListNum,
        futureFutureNum,
        futureOrFutureOrNum,
        futureT,
        futureOrT,
      ],
      returnFutureNull: [returnVoid],
    };

    for (DartType t in all) {
      List<DartType> expectedSubtypes = expectedSubtypesMap[t] ?? [];
      for (DartType s in all) {
        bool expectedSubtype = t == s ||
            expectedSubtypes.contains(s) ||
            s == Object_ ||
            t == Null_;
        Expect.equals(
            expectedSubtype,
            env.isSubtype(t, s),
            "$t${expectedSubtype ? '' : ' not'} "
            "expected to be a subtype of $s.");
      }
    }
  });
}
