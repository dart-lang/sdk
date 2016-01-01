// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/types/types.dart';

import 'compiler_helper.dart';

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
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(CODE, uri);
  var classWorld = compiler.world;

  asyncTest(() => compiler.run(uri).then((_) {
    var classA = findElement(compiler, 'A');
    var classB = findElement(compiler, 'B');
    var classC = findElement(compiler, 'C');
    var classD = findElement(compiler, 'D');

    var exactA = new TypeMask.nonNullExact(classA, classWorld);
    var exactB = new TypeMask.nonNullExact(classB, classWorld);
    var exactC = new TypeMask.nonNullExact(classC, classWorld);
    var exactD = new TypeMask.nonNullExact(classD, classWorld);

    var subclassA = new TypeMask.nonNullSubclass(classA, classWorld);
    var subtypeA = new TypeMask.nonNullSubtype(classA, classWorld);

    var subclassObject = new TypeMask.nonNullSubclass(
        compiler.coreClasses.objectClass, classWorld);

    var unionABC = UnionTypeMask.unionOf([exactA, exactB, exactC], classWorld);
    var unionABnC = UnionTypeMask.unionOf([exactA, exactB.nullable(), exactC],
        classWorld);
    var unionAB = UnionTypeMask.unionOf([exactA, exactB], classWorld);
    var unionSubtypeAC = UnionTypeMask.unionOf([subtypeA, exactC], classWorld);
    var unionSubclassAC = UnionTypeMask.unionOf([subclassA, exactC],
        classWorld);
    var unionBCD = UnionTypeMask.unionOf([exactB, exactC, exactD], classWorld);
    var unionBCDn = UnionTypeMask.unionOf([exactB, exactC, exactD.nullable()],
        classWorld);

    Expect.isFalse(unionABC.isNullable);
    Expect.isTrue(unionABnC.isNullable);
    Expect.isFalse(unionBCD.isNullable);
    Expect.isTrue(unionBCDn.isNullable);

    rule(a, b, c) => Expect.equals(c, a.isInMask(b, classWorld));

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
  }));
}
