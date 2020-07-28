// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

const String CODE = """
class A {}
class B extends A {}
class C implements A {}
class D implements A {}
main() {
  print([new A(), new B(), new C(), new D()]);
}
""";

main() {
  retainDataForTesting = true;

  runTests() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': CODE});
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    AbstractValueDomain commonMasks = closedWorld.abstractValueDomain;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

    dynamic classA =
        elementEnvironment.lookupClass(elementEnvironment.mainLibrary, 'A');
    dynamic classB =
        elementEnvironment.lookupClass(elementEnvironment.mainLibrary, 'B');
    dynamic classC =
        elementEnvironment.lookupClass(elementEnvironment.mainLibrary, 'C');
    dynamic classD =
        elementEnvironment.lookupClass(elementEnvironment.mainLibrary, 'D');

    var exactA = new TypeMask.nonNullExact(classA, closedWorld);
    var exactB = new TypeMask.nonNullExact(classB, closedWorld);
    var exactC = new TypeMask.nonNullExact(classC, closedWorld);
    var exactD = new TypeMask.nonNullExact(classD, closedWorld);

    var subclassA = new TypeMask.nonNullSubclass(classA, closedWorld);
    var subtypeA = new TypeMask.nonNullSubtype(classA, closedWorld);

    var subclassObject = new TypeMask.nonNullSubclass(
        closedWorld.commonElements.objectClass, closedWorld);

    var unionABC = UnionTypeMask.unionOf([exactA, exactB, exactC], commonMasks);
    var unionABnC =
        UnionTypeMask.unionOf([exactA, exactB.nullable(), exactC], commonMasks);
    var unionAB = UnionTypeMask.unionOf([exactA, exactB], commonMasks);
    var unionSubtypeAC = UnionTypeMask.unionOf([subtypeA, exactC], commonMasks);
    var unionSubclassAC =
        UnionTypeMask.unionOf([subclassA, exactC], commonMasks);
    var unionBCD = UnionTypeMask.unionOf([exactB, exactC, exactD], commonMasks);
    var unionBCDn =
        UnionTypeMask.unionOf([exactB, exactC, exactD.nullable()], commonMasks);

    Expect.isFalse(unionABC.isNullable);
    Expect.isTrue(unionABnC.isNullable);
    Expect.isFalse(unionBCD.isNullable);
    Expect.isTrue(unionBCDn.isNullable);

    rule(a, b, c) => Expect.equals(c, a.isInMask(b, closedWorld));

    rule(exactA, exactA, true);
    rule(exactA, exactB, false);
    rule(exactA, exactC, false);
    rule(exactA, subclassA, true);
    rule(exactA, subtypeA, true);

    rule(exactB, exactA, false);
    rule(exactB, exactB, true);
    rule(exactB, exactC, false);
    rule(exactB, subclassA, true);
    rule(exactB, subtypeA, true);

    rule(exactC, exactA, false);
    rule(exactC, exactB, false);
    rule(exactC, exactC, true);
    rule(exactC, subclassA, false);
    rule(exactC, subtypeA, true);

    rule(subclassA, exactA, false);
    rule(subclassA, exactB, false);
    rule(subclassA, exactC, false);
    rule(subclassA, subclassA, true);
    rule(subclassA, subtypeA, true);

    rule(subtypeA, exactA, false);
    rule(subtypeA, exactB, false);
    rule(subtypeA, exactC, false);
    rule(subtypeA, subclassA, false);
    rule(subtypeA, subtypeA, true);

    rule(unionABC, unionSubtypeAC, true);
    rule(unionSubtypeAC, unionABC, true);
    rule(unionAB, unionSubtypeAC, true);
    rule(unionSubtypeAC, unionAB, false);
    rule(unionABC, unionSubclassAC, true);
    rule(unionSubclassAC, unionABC, true);
    rule(unionAB, unionSubclassAC, true);
    rule(unionSubclassAC, unionAB, false);
    rule(unionAB, subclassA, true);
    rule(subclassA, unionAB, true);
    rule(unionABC, subtypeA, true);
    rule(subtypeA, unionABC, true);
    rule(unionABC, subclassA, false);
    rule(subclassA, unionABC, true);
    rule(unionAB, subclassA, true);
    rule(subclassA, unionAB, true);

    rule(exactA, subclassObject, true);
    rule(exactB, subclassObject, true);
    rule(subclassA, subclassObject, true);
    rule(subtypeA, subclassObject, true);
    rule(unionABC, subclassObject, true);
    rule(unionAB, subclassObject, true);
    rule(unionSubtypeAC, subclassObject, true);
    rule(unionSubclassAC, subclassObject, true);

    rule(unionABnC, unionABC, false);
    rule(unionABC, unionABnC, true);
    rule(exactA.nullable(), unionABnC, true);
    rule(exactA.nullable(), unionABC, false);
    rule(exactB, unionABnC, true);
    rule(unionBCDn, unionBCD, false);
    rule(unionBCD, unionBCDn, true);
    rule(exactB.nullable(), unionBCDn, true);
    rule(exactB.nullable(), unionBCD, false);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
