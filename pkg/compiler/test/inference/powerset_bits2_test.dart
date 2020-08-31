// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/inferrer/powersets/powersets.dart';
import 'package:compiler/src/inferrer/powersets/powerset_bits.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

const String CODE = """
class A {}
main() {
  A a = A();
}
""";

main() {
  retainDataForTesting = true;

  runTests() async {
    CompilationResult result = await runCompiler(memorySourceFiles: {
      'main.dart': CODE
    }, options: [
      '--experimental-powersets',
    ]);
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    var results = compiler.globalInference.resultsForTesting;
    JClosedWorld closedWorld = results.closedWorld;
    CommonElements commonElements = closedWorld.commonElements;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    PowersetDomain powersetDomain = closedWorld.abstractValueDomain;
    PowersetBitsDomain powersetBitsDomain = powersetDomain.powersetBitsDomain;

    var exactTrue = powersetBitsDomain.trueValue;
    var exactFalse = powersetBitsDomain.falseValue;
    dynamic classA =
        elementEnvironment.lookupClass(elementEnvironment.mainLibrary, 'A');
    var exactA = powersetBitsDomain.createNonNullExact(classA);
    var subtypeObject =
        powersetBitsDomain.createNonNullSubtype(commonElements.objectClass);
    var exactNull =
        powersetBitsDomain.createNonNullExact(commonElements.jsNullClass);
    var exactBool =
        powersetBitsDomain.createNonNullExact(commonElements.jsBoolClass);
    var nullableBool =
        powersetBitsDomain.createNullableExact(commonElements.jsBoolClass);

    var unionTrueFalse = powersetBitsDomain.union(exactTrue, exactFalse);
    var unionBoolNull = powersetBitsDomain.union(exactBool, exactNull);
    var unionBoolNullOther = powersetBitsDomain.union(unionBoolNull, exactA);

    Expect.equals(unionTrueFalse, exactBool);
    Expect.equals(unionBoolNull, nullableBool);
    Expect.equals(unionBoolNullOther, powersetBitsDomain.powersetTop);

    checkDisjoint(int v1, int v2) {
      Expect.isTrue(powersetBitsDomain.areDisjoint(v1, v2).isDefinitelyTrue);
    }

    checkDisjoint(exactTrue, exactFalse);
    checkDisjoint(exactA, exactNull);
    checkDisjoint(subtypeObject, exactNull);
    checkDisjoint(exactBool, exactNull);
    checkDisjoint(exactA, exactBool);
    checkDisjoint(exactA, nullableBool);

    checkisIn(int v1, int v2) {
      Expect.isTrue(powersetBitsDomain.isIn(v1, v2).isDefinitelyTrue);
    }

    checkisIn(exactTrue, exactBool);
    checkisIn(exactFalse, exactBool);
    checkisIn(exactNull, nullableBool);
    checkisIn(exactBool, nullableBool);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
