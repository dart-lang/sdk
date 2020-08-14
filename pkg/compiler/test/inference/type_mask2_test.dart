// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library type_mask2_test;

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/world.dart' show JClosedWorld;
import '../helpers/type_test_helper.dart';

void main() {
  runTests() async {
    await testUnionTypeMaskFlatten();
    await testStringSubtypes();
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

checkMasks(JClosedWorld closedWorld, List<ClassEntity> allClasses,
    List<FlatTypeMask> masks,
    {FlatTypeMask result,
    List<FlatTypeMask> disjointMasks,
    FlatTypeMask flattened,
    List<ClassEntity> containedClasses}) {
  AbstractValueDomain commonMasks = closedWorld.abstractValueDomain;
  bool isNullable = masks.any((FlatTypeMask mask) => mask.isNullable);
  List<FlatTypeMask> disjoint = <FlatTypeMask>[];
  UnionTypeMask.unionOfHelper(masks, disjoint, commonMasks);
  Expect.listEquals(disjointMasks, disjoint,
      'Unexpected disjoint masks: $disjoint, expected $disjointMasks.');
  if (flattened == null) {
    Expect.throws(
        () => UnionTypeMask.flatten(disjoint, isNullable, commonMasks),
        (e) => e is ArgumentError,
        'Expect argument error on flattening of $disjoint.');
  } else {
    TypeMask flattenResult =
        UnionTypeMask.flatten(disjoint, isNullable, commonMasks);
    Expect.equals(
        flattened,
        flattenResult,
        'Unexpected flattening of $disjoint: '
        '$flattenResult, expected $flattened.');
  }
  dynamic union = UnionTypeMask.unionOf(masks, commonMasks);
  if (result == null) {
    Expect.isTrue(union is UnionTypeMask,
        'Expected union of $masks to be a union-type: $union.');
    Expect.listEquals(
        disjointMasks,
        union.disjointMasks,
        'Unexpected union masks: '
        '${union.disjointMasks}, expected $disjointMasks.');
  } else {
    Expect.equals(
        result, union, 'Unexpected union of $masks: $union, expected $result.');
  }
  if (containedClasses != null) {
    for (ClassEntity cls in allClasses) {
      if (containedClasses.contains(cls)) {
        Expect.isTrue(union.contains(cls, closedWorld),
            'Expected $union to contain $cls.');
      } else {
        Expect.isFalse(union.contains(cls, closedWorld),
            '$union not expected to contain $cls.');
      }
    }
  }
  return union;
}

Future testUnionTypeMaskFlatten() async {
  TypeEnvironment env = await TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends A {}
      class D implements A {}
      class E extends B implements A {}

      main() {
        new A();
        new B();
        new C();
        new D();
        new E();
      }
      """, testBackendWorld: true);

  JClosedWorld closedWorld = env.jClosedWorld;

  ClassEntity Object_ = env.getElement("Object");
  ClassEntity A = env.getElement("A");
  ClassEntity B = env.getElement("B");
  ClassEntity C = env.getElement("C");
  ClassEntity D = env.getElement("D");
  ClassEntity E = env.getElement("E");

  List<ClassEntity> allClasses = <ClassEntity>[Object_, A, B, C, D, E];

  check(List<FlatTypeMask> masks,
      {FlatTypeMask result,
      List<FlatTypeMask> disjointMasks,
      FlatTypeMask flattened,
      List<ClassEntity> containedClasses}) {
    return checkMasks(closedWorld, allClasses, masks,
        result: result,
        disjointMasks: disjointMasks,
        flattened: flattened,
        containedClasses: containedClasses);
  }

  TypeMask empty = const TypeMask.nonNullEmpty();
  TypeMask subclassObject = new TypeMask.nonNullSubclass(Object_, closedWorld);
  TypeMask exactA = new TypeMask.nonNullExact(A, closedWorld);
  TypeMask subclassA = new TypeMask.nonNullSubclass(A, closedWorld);
  TypeMask subtypeA = new TypeMask.nonNullSubtype(A, closedWorld);
  TypeMask exactB = new TypeMask.nonNullExact(B, closedWorld);
  TypeMask subclassB = new TypeMask.nonNullSubclass(B, closedWorld);
  TypeMask exactC = new TypeMask.nonNullExact(C, closedWorld);
  TypeMask exactD = new TypeMask.nonNullExact(D, closedWorld);
  TypeMask exactE = new TypeMask.nonNullExact(E, closedWorld);

  check([],
      result: empty,
      disjointMasks: [],
      flattened: null, // 'flatten' throws.
      containedClasses: []);

  check([exactA],
      result: exactA,
      disjointMasks: [exactA],
      flattened: subtypeA, // TODO(37602): Imprecise.
      containedClasses: [A]);

  check([exactA, exactA],
      result: exactA,
      disjointMasks: [exactA],
      flattened: subtypeA, // TODO(37602): Imprecise.
      containedClasses: [A]);

  check([exactA, exactB],
      disjointMasks: [exactA, exactB],
      flattened: subclassObject,
      containedClasses: [A, B]);

  check([subclassObject],
      result: subclassObject,
      disjointMasks: [subclassObject],
      flattened: subclassObject,
      containedClasses: [Object_, A, B, C, D, E]);

  check([subclassObject, exactA],
      disjointMasks: [subclassObject],
      result: subclassObject,
      flattened: subclassObject,
      containedClasses: [Object_, A, B, C, D, E]);

  check([exactA, exactC],
      disjointMasks: [subclassA],
      result: subclassA,
      flattened: subtypeA, // TODO(37602): Imprecise.
      containedClasses: [A, C]);

  check([exactA, exactB, exactC],
      disjointMasks: [subclassA, exactB],
      flattened: subclassObject,
      containedClasses: [A, B, C]);

  check([exactA, exactD],
      disjointMasks: [subtypeA],
      result: subtypeA,
      flattened: subtypeA,
      containedClasses: [A, C, D, E]);

  check([exactA, exactB, exactD],
      disjointMasks: [subtypeA, exactB],
      flattened: subclassObject,
      containedClasses: [A, B, C, D, E]);

  check([exactA, exactE],
      disjointMasks: [subtypeA],
      result: subtypeA,
      flattened: subtypeA,
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
  TypeEnvironment env = await TypeEnvironment.create(r"""
      main() {
        '' is String;
      }
      """, testBackendWorld: true);
  JClosedWorld closedWorld = env.jClosedWorld;

  ClassEntity Object_ = env.getElement("Object");
  ClassEntity String_ = env.getElement("String");
  ClassEntity JSString = closedWorld.commonElements.jsStringClass;

  // TODO(37602): Track down why `Object` is directly instantiated:
  // Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(Object_));

  Expect.isTrue(closedWorld.classHierarchy.isIndirectlyInstantiated(Object_));
  Expect.isTrue(closedWorld.classHierarchy.isInstantiated(Object_));

  Expect.isFalse(closedWorld.classHierarchy.isDirectlyInstantiated(String_));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(String_));
  Expect.isFalse(closedWorld.classHierarchy.isInstantiated(String_));

  Expect.isTrue(closedWorld.classHierarchy.isDirectlyInstantiated(JSString));
  Expect.isFalse(closedWorld.classHierarchy.isIndirectlyInstantiated(JSString));
  Expect.isTrue(closedWorld.classHierarchy.isInstantiated(JSString));

  TypeMask subtypeString = new TypeMask.nonNullSubtype(String_, closedWorld);
  TypeMask exactJSString = new TypeMask.nonNullExact(JSString, closedWorld);
  TypeMask subtypeJSString = new TypeMask.nonNullSubtype(JSString, closedWorld);
  TypeMask subclassJSString =
      new TypeMask.nonNullSubclass(JSString, closedWorld);

  Expect.equals(exactJSString, subtypeString);
  Expect.equals(exactJSString, subtypeJSString);
  Expect.equals(exactJSString, subclassJSString);
}
