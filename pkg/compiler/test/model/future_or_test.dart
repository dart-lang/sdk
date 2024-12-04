// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

main() {
  asyncTest(() async {
    var env = await TypeEnvironment.create("""
import 'dart:async';

Never never() => throw '';

Future<num> futureNum() async => never();
FutureOr<num> futureOrNum() async => never();

Future<int> futureInt() async => never();
FutureOr<int> futureOrInt() async => never();

Future<List<num>> futureListNum() async => never();
FutureOr<List<num>> futureOrListNum() async => never();

Future<Future<num>> futureFutureNum() async => never();
FutureOr<FutureOr<num>> futureOrFutureOrNum() async => never();

Future<Null> futureNull() async => never();
FutureOr<Null> futureOrNull() async => never();

void returnVoid() {}

class C<T> {
  Future<T> futureT() async => never();
  FutureOr<T> futureOrT() async => never();
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
  C().futureT();
  C().futureOrT();
}
""");
    FunctionType getFunctionType(String name, String expectedType,
        [ClassEntity? cls]) {
      final type = env.getMemberType(name, cls) as FunctionType?;
      Expect.isNotNull(type,
          "Member $name not found${cls != null ? ' in class $cls' : ''}.");
      Expect.equals(
          expectedType,
          env.printType(type!),
          "Unexpected type for $name"
          "${cls != null ? ' in class $cls' : ''}.");
      return type;
    }

    DartType getReturnType(String name, String expectedType,
        [ClassEntity? cls]) {
      final type = env.getMemberType(name, cls) as FunctionType?;
      Expect.isNotNull(type,
          "Member $name not found${cls != null ? ' in class $cls' : ''}.");
      DartType returnType = type!.returnType.withoutNullability;
      Expect.equals(
          expectedType,
          env.printType(returnType),
          "Unexpected return type for $name"
          "${cls != null ? ' in class $cls' : ''}.");
      return returnType;
    }

    DartType top = env.types.nullableType(env['Object']);
    DartType bottom = env.types.neverType();

    DartType futureNum = getReturnType('futureNum', 'Future<num>');
    final futureOrNum =
        getReturnType('futureOrNum', 'FutureOr<num>') as FutureOrType;
    DartType num_ = futureOrNum.typeArgument;

    DartType futureInt = getReturnType('futureInt', 'Future<int>');
    final futureOrInt =
        getReturnType('futureOrInt', 'FutureOr<int>') as FutureOrType;
    DartType int_ = futureOrInt.typeArgument;

    DartType futureListNum =
        getReturnType('futureListNum', 'Future<List<num>>');
    final futureOrListNum =
        getReturnType('futureOrListNum', 'FutureOr<List<num>>') as FutureOrType;
    DartType ListNum = futureOrListNum.typeArgument;

    DartType futureFutureNum =
        getReturnType('futureFutureNum', 'Future<Future<num>>');
    final futureOrFutureOrNum =
        getReturnType('futureOrFutureOrNum', 'FutureOr<FutureOr<num>>')
            as FutureOrType;

    DartType futureNull = getReturnType('futureNull', 'Future<Null>');
    final futureOrNull =
        getReturnType('futureOrNull', 'Future<Null>') as InterfaceType;
    DartType Null_ = futureOrNull.typeArguments.single;

    ClassEntity C = env.getClass('C');
    DartType futureT = getReturnType('futureT', 'Future<C.T>', C);
    final futureOrT =
        getReturnType('futureOrT', 'FutureOr<C.T>', C) as FutureOrType;
    DartType T = futureOrT.typeArgument.withoutNullability;
    Expect.isTrue(futureOrT.containsTypeVariables);
    futureOrT.forEachTypeVariable((t) => Expect.equals(T, t));

    DartType returnVoid = getFunctionType('returnVoid', 'void Function()');
    DartType returnFutureNull =
        getFunctionType('futureOrNull', 'Future<Null>? Function()');

    List<DartType> all = [
      top,
      bottom,
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
      ],
      futureListNum: [futureOrListNum],
      futureT: [futureOrT],
      futureFutureNum: [futureOrFutureOrNum],
      futureOrNum: [futureOrFutureOrNum],
      futureOrInt: [futureOrNum, futureOrFutureOrNum],
      futureOrNull: [],
      returnFutureNull: [returnVoid],
    };

    for (DartType t in all) {
      List<DartType> expectedSubtypes = expectedSubtypesMap[t] ?? [];
      for (DartType s in all) {
        bool expectedSubtype =
            t == s || expectedSubtypes.contains(s) || s == top || t == bottom;
        Expect.equals(
            expectedSubtype,
            env.isSubtype(t, s),
            "$t${expectedSubtype ? '' : ' not'} "
            "expected to be a subtype of $s.");
      }
    }
  });
}
