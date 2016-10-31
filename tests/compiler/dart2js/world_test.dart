// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library world_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/elements/elements.dart'
    show Element, ClassElement, LibraryElement;
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;

void main() {
  asyncTest(() async {
    await testClassSets();
    await testProperties();
    await testNativeClasses();
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
      import 'dart:html' as html;
      main() {
        new A();
        new B();
        new C();
        new D();
        new E();
        new F();
        new G();
        html.window;
        new html.Worker('');
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

testNativeClasses() async {
  var env = await TypeEnvironment.create('',
      mainSource: r"""
      import 'dart:html' as html;
      main() {
        html.window; // Creates 'Window'.
        new html.Worker(''); // Creates 'Worker'.
        new html.CanvasElement() // Creates CanvasElement
            ..getContext(''); // Creates CanvasRenderingContext2D
      }
      """,
      useMockCompiler: false);
  ClosedWorld closedWorld = env.compiler.closedWorld;
  LibraryElement dart_html =
      env.compiler.libraryLoader.lookupLibrary(Uris.dart_html);

  ClassElement clsEventTarget = dart_html.findExported('EventTarget');
  ClassElement clsWindow = dart_html.findExported('Window');
  ClassElement clsAbstractWorker = dart_html.findExported('AbstractWorker');
  ClassElement clsWorker = dart_html.findExported('Worker');
  ClassElement clsCanvasElement = dart_html.findExported('CanvasElement');
  ClassElement clsCanvasRenderingContext =
      dart_html.findExported('CanvasRenderingContext');
  ClassElement clsCanvasRenderingContext2D =
      dart_html.findExported('CanvasRenderingContext2D');

  List<ClassElement> allClasses = [
    clsEventTarget,
    clsWindow,
    clsAbstractWorker,
    clsWorker,
    clsCanvasElement,
    clsCanvasRenderingContext,
    clsCanvasRenderingContext2D
  ];

  check(ClassElement cls,
      {bool isDirectlyInstantiated,
      bool isAbstractlyInstantiated,
      bool isIndirectlyInstantiated,
      bool hasStrictSubtype,
      bool hasOnlySubclasses,
      ClassElement lubOfInstantiatedSubclasses,
      ClassElement lubOfInstantiatedSubtypes,
      int instantiatedSubclassCount,
      int instantiatedSubtypeCount,
      List<ClassElement> subclasses: const <ClassElement>[],
      List<ClassElement> subtypes: const <ClassElement>[]}) {
    ClassSet classSet = closedWorld.getClassSet(cls);
    ClassHierarchyNode node = classSet.node;

    String dumpText = '\n${closedWorld.dump(cls)}';

    Expect.equals(
        isDirectlyInstantiated,
        closedWorld.isDirectlyInstantiated(cls),
        "Unexpected isDirectlyInstantiated property on $cls.$dumpText");
    Expect.equals(
        isAbstractlyInstantiated,
        closedWorld.isAbstractlyInstantiated(cls),
        "Unexpected isAbstractlyInstantiated property on $cls.$dumpText");
    Expect.equals(
        isIndirectlyInstantiated,
        closedWorld.isIndirectlyInstantiated(cls),
        "Unexpected isIndirectlyInstantiated property on $cls.$dumpText");
    Expect.equals(hasStrictSubtype, closedWorld.hasAnyStrictSubtype(cls),
        "Unexpected hasAnyStrictSubtype property on $cls.$dumpText");
    Expect.equals(hasOnlySubclasses, closedWorld.hasOnlySubclasses(cls),
        "Unexpected hasOnlySubclasses property on $cls.$dumpText");
    Expect.equals(
        lubOfInstantiatedSubclasses,
        node.getLubOfInstantiatedSubclasses(),
        "Unexpected getLubOfInstantiatedSubclasses() result on $cls.$dumpText");
    Expect.equals(
        lubOfInstantiatedSubtypes,
        classSet.getLubOfInstantiatedSubtypes(),
        "Unexpected getLubOfInstantiatedSubtypes() result on $cls.$dumpText");
    if (instantiatedSubclassCount != null) {
      Expect.equals(instantiatedSubclassCount, node.instantiatedSubclassCount,
          "Unexpected instantiatedSubclassCount property on $cls.$dumpText");
    }
    if (instantiatedSubtypeCount != null) {
      Expect.equals(instantiatedSubtypeCount, classSet.instantiatedSubtypeCount,
          "Unexpected instantiatedSubtypeCount property on $cls.$dumpText");
    }
    for (ClassElement other in allClasses) {
      if (other == cls) continue;
      if (!closedWorld.isExplicitlyInstantiated(other)) continue;
      Expect.equals(
          subclasses.contains(other),
          closedWorld.isSubclassOf(other, cls),
          "Unexpected subclass relation between $other and $cls.");
      Expect.equals(
          subtypes.contains(other),
          closedWorld.isSubtypeOf(other, cls),
          "Unexpected subtype relation between $other and $cls.");
    }

    Set<ClassElement> strictSubclasses = new Set<ClassElement>();
    closedWorld.forEachStrictSubclassOf(cls, (ClassElement other) {
      if (allClasses.contains(other)) {
        strictSubclasses.add(other);
      }
    });
    Expect.setEquals(subclasses, strictSubclasses,
        "Unexpected strict subclasses of $cls: ${strictSubclasses}.");

    Set<ClassElement> strictSubtypes = new Set<ClassElement>();
    closedWorld.forEachStrictSubtypeOf(cls, (ClassElement other) {
      if (allClasses.contains(other)) {
        strictSubtypes.add(other);
      }
    });
    Expect.setEquals(subtypes, strictSubtypes,
        "Unexpected strict subtypes of $cls: $strictSubtypes.");
  }

  // Extended by Window.
  check(clsEventTarget,
      isDirectlyInstantiated: false,
      isAbstractlyInstantiated: false,
      isIndirectlyInstantiated: true,
      hasStrictSubtype: true,
      hasOnlySubclasses: true,
      lubOfInstantiatedSubclasses: clsEventTarget,
      lubOfInstantiatedSubtypes: clsEventTarget,
      // May vary with implementation, do no test.
      instantiatedSubclassCount: null,
      instantiatedSubtypeCount: null,
      subclasses: [clsWindow, clsCanvasElement, clsWorker],
      subtypes: [clsWindow, clsCanvasElement, clsWorker]);

  // Created by 'html.window'.
  check(clsWindow,
      isDirectlyInstantiated: false,
      isAbstractlyInstantiated: true,
      isIndirectlyInstantiated: false,
      hasStrictSubtype: false,
      hasOnlySubclasses: true,
      lubOfInstantiatedSubclasses: clsWindow,
      lubOfInstantiatedSubtypes: clsWindow,
      instantiatedSubclassCount: 0,
      instantiatedSubtypeCount: 0);

  // Implemented by 'Worker'.
  check(clsAbstractWorker,
      isDirectlyInstantiated: false,
      isAbstractlyInstantiated: false,
      isIndirectlyInstantiated: false,
      hasStrictSubtype: true,
      hasOnlySubclasses: false,
      lubOfInstantiatedSubclasses: null,
      lubOfInstantiatedSubtypes: clsWorker,
      instantiatedSubclassCount: 0,
      instantiatedSubtypeCount: 1,
      subtypes: [clsWorker]);

  // Created by 'new html.Worker'.
  check(clsWorker,
      isDirectlyInstantiated: false,
      isAbstractlyInstantiated: true,
      isIndirectlyInstantiated: false,
      hasStrictSubtype: false,
      hasOnlySubclasses: true,
      lubOfInstantiatedSubclasses: clsWorker,
      lubOfInstantiatedSubtypes: clsWorker,
      instantiatedSubclassCount: 0,
      instantiatedSubtypeCount: 0);

  // Created by 'new html.CanvasElement'.
  check(clsCanvasElement,
      isDirectlyInstantiated: false,
      isAbstractlyInstantiated: true,
      isIndirectlyInstantiated: false,
      hasStrictSubtype: false,
      hasOnlySubclasses: true,
      lubOfInstantiatedSubclasses: clsCanvasElement,
      lubOfInstantiatedSubtypes: clsCanvasElement,
      instantiatedSubclassCount: 0,
      instantiatedSubtypeCount: 0);

  // Implemented by CanvasRenderingContext2D and RenderingContext.
  check(clsCanvasRenderingContext,
      isDirectlyInstantiated: false,
      isAbstractlyInstantiated: false,
      isIndirectlyInstantiated: false,
      hasStrictSubtype: true,
      hasOnlySubclasses: false,
      lubOfInstantiatedSubclasses: null,
      lubOfInstantiatedSubtypes: clsCanvasRenderingContext,
      instantiatedSubclassCount: 0,
      instantiatedSubtypeCount: 2,
      subtypes: [clsCanvasRenderingContext2D]);

  // Created by 'html.CanvasElement.getContext'.
  check(clsCanvasRenderingContext2D,
      isDirectlyInstantiated: false,
      isAbstractlyInstantiated: true,
      isIndirectlyInstantiated: false,
      hasStrictSubtype: false,
      hasOnlySubclasses: true,
      lubOfInstantiatedSubclasses: clsCanvasRenderingContext2D,
      lubOfInstantiatedSubtypes: clsCanvasRenderingContext2D,
      instantiatedSubclassCount: 0,
      instantiatedSubtypeCount: 0);
}
