// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_mask2_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/implementation/dart_types.dart';
import 'package:compiler/implementation/elements/elements.dart'
       show Element, ClassElement;
import 'package:compiler/implementation/types/types.dart';

void main() {
  testUnionTypeMaskFlatten();
}

void testUnionTypeMaskFlatten() {
  asyncTest(() => TypeEnvironment.create(r"""
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
      useMockCompiler: false).then((env) {
    var classWorld = env.compiler.world;

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
      List<FlatTypeMask> disjoint = <FlatTypeMask>[];
      UnionTypeMask.unionOfHelper(masks, disjoint, env.compiler);
      Expect.listEquals(disjointMasks, disjoint,
          'Unexpected disjoint masks: $disjoint, expected $disjointMasks.');
      if (flattened == null) {
        Expect.throws(() => UnionTypeMask.flatten(disjoint, classWorld),
          (e) => e is AssertionError,
          'Expect assertion failure on flattening of $disjoint.');
      } else {
        TypeMask flattenResult =
            UnionTypeMask.flatten(disjoint, classWorld);
        Expect.equals(flattened, flattenResult,
            'Unexpected flattening of $disjoint: '
            '$flattenResult, expected $flattened.');
      }
      var union = UnionTypeMask.unionOf(masks, env.compiler);
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
            Expect.isTrue(union.contains(cls, env.compiler),
                'Expected $union to contain $cls.');
          } else {
            Expect.isFalse(union.contains(cls, env.compiler),
                '$union not expected to contain $cls.');
          }
        }

      }
      return union;
    }

    TypeMask empty = const TypeMask.nonNullEmpty();
    TypeMask subclassObject = new TypeMask.nonNullSubclass(Object_, classWorld);
    TypeMask exactA = new TypeMask.nonNullExact(A);
    TypeMask subclassA = new TypeMask.nonNullSubclass(A, classWorld);
    TypeMask subtypeA = new TypeMask.nonNullSubtype(A, classWorld);
    TypeMask exactB = new TypeMask.nonNullExact(B);
    TypeMask subclassB = new TypeMask.nonNullSubclass(B, classWorld);
    TypeMask exactC = new TypeMask.nonNullExact(C);
    TypeMask exactD = new TypeMask.nonNullExact(D);
    TypeMask exactE = new TypeMask.nonNullExact(E);

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
  }));
}
