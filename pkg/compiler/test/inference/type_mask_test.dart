// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/util/memory_compiler.dart';

const String CODE = """
class A {}
class B extends A {}
class C implements A {}
class D implements A {}
main() {
  print([new A(), B(), C(), D()]);
}
""";

main() {
  retainDataForTesting = true;

  runTests() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': CODE});
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler!;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting!;
    final commonMasks = closedWorld.abstractValueDomain as CommonMasks;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    final mainLibrary = elementEnvironment.mainLibrary!;

    dynamic classA = elementEnvironment.lookupClass(mainLibrary, 'A');
    dynamic classB = elementEnvironment.lookupClass(mainLibrary, 'B');
    dynamic classC = elementEnvironment.lookupClass(mainLibrary, 'C');
    dynamic classD = elementEnvironment.lookupClass(mainLibrary, 'D');

    var exactA = TypeMask.nonNullExact(classA, closedWorld);
    var exactB = TypeMask.nonNullExact(classB, closedWorld);
    var exactC = TypeMask.nonNullExact(classC, closedWorld);
    var exactD = TypeMask.nonNullExact(classD, closedWorld);

    var subclassA = TypeMask.nonNullSubclass(classA, closedWorld);
    var subtypeA = TypeMask.nonNullSubtype(classA, closedWorld);

    var subclassObject = TypeMask.nonNullSubclass(
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
