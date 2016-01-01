// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_mask2_test;

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/elements/elements.dart'
       show Element, ClassElement;
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/world.dart' show
    ClassWorld;

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

void main() {
  asyncTest(() async {
    await testUnionTypeMaskFlatten();
    await testStringSubtypes();
  });
}

checkMasks(ClassWorld classWorld,
           List<ClassElement> allClasses,
           List<FlatTypeMask> masks,
           {FlatTypeMask result,
            List<FlatTypeMask> disjointMasks,
            FlatTypeMask flattened,
            List<ClassElement> containedClasses}) {
  List<FlatTypeMask> disjoint = <FlatTypeMask>[];
  UnionTypeMask.unionOfHelper(masks, disjoint, classWorld);
  Expect.listEquals(disjointMasks, disjoint,
      'Unexpected disjoint masks: $disjoint, expected $disjointMasks.');
  if (flattened == null) {
    // We only do the invalid call to flatten in checked mode, as flatten's
    // behaviour in unchecked mode is not defined and thus cannot be
    // reliably tested.
    if (isCheckedMode()) {
      Expect.throws(() => UnionTypeMask.flatten(disjoint, classWorld),
        (e) => e is AssertionError,
        'Expect assertion failure on flattening of $disjoint.');
    }
  } else {
    TypeMask flattenResult =
        UnionTypeMask.flatten(disjoint, classWorld);
    Expect.equals(flattened, flattenResult,
        'Unexpected flattening of $disjoint: '
        '$flattenResult, expected $flattened.');
  }
  var union = UnionTypeMask.unionOf(masks, classWorld);
  if (result == null) {
    Expect.isTrue(union is UnionTypeMask,
        'Expected union of $masks to be a union-type: $union.');
    Expect.listEquals(disjointMasks, union.disjointMasks,
        'Unexpected union masks: '
        '${union.disjointMasks}, expected $disjointMasks.');
  } else {
    Expect.equals(result, union,
        'Unexpected union of $masks: $union, expected $result.');
  }
  if (containedClasses != null) {
    for (ClassElement cls in allClasses) {
      if (containedClasses.contains(cls)) {
        Expect.isTrue(union.contains(cls, classWorld),
            'Expected $union to contain $cls.');
      } else {
        Expect.isFalse(union.contains(cls, classWorld),
            '$union not expected to contain $cls.');
      }
    }

  }
  return union;
}

