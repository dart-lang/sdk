// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library world_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/elements/elements.dart'
       show Element, ClassElement;
import 'package:compiler/src/dart2jslib.dart';

void main() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends A {}
      class D implements A {}
      class E extends B implements A {}
      class F extends Object with A implements B {}
      class G extends Object with A, B {}
      """,
      mainSource: r"""
      main() {
        new A();
        new B();
        new C();
        new D();
        new E();
        new F();
        new G();
      }
      """,
      useMockCompiler: false).then((env) {
    ClassWorld classWorld = env.compiler.world;

    ClassElement Object_ = env.getElement("Object");
    ClassElement A = env.getElement("A");
    ClassElement B = env.getElement("B");
    ClassElement C = env.getElement("C");
    ClassElement D = env.getElement("D");
    ClassElement E = env.getElement("E");
    ClassElement F = env.getElement("F");
    ClassElement G = env.getElement("G");

    void check(
        String property,
        ClassElement cls,
        Iterable<ClassElement> foundClasses,
        List<ClassElement> expectedClasses,
        {bool exact: true}) {
      for (ClassElement expectedClass in expectedClasses) {
        Expect.isTrue(foundClasses.contains(expectedClass),
            "Expect $expectedClass in '$property' on $cls. "
            "Found:\n ${foundClasses.join('\n ')}");
      }
      if (exact) {
        Expect.equals(expectedClasses.length, foundClasses.length,
            "Unexpected classes "
            "${foundClasses.where((c) => !expectedClasses.contains(c))} "
            "in '$property' on $cls.");
      }
    }

    void testStrictSubclasses(
        ClassElement cls,
        List<ClassElement> expectedClasses,
        {bool exact: true}) {
      check(
        'strictSubclassesOf',
        cls,
        classWorld.strictSubclassesOf(cls),
        expectedClasses,
        exact: exact);
    }

    void testStrictSubtypes(
        ClassElement cls,
        List<ClassElement> expectedClasses,
        {bool exact: true}) {
      check(
        'strictSubtypesOf',
        cls,
        classWorld.strictSubtypesOf(cls),
        expectedClasses,
        exact: exact);
    }

    void testMixinUses(
        ClassElement cls,
        List<ClassElement> expectedClasses,
        {bool exact: true}) {
      check(
        'mixinUsesOf',
        cls,
        classWorld.mixinUsesOf(cls),
        expectedClasses,
        exact: exact);
    }

    testStrictSubclasses(Object_, [A, B, C, D, E, F, G], exact: false);
    testStrictSubclasses(A, [C]);
    testStrictSubclasses(B, [E]);
    testStrictSubclasses(C, []);
    testStrictSubclasses(D, []);
    testStrictSubclasses(E, []);
    testStrictSubclasses(F, []);
    testStrictSubclasses(G, []);

    testStrictSubtypes(Object_, [A, B, C, D, E, F, G], exact: false);
    testStrictSubtypes(A, [C, D, E, F, G]);
    testStrictSubtypes(B, [E, F, G]);
    testStrictSubtypes(C, []);
    testStrictSubtypes(D, []);
    testStrictSubtypes(E, []);
    testStrictSubtypes(F, []);
    testStrictSubtypes(G, []);

    testMixinUses(Object_, []);
    testMixinUses(A, [F.superclass, G.superclass.superclass]);
    testMixinUses(B, [G.superclass]);
    testMixinUses(C, []);
    testMixinUses(D, []);
    testMixinUses(E, []);
    testMixinUses(F, []);
    testMixinUses(G, []);

  }));
}
