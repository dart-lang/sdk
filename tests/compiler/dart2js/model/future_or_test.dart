// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:expect/expect.dart';
import '../type_test_helper.dart';

main() {
  asyncTest(() async {
    var env = await TypeEnvironment.create(
        '''
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
''',
        compileMode: CompileMode.kernel,
        options: [Flags.strongMode]);
    DartType getReturnType(String name, String expectedType) {
      FunctionType type = env.getMemberType(name);
      DartType returnType = type.returnType;
      Expect.equals(expectedType, '${returnType}');
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
    FutureOrType futureOrNull = getReturnType('futureOrNull', 'FutureOr<Null>');
    DartType Null_ = futureOrNull.typeArgument;

    List<DartType> all = [
      Object_,
      num_,
      int_,
      Null_,
      ListNum,
      futureNum,
      futureOrNum,
      futureInt,
      futureNull,
      futureListNum,
      futureOrInt,
      futureOrNull,
      futureOrListNum,
      futureFutureNum,
      futureOrFutureOrNum,
    ];

    Map<DartType, List<DartType>> expectedSubtypesMap = {
      num_: [futureOrNum, futureOrFutureOrNum],
      int_: [num_, futureOrInt, futureOrNum, futureOrFutureOrNum],
      ListNum: [futureOrListNum],
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
        futureOrNull,
      ],
      futureListNum: [futureOrListNum],
      futureFutureNum: [futureOrFutureOrNum],
      futureOrNum: [futureOrFutureOrNum],
      futureOrInt: [futureOrNum, futureOrFutureOrNum],
      futureOrNull: [
        futureOrNum,
        futureOrInt,
        futureOrListNum,
        futureOrFutureOrNum
      ],
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
