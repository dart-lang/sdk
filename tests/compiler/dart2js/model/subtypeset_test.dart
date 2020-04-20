// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test for iterators on for [SubclassNode].

library subtypeset_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/world.dart';
import '../helpers/type_test_helper.dart';

void main() {
  asyncTest(() async {
    // TODO(johnniwinther): Remove code for Dart 1 tests.
    await runTests(strongMode: true);
  });
}

runTests({bool strongMode: false}) async {
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
        new A().call;
        new C();
        new D();
        new E();
        new F();
        new G();
      }
      """);
  KClosedWorld world = env.kClosedWorld;

  ClassEntity A = env.getElement("A");
  ClassEntity B = env.getElement("B");
  ClassEntity C = env.getElement("C");
  ClassEntity D = env.getElement("D");
  ClassEntity E = env.getElement("E");
  ClassEntity F = env.getElement("F");
  ClassEntity G = env.getElement("G");
  ClassEntity H = env.getElement("H");
  ClassEntity I = env.getElement("I");
  ClassEntity Function_ = env.getElement("Function");

  void checkClass(ClassEntity cls, List<ClassEntity> expectedSubtypes,
      {bool checkSubset: false}) {
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
  checkClass(Function_, strongMode ? [] : [A, B, C, D, E, F, G],
      checkSubset: true);
}