Future testUnionTypeMaskFlatten() async  {
  TypeEnvironment env = await TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends A {}
      class D implements A {}
      class E extends B implements A {}
      """,
      mainSource: r"""
      main() {
        new A();
        new B();
        new C();
        new D();
        new E();
      }
      """,
      useMockCompiler: false);

  ClassWorld classWorld = env.compiler.world;

  ClassElement Object_ = env.getElement("Object");
  ClassElement A = env.getElement("A");
  ClassElement B = env.getElement("B");
  ClassElement C = env.getElement("C");
  ClassElement D = env.getElement("D");
  ClassElement E = env.getElement("E");

  List<ClassElement> allClasses = <ClassElement>[Object_, A, B, C, D, E];

  check(List<FlatTypeMask> masks,
        {FlatTypeMask result,
         List<FlatTypeMask> disjointMasks,
         FlatTypeMask flattened,
         List<ClassElement> containedClasses}) {
    return checkMasks(
        classWorld,
        allClasses,
        masks,
        result: result,
        disjointMasks: disjointMasks,
        flattened: flattened,
        containedClasses: containedClasses);
  }

  TypeMask empty = const TypeMask.nonNullEmpty();
  TypeMask subclassObject = new TypeMask.nonNullSubclass(Object_, classWorld);
  TypeMask exactA = new TypeMask.nonNullExact(A, classWorld);
  TypeMask subclassA = new TypeMask.nonNullSubclass(A, classWorld);
  TypeMask subtypeA = new TypeMask.nonNullSubtype(A, classWorld);
  TypeMask exactB = new TypeMask.nonNullExact(B, classWorld);
  TypeMask subclassB = new TypeMask.nonNullSubclass(B, classWorld);
  TypeMask exactC = new TypeMask.nonNullExact(C, classWorld);
  TypeMask exactD = new TypeMask.nonNullExact(D, classWorld);
  TypeMask exactE = new TypeMask.nonNullExact(E, classWorld);

  check([],
        result: empty,
        disjointMasks: [],
        containedClasses: []);

  check([exactA],
        result: exactA,
        disjointMasks: [exactA],
        containedClasses: [A]);

  check([exactA, exactA],
        result: exactA,
        disjointMasks: [exactA],
        containedClasses: [A]);

  check([exactA, exactB],
        disjointMasks: [exactA, exactB],
        flattened: subclassObject,
        containedClasses: [A, B]);

  check([subclassObject],
        result: subclassObject,
        disjointMasks: [subclassObject],
        containedClasses: [Object_, A, B, C, D, E]);

  check([subclassObject, exactA],
        disjointMasks: [subclassObject],
        result: subclassObject,
        containedClasses: [Object_, A, B, C, D, E]);

  check([exactA, exactC],
        disjointMasks: [subclassA],
        result: subclassA,
        containedClasses: [A, C]);

  check([exactA, exactB, exactC],
        disjointMasks: [subclassA, exactB],
        flattened: subclassObject,
        containedClasses: [A, B, C]);

  check([exactA, exactD],
        disjointMasks: [subtypeA],
        result: subtypeA,
        containedClasses: [A, C, D, E]);

  check([exactA, exactB, exactD],
        disjointMasks: [subtypeA, exactB],
        flattened: subclassObject,
        containedClasses: [A, B, C, D, E]);

  check([exactA, exactE],
        disjointMasks: [subtypeA],
        result: subtypeA,
        containedClasses: [A, C, D, E]);

  check([exactA, exactB, exactE],
        disjointMasks: [subtypeA, exactB],
        flattened: subclassObject,
        containedClasses: [A, B, C, D, E]);

  check([exactB, exactE, exactA],
        disjointMasks: [subclassB, exactA],
        flattened: subclassObject,
        containedClasses: [A, B, E]);

  check([exactE, exactA, exactB],
        disjointMasks: [subtypeA, exactB],
        flattened: subclassObject,
        containedClasses: [A, B, C, D, E]);

  check([exactE, exactB, exactA],
        disjointMasks: [subclassB, exactA],
        flattened: subclassObject,
        containedClasses: [A, B, E]);
}

Future testStringSubtypes() async {
  TypeEnvironment env = await TypeEnvironment.create('',
      mainSource: r"""
      main() {
        '' is String;
      }
      """,
      useMockCompiler: false);
    var classWorld = env.compiler.world;
    var backend = env.compiler.backend;

    ClassElement Object_ = env.getElement("Object");
    ClassElement String_ = env.getElement("String");
    ClassElement JSString = backend.helpers.jsStringClass;

    List<ClassElement> allClasses = <ClassElement>[Object_, String_];

    Expect.isFalse(classWorld.isDirectlyInstantiated(Object_));
    Expect.isTrue(classWorld.isIndirectlyInstantiated(Object_));
    Expect.isTrue(classWorld.isInstantiated(Object_));

    Expect.isFalse(classWorld.isDirectlyInstantiated(String_));
    Expect.isFalse(classWorld.isIndirectlyInstantiated(String_));
    Expect.isFalse(classWorld.isInstantiated(String_));

    Expect.isTrue(classWorld.isDirectlyInstantiated(JSString));
    Expect.isFalse(classWorld.isIndirectlyInstantiated(JSString));
    Expect.isTrue(classWorld.isInstantiated(JSString));

    TypeMask subtypeString = new TypeMask.nonNullSubtype(String_, classWorld);
    TypeMask exactJSString = new TypeMask.nonNullExact(JSString, classWorld);
    TypeMask subtypeJSString =
        new TypeMask.nonNullSubtype(JSString, classWorld);
    TypeMask subclassJSString =
        new TypeMask.nonNullSubclass(JSString, classWorld);

    Expect.equals(exactJSString, subtypeString);
    Expect.equals(exactJSString, subtypeJSString);
    Expect.equals(exactJSString, subclassJSString);
}
