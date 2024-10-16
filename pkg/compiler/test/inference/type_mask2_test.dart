// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_mask2_test;

import 'dart:async';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
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
    {FlatTypeMask? result,
    required List<FlatTypeMask> disjointMasks,
    FlatTypeMask? flattened,
    List<ClassEntity>? containedClasses}) {
  final commonMasks = closedWorld.abstractValueDomain as CommonMasks;
  bool isNullable = masks.any((FlatTypeMask mask) => mask.isNullable);
  bool hasLateSentinel = masks.any((FlatTypeMask mask) => mask.hasLateSentinel);
  List<FlatTypeMask> disjoint = <FlatTypeMask>[];
  UnionTypeMask.unionOfHelper(masks, disjoint, commonMasks);
  Expect.listEquals(disjointMasks, disjoint,
      'Unexpected disjoint masks: $disjoint, expected $disjointMasks.');
  if (flattened == null) {
    Expect.throws(
        () => UnionTypeMask.flatten(disjoint, commonMasks,
            includeNull: isNullable, includeLateSentinel: hasLateSentinel),
        (e) => e is ArgumentError,
        'Expect argument error on flattening of $disjoint.');
  } else {
    TypeMask flattenResult = UnionTypeMask.flatten(disjoint, commonMasks,
        includeNull: isNullable, includeLateSentinel: hasLateSentinel);
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
        A();
        B();
        C();
        D();
        E();
      }
      """, testBackendWorld: true);

  JClosedWorld closedWorld = env.jClosedWorld;

  final Object_ = env.getElement("Object") as ClassEntity;
  final A = env.getElement("A") as ClassEntity;
  final B = env.getElement("B") as ClassEntity;
  final C = env.getElement("C") as ClassEntity;
  final D = env.getElement("D") as ClassEntity;
  final E = env.getElement("E") as ClassEntity;

  List<ClassEntity> allClasses = <ClassEntity>[Object_, A, B, C, D, E];

  check(List<FlatTypeMask> masks,
      {FlatTypeMask? result,
      required List<FlatTypeMask> disjointMasks,
      FlatTypeMask? flattened,
      List<ClassEntity>? containedClasses}) {
    return checkMasks(closedWorld, allClasses, masks,
        result: result,
        disjointMasks: disjointMasks,
        flattened: flattened,
        containedClasses: containedClasses);
  }

  final empty = TypeMask.nonNullEmpty() as FlatTypeMask;
  final sentinel = TypeMask.nonNullEmpty(hasLateSentinel: true) as FlatTypeMask;
  final subclassObject =
      TypeMask.nonNullSubclass(Object_, closedWorld) as FlatTypeMask;
  final subclassObjectOrSentinel =
      TypeMask.nonNullSubclass(Object_, closedWorld, hasLateSentinel: true)
          as FlatTypeMask;
  final exactA = TypeMask.nonNullExact(A, closedWorld) as FlatTypeMask;
  final exactAOrSentinel =
      TypeMask.nonNullExact(A, closedWorld, hasLateSentinel: true)
          as FlatTypeMask;
  final subclassA = TypeMask.nonNullSubclass(A, closedWorld) as FlatTypeMask;
  final subtypeA = TypeMask.nonNullSubtype(A, closedWorld) as FlatTypeMask;
  final subtypeAOrSentinel =
      TypeMask.nonNullSubtype(A, closedWorld, hasLateSentinel: true)
          as FlatTypeMask;
  final exactB = TypeMask.nonNullExact(B, closedWorld) as FlatTypeMask;
  final exactBOrSentinel =
      TypeMask.nonNullExact(B, closedWorld, hasLateSentinel: true)
          as FlatTypeMask;
  final subclassB = TypeMask.nonNullSubclass(B, closedWorld) as FlatTypeMask;
  final exactC = TypeMask.nonNullExact(C, closedWorld) as FlatTypeMask;
  final exactD = TypeMask.nonNullExact(D, closedWorld) as FlatTypeMask;
  final exactE = TypeMask.nonNullExact(E, closedWorld) as FlatTypeMask;

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

  check([sentinel],
      result: sentinel,
      disjointMasks: const [],
      flattened: null,
      containedClasses: const []);

  check([sentinel, sentinel],
      result: sentinel,
      disjointMasks: const [],
      flattened: null,
      containedClasses: const []);

  check([empty, sentinel],
      result: sentinel,
      disjointMasks: const [],
      flattened: null,
      containedClasses: const []);

  check([sentinel, empty],
      result: sentinel,
      disjointMasks: const [],
      flattened: null,
      containedClasses: const []);

  check([exactAOrSentinel],
      result: exactAOrSentinel,
      disjointMasks: [exactA],
      flattened: subtypeAOrSentinel, // TODO(37602): Imprecise.
      containedClasses: [A]);

  check([exactA, exactAOrSentinel],
      result: exactAOrSentinel,
      disjointMasks: [exactA],
      flattened: subtypeAOrSentinel, // TODO(37602): Imprecise.
      containedClasses: [A]);

  check([exactAOrSentinel, exactB],
      disjointMasks: [exactA, exactB],
      flattened: subclassObjectOrSentinel,
      containedClasses: [A, B]);

  check([exactAOrSentinel, exactBOrSentinel],
      disjointMasks: [exactA, exactB],
      flattened: subclassObjectOrSentinel,
      containedClasses: [A, B]);
}

Future testStringSubtypes() async {
  TypeEnvironment env = await TypeEnvironment.create(r"""
      main() {
        '' is String;
      }
      """, testBackendWorld: true);
  JClosedWorld closedWorld = env.jClosedWorld;

  final Object_ = env.getElement("Object") as ClassEntity;
  final String_ = env.getElement("String") as ClassEntity;
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

  TypeMask subtypeString = TypeMask.nonNullSubtype(String_, closedWorld);
  TypeMask exactJSString = TypeMask.nonNullExact(JSString, closedWorld);
  TypeMask subtypeJSString = TypeMask.nonNullSubtype(JSString, closedWorld);
  TypeMask subclassJSString = TypeMask.nonNullSubclass(JSString, closedWorld);

  Expect.equals(exactJSString, subtypeString);
  Expect.equals(exactJSString, subtypeJSString);
  Expect.equals(exactJSString, subclassJSString);
}
