// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for iterators on for [SubclassNode].

library subtypeset_test;

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/kernel_world.dart';
import 'package:compiler/src/universe/class_set.dart';
import '../helpers/type_test_helper.dart';

void main() {
  asyncTest(() async {
    await runTests();
  });
}

runTests() async {
  var env = await TypeEnvironment.create(r"""
      ///        A
      ///       / \
      ///      B   C
      ///     /   /|\
      ///    D   E F G 
      ///
      class A {
        call(H h, I i) {} // Make `H` and `I` part of the world.
      }
      class B extends A implements C {}
      class C extends A {}
      class D extends B implements A {}
      class E extends C implements B {}
      class F extends C {}
      class G extends C {}
      abstract class H implements C {}
      abstract class I implements H {}

      main() {
        A().call;
        C();
        D();
        E();
        F();
        G();
      }
      """);
  KClosedWorld world = env.kClosedWorld;

  final A = env.getElement("A") as ClassEntity;
  final B = env.getElement("B") as ClassEntity;
  final C = env.getElement("C") as ClassEntity;
  final D = env.getElement("D") as ClassEntity;
  final E = env.getElement("E") as ClassEntity;
  final F = env.getElement("F") as ClassEntity;
  final G = env.getElement("G") as ClassEntity;
  final H = env.getElement("H") as ClassEntity;
  final I = env.getElement("I") as ClassEntity;
  final Function_ = env.getElement("Function") as ClassEntity;

  void checkClass(ClassEntity cls, List<ClassEntity> expectedSubtypes,
      {bool checkSubset = false}) {
    ClassSet node = world.classHierarchy.getClassSet(cls);
    Set<ClassEntity> actualSubtypes = node.subtypes().toSet();
    if (checkSubset) {
      for (ClassEntity subtype in expectedSubtypes) {
        Expect.isTrue(
            actualSubtypes.contains(subtype),
            "Unexpected subtype ${subtype} of ${cls.name}:\n"
            "Expected: $expectedSubtypes\n"
            "Found   : $actualSubtypes");
      }
    } else {
      Expect.setEquals(
          expectedSubtypes,
          actualSubtypes,
          "Unexpected subtypes of ${cls.name}:\n"
          "Expected: $expectedSubtypes\n"
          "Found   : $actualSubtypes");
    }
  }

  checkClass(A, [A, C, E, F, G, B, D, H, I]);
  checkClass(B, [B, D, E]);
  checkClass(C, [C, E, F, G, H, B, D, I]);
  checkClass(D, [D]);
  checkClass(E, [E]);
  checkClass(F, [F]);
  checkClass(G, [G]);
  checkClass(H, [H, I]);
  checkClass(I, [I]);
  checkClass(Function_, [], checkSubset: true);
}
