// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library world_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/elements/elements.dart' show Element, ClassElement;
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;

void main() {
  asyncTest(() async {
    await testClassSets();
    await testProperties();
  });
}

testClassSets() async {
  var env = await TypeEnvironment.create(
      r"""
      class A implements X {}
      class B {}
      class C_Super extends A {}
      class C extends C_Super {}
      class D implements A {}
      class E extends B implements A {}
      class F extends Object with A implements B {}
      class G extends Object with A, B {}
      class X {}
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
      useMockCompiler: false);
  ClosedWorld closedWorld = env.compiler.closedWorld;

  ClassElement Object_ = env.getElement("Object");
  ClassElement A = env.getElement("A");
  ClassElement B = env.getElement("B");
  ClassElement C = env.getElement("C");
  ClassElement D = env.getElement("D");
  ClassElement E = env.getElement("E");
  ClassElement F = env.getElement("F");
  ClassElement G = env.getElement("G");
  ClassElement X = env.getElement("X");

  void checkClasses(String property, ClassElement cls,
      Iterable<ClassElement> foundClasses, List<ClassElement> expectedClasses,
      {bool exact: true}) {
    for (ClassElement expectedClass in expectedClasses) {
      Expect.isTrue(
          foundClasses.contains(expectedClass),
          "Expect $expectedClass in '$property' on $cls. "
          "Found:\n ${foundClasses.join('\n ')}\n"
          "${env.compiler.closedWorld.dump(cls)}");
    }
    if (exact) {
      Expect.equals(
          expectedClasses.length,
          foundClasses.length,
          "Unexpected classes "
          "${foundClasses.where((c) => !expectedClasses.contains(c))} "
          "in '$property' on $cls.\n"
          "${env.compiler.closedWorld.dump(cls)}");
    }
  }

  void check(String property, ClassElement cls,
      Iterable<ClassElement> foundClasses, List<ClassElement> expectedClasses,
      {bool exact: true,
      void forEach(ClassElement cls, ForEachFunction f),
      int getCount(ClassElement cls)}) {
    checkClasses(property, cls, foundClasses, expectedClasses, exact: exact);

    if (forEach != null) {
      List<ClassElement> visited = <ClassElement>[];
      forEach(cls, (ClassElement c) {
        visited.add(c);
      });
      checkClasses('forEach($property)', cls, visited, expectedClasses,
          exact: exact);
    }

    if (getCount != null && exact) {
      int count = getCount(cls);
      Expect.equals(
          expectedClasses.length,
          count,
          "Unexpected class count in '$property' on $cls.\n"
          "${env.compiler.closedWorld.dump(cls)}");
    }
  }

  void testSubclasses(ClassElement cls, List<ClassElement> expectedClasses,
      {bool exact: true}) {
    check('subclassesOf', cls, closedWorld.subclassesOf(cls), expectedClasses,
        exact: exact);
  }

  void testStrictSubclasses(
      ClassElement cls, List<ClassElement> expectedClasses,
      {bool exact: true}) {
    check('strictSubclassesOf', cls, closedWorld.strictSubclassesOf(cls),
        expectedClasses,
        exact: exact,
        forEach: closedWorld.forEachStrictSubclassOf,
        getCount: closedWorld.strictSubclassCount);
  }

  void testStrictSubtypes(ClassElement cls, List<ClassElement> expectedClasses,
      {bool exact: true}) {
    check('strictSubtypesOf', cls, closedWorld.strictSubtypesOf(cls),
        expectedClasses,
        exact: exact,
        forEach: closedWorld.forEachStrictSubtypeOf,
        getCount: closedWorld.strictSubtypeCount);
  }

  void testMixinUses(ClassElement cls, List<ClassElement> expectedClasses,
      {bool exact: true}) {
    check('mixinUsesOf', cls, closedWorld.mixinUsesOf(cls), expectedClasses,
        exact: exact);
  }

  testSubclasses(Object_, [A, B, C, D, E, F, G], exact: false);
  testSubclasses(A, [A, C]);
  testSubclasses(B, [B, E]);
  testSubclasses(C, [C]);
  testSubclasses(D, [D]);
  testSubclasses(E, [E]);
  testSubclasses(F, [F]);
  testSubclasses(G, [G]);
  testSubclasses(X, []);

  testStrictSubclasses(Object_, [A, B, C, D, E, F, G], exact: false);
  testStrictSubclasses(A, [C]);
  testStrictSubclasses(B, [E]);
  testStrictSubclasses(C, []);
  testStrictSubclasses(D, []);
  testStrictSubclasses(E, []);
  testStrictSubclasses(F, []);
  testStrictSubclasses(G, []);
  testStrictSubclasses(X, []);

  testStrictSubtypes(Object_, [A, B, C, D, E, F, G], exact: false);
  testStrictSubtypes(A, [C, D, E, F, G]);
  testStrictSubtypes(B, [E, F, G]);
  testStrictSubtypes(C, []);
  testStrictSubtypes(D, []);
  testStrictSubtypes(E, []);
  testStrictSubtypes(F, []);
  testStrictSubtypes(G, []);
  testStrictSubtypes(X, [A, C, D, E, F, G]);

  testMixinUses(Object_, []);
  testMixinUses(A, [F.superclass, G.superclass.superclass]);
  testMixinUses(B, [G.superclass]);
  testMixinUses(C, []);
  testMixinUses(D, []);
  testMixinUses(E, []);
  testMixinUses(F, []);
  testMixinUses(G, []);
  testMixinUses(X, []);
}

testProperties() async {
  var env = await TypeEnvironment.create(
      r"""
      class A {}
      class A1 extends A {}
      class A2 implements A {}
      class A3 extends Object with A {}

      class B {}
      class B1 extends B {}
      class B2 implements B {}
      class B3 extends Object with B {}

      class C {}
      class C1 extends C {}
      class C2 implements C {}
      class C3 extends Object with C {}

      class D {}
      class D1 extends D {}
      class D2 implements D {}
      class D3 extends Object with D {}

      class E {}
      class E1 extends E {}
      class E2 implements E {}
      class E3 extends Object with E {}

      class F {}
      class F1 extends F {}
      class F2 implements F {}
      class F3 extends Object with F {}

      class G {}
      class G1 extends G {}
      class G2 extends G1 {}
      class G3 extends G2 implements G {}
      class G4 extends G2 with G {}

      class H {}
      class H1 extends H {}
      class H2 extends H1 {}
      class H3 extends H2 implements H {}
      class H4 extends H2 with H {}
      """,
      mainSource: r"""
      main() {
        new B();
        new C1();
        new D2();
        new E3();
        new F1();
        new F2();
        new G2();
        new G3();
        new H4();
      }
      """,
      useMockCompiler: false);
  ClosedWorld closedWorld = env.compiler.closedWorld;

  check(String name, {bool hasStrictSubtype, bool hasOnlySubclasses}) {
    ClassElement cls = env.getElement(name);
    Expect.equals(hasStrictSubtype, closedWorld.hasAnyStrictSubtype(cls),
        "Unexpected hasAnyStrictSubtype property on $cls.");
    Expect.equals(hasOnlySubclasses, closedWorld.hasOnlySubclasses(cls),
        "Unexpected hasOnlySubclasses property on $cls.");
  }

  check("Object", hasStrictSubtype: true, hasOnlySubclasses: true);

  // No instantiated Ax classes.
  check("A", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("A1", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("A2", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("A3", hasStrictSubtype: false, hasOnlySubclasses: true);

  // class B instantiated
  check("B", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("B1", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("B2", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("B3", hasStrictSubtype: false, hasOnlySubclasses: true);

  // class C1 extends C instantiated
  check("C", hasStrictSubtype: true, hasOnlySubclasses: true);
  check("C1", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("C2", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("C3", hasStrictSubtype: false, hasOnlySubclasses: true);

  // class D2 implements D instantiated
  check("D", hasStrictSubtype: true, hasOnlySubclasses: false);
  check("D1", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("D2", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("D3", hasStrictSubtype: false, hasOnlySubclasses: true);

  // class E2 extends Object with E instantiated
  check("E", hasStrictSubtype: true, hasOnlySubclasses: false);
  check("E1", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("E2", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("E3", hasStrictSubtype: false, hasOnlySubclasses: true);

  // class F1 extends F instantiated
  // class F2 implements F instantiated
  check("F", hasStrictSubtype: true, hasOnlySubclasses: false);
  check("F1", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("F2", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("F3", hasStrictSubtype: false, hasOnlySubclasses: true);

  // class G2 extends G1 extends G instantiated
  // class G3 extends G2 extends G1 extends G instantiated
  check("G", hasStrictSubtype: true, hasOnlySubclasses: true);
  check("G1", hasStrictSubtype: true, hasOnlySubclasses: true);
  check("G2", hasStrictSubtype: true, hasOnlySubclasses: true);
  check("G3", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("G4", hasStrictSubtype: false, hasOnlySubclasses: true);

  // class H4 extends H2 with H extends H1 extends H instantiated
  check("H", hasStrictSubtype: true, hasOnlySubclasses: true);
  check("H1", hasStrictSubtype: true, hasOnlySubclasses: true);
  check("H2", hasStrictSubtype: true, hasOnlySubclasses: true);
  check("H3", hasStrictSubtype: false, hasOnlySubclasses: true);
  check("H4", hasStrictSubtype: false, hasOnlySubclasses: true);
}
