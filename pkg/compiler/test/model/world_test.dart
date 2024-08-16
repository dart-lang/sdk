// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library world_test;

import 'package:compiler/src/elements/names.dart';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import 'package:compiler/src/universe/class_hierarchy.dart';
import 'package:compiler/src/universe/class_set.dart';
import '../helpers/type_test_helper.dart';

void main() {
  runTests() async {
    await testClassSets();
    await testProperties();
    await testNativeClasses();
    await testCommonSubclasses();
    await testLiveMembers();
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

testClassSets() async {
  var env = await TypeEnvironment.create(r"""
      import 'dart:html' as html;

      mixin class A implements X {}
      mixin class B {}
      class C_Super extends A {}
      class C extends C_Super {}
      class D implements A {}
      class E extends B implements A {}
      class F extends Object with A implements B {}
      class G extends Object with B, A {}
      class X {}

      main() {
        A();
        B();
        C();
        D();
        E();
        F();
        G();
        html.window;
        html.Worker('');
      }
      """, testBackendWorld: true);
  JClosedWorld closedWorld = env.jClosedWorld;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  final Object_ = env.getElement("Object") as ClassEntity;
  final A = env.getElement("A") as ClassEntity;
  final B = env.getElement("B") as ClassEntity;
  final C = env.getElement("C") as ClassEntity;
  final D = env.getElement("D") as ClassEntity;
  final E = env.getElement("E") as ClassEntity;
  final F = env.getElement("F") as ClassEntity;
  final G = env.getElement("G") as ClassEntity;
  final X = env.getElement("X") as ClassEntity;

  void checkClasses(String property, ClassEntity cls,
      Iterable<ClassEntity> foundClasses, List<ClassEntity> expectedClasses,
      {bool exact = true}) {
    for (ClassEntity expectedClass in expectedClasses) {
      Expect.isTrue(
          foundClasses.contains(expectedClass),
          "Expect $expectedClass in '$property' on $cls. "
          "Found:\n ${foundClasses.join('\n ')}\n"
          "${closedWorld.classHierarchy.dump(cls)}");
    }
    if (exact) {
      Expect.equals(
          expectedClasses.length,
          foundClasses.length,
          "Unexpected classes "
          "${foundClasses.where((c) => !expectedClasses.contains(c))} "
          "in '$property' on $cls.\n"
          "${closedWorld.classHierarchy.dump(cls)}");
    }
  }

  void check(String property, ClassEntity cls,
      Iterable<ClassEntity> foundClasses, List<ClassEntity> expectedClasses,
      {bool exact = true,
      void forEach(ClassEntity cls, ForEachFunction f)?,
      int getCount(ClassEntity cls)?}) {
    checkClasses(property, cls, foundClasses, expectedClasses, exact: exact);

    if (forEach != null) {
      List<ClassEntity> visited = <ClassEntity>[];
      forEach(cls, (ClassEntity c) {
        visited.add(c);
        return IterationStep.CONTINUE;
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
          "${closedWorld.classHierarchy.dump(cls)}");
    }
  }

  void testSubclasses(ClassEntity cls, List<ClassEntity> expectedClasses,
      {bool exact = true}) {
    check('subclassesOf', cls, closedWorld.classHierarchy.subclassesOf(cls),
        expectedClasses,
        exact: exact);
  }

  void testStrictSubclasses(ClassEntity cls, List<ClassEntity> expectedClasses,
      {bool exact = true}) {
    check('strictSubclassesOf', cls,
        closedWorld.classHierarchy.strictSubclassesOf(cls), expectedClasses,
        exact: exact,
        forEach: closedWorld.classHierarchy.forEachStrictSubclassOf,
        getCount: closedWorld.classHierarchy.strictSubclassCount);
  }

  void testStrictSubtypes(ClassEntity cls, List<ClassEntity> expectedClasses,
      {bool exact = true}) {
    check('strictSubtypesOf', cls,
        closedWorld.classHierarchy.strictSubtypesOf(cls), expectedClasses,
        exact: exact,
        forEach: closedWorld.classHierarchy.forEachStrictSubtypeOf,
        getCount: closedWorld.classHierarchy.strictSubtypeCount);
  }

  void testMixinUses(ClassEntity cls, List<ClassEntity> expectedClasses,
      {bool exact = true}) {
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
  testMixinUses(A, [
    elementEnvironment.getSuperClass(F)!,
    elementEnvironment.getSuperClass(G)!
  ]);
  testMixinUses(B, [
    elementEnvironment.getSuperClass(elementEnvironment.getSuperClass(G)!)!
  ]);
  testMixinUses(C, []);
  testMixinUses(D, []);
  testMixinUses(E, []);
  testMixinUses(F, []);
  testMixinUses(G, []);
  testMixinUses(X, []);
}

testProperties() async {
  var env = await TypeEnvironment.create(r"""
      mixin class A {}
      class A1 extends A {}
      class A2 implements A {}
      class A3 extends Object with A {}

      mixin class B {}
      class B1 extends B {}
      class B2 implements B {}
      class B3 extends Object with B {}

      mixin class C {}
      class C1 extends C {}
      class C2 implements C {}
      class C3 extends Object with C {}

      mixin class D {}
      class D1 extends D {}
      class D2 implements D {}
      class D3 extends Object with D {}

      mixin class E {}
      class E1 extends E {}
      class E2 implements E {}
      class E3 extends Object with E {}

      mixin class F {}
      class F1 extends F {}
      class F2 implements F {}
      class F3 extends Object with F {}

      mixin class G {}
      class G1 extends G {}
      class G2 extends G1 {}
      class G3 extends G2 implements G {}
      class G4 extends G2 with G {}

      mixin class H {}
      class H1 extends H {}
      class H2 extends H1 {}
      class H3 extends H2 implements H {}
      class H4 extends H2 with H {}

      main() {
        B();
        C1();
        D2();
        E3();
        F1();
        F2();
        G2();
        G3();
        H4();
      }
      """, testBackendWorld: true);
  JClosedWorld closedWorld = env.jClosedWorld;

  check(String name, {bool? hasStrictSubtype, bool? hasOnlySubclasses}) {
    final cls = env.getElement(name) as ClassEntity;
    Expect.equals(
        hasStrictSubtype,
        closedWorld.classHierarchy.hasAnyStrictSubtype(cls),
        "Unexpected hasAnyStrictSubtype property on $cls.");
    Expect.equals(
        hasOnlySubclasses,
        closedWorld.classHierarchy.hasOnlySubclasses(cls),
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
  var env = await TypeEnvironment.create(r"""
      import 'dart:html' as html;
      main() {
        html.window; // Creates 'Window'.
        html.Worker(''); // Creates 'Worker'.
        html.CanvasElement() // Creates CanvasElement
            ..getContext(''); // Creates CanvasRenderingContext2D
      }
      """, testBackendWorld: true);
  JClosedWorld closedWorld = env.jClosedWorld;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  LibraryEntity dart_html = elementEnvironment.lookupLibrary(Uris.dart_html)!;

  ClassEntity clsEventTarget =
      elementEnvironment.lookupClass(dart_html, 'EventTarget')!;
  ClassEntity clsWindow = elementEnvironment.lookupClass(dart_html, 'Window')!;
  ClassEntity clsAbstractWorker =
      elementEnvironment.lookupClass(dart_html, 'AbstractWorker')!;
  ClassEntity clsWorker = elementEnvironment.lookupClass(dart_html, 'Worker')!;
  ClassEntity clsCanvasElement =
      elementEnvironment.lookupClass(dart_html, 'CanvasElement')!;
  ClassEntity clsCanvasRenderingContext =
      elementEnvironment.lookupClass(dart_html, 'CanvasRenderingContext')!;
  ClassEntity clsCanvasRenderingContext2D =
      elementEnvironment.lookupClass(dart_html, 'CanvasRenderingContext2D')!;

  List<ClassEntity> allClasses = [
    clsEventTarget,
    clsWindow,
    clsAbstractWorker,
    clsWorker,
    clsCanvasElement,
    clsCanvasRenderingContext,
    clsCanvasRenderingContext2D
  ];

  check(ClassEntity cls,
      {required bool isDirectlyInstantiated,
      required bool isAbstractlyInstantiated,
      required bool isIndirectlyInstantiated,
      required bool hasStrictSubtype,
      required bool hasOnlySubclasses,
      ClassEntity? lubOfInstantiatedSubclasses,
      ClassEntity? lubOfInstantiatedSubtypes,
      int? instantiatedSubclassCount,
      int? instantiatedSubtypeCount,
      List<ClassEntity> subclasses = const <ClassEntity>[],
      List<ClassEntity> subtypes = const <ClassEntity>[]}) {
    ClassSet classSet = closedWorld.classHierarchy.getClassSet(cls);
    ClassHierarchyNode node = classSet.node;

    String dumpText = '\n${closedWorld.classHierarchy.dump(cls)}';

    Expect.equals(
        isDirectlyInstantiated,
        closedWorld.classHierarchy.isDirectlyInstantiated(cls),
        "Unexpected isDirectlyInstantiated property on $cls.$dumpText");
    Expect.equals(
        isAbstractlyInstantiated,
        closedWorld.classHierarchy.isAbstractlyInstantiated(cls),
        "Unexpected isAbstractlyInstantiated property on $cls.$dumpText");
    Expect.equals(
        isIndirectlyInstantiated,
        closedWorld.classHierarchy.isIndirectlyInstantiated(cls),
        "Unexpected isIndirectlyInstantiated property on $cls.$dumpText");
    Expect.equals(
        hasStrictSubtype,
        closedWorld.classHierarchy.hasAnyStrictSubtype(cls),
        "Unexpected hasAnyStrictSubtype property on $cls.$dumpText");
    Expect.equals(
        hasOnlySubclasses,
        closedWorld.classHierarchy.hasOnlySubclasses(cls),
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
    for (ClassEntity other in allClasses) {
      if (other == cls) continue;
      if (!closedWorld.classHierarchy.isExplicitlyInstantiated(other)) continue;
      Expect.equals(
          subclasses.contains(other),
          closedWorld.classHierarchy.isSubclassOf(other, cls),
          "Unexpected subclass relation between $other and $cls.");
      Expect.equals(
          subtypes.contains(other),
          closedWorld.classHierarchy.isSubtypeOf(other, cls),
          "Unexpected subtype relation between $other and $cls.");
    }

    Set<ClassEntity> strictSubclasses = Set<ClassEntity>();
    closedWorld.classHierarchy.forEachStrictSubclassOf(cls,
        (ClassEntity other) {
      if (allClasses.contains(other)) {
        strictSubclasses.add(other);
      }
      return IterationStep.CONTINUE;
    });
    Expect.setEquals(subclasses, strictSubclasses,
        "Unexpected strict subclasses of $cls: ${strictSubclasses}.");

    Set<ClassEntity> strictSubtypes = Set<ClassEntity>();
    closedWorld.classHierarchy.forEachStrictSubtypeOf(cls, (ClassEntity other) {
      if (allClasses.contains(other)) {
        strictSubtypes.add(other);
      }
      return IterationStep.CONTINUE;
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

testCommonSubclasses() async {
  var env = await TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends A {}
      class D implements A {}
      class E extends B {}
      class F implements C, E {}
      class G extends C implements E {}
      class H implements C {}
      class I extends D implements E {}
      class J extends E implements D {}
      main() {
        A();
        B();
        C();
        D();
        E();
        F();
        G();
        H();
        I();
        J();
      }
      """, testBackendWorld: true);
  JClosedWorld closedWorld = env.jClosedWorld;

  final A = env.getElement("A") as ClassEntity;
  final B = env.getElement("B") as ClassEntity;
  final C = env.getElement("C") as ClassEntity;
  final F = env.getElement("F") as ClassEntity;
  final G = env.getElement("G") as ClassEntity;
  final I = env.getElement("I") as ClassEntity;
  final J = env.getElement("J") as ClassEntity;

  ClassQuery? toClassQuery(SubclassResult result, ClassEntity cls1,
      ClassQuery query1, ClassEntity cls2, ClassQuery query2) {
    switch (result) {
      case SimpleSubclassResult.empty:
        return null;
      case SimpleSubclassResult.exact1:
        return ClassQuery.EXACT;
      case SimpleSubclassResult.exact2:
        return ClassQuery.EXACT;
      case SimpleSubclassResult.subclass1:
        return ClassQuery.SUBCLASS;
      case SimpleSubclassResult.subclass2:
        return ClassQuery.SUBCLASS;
      case SimpleSubclassResult.subtype1:
        return ClassQuery.SUBTYPE;
      case SimpleSubclassResult.subtype2:
        return ClassQuery.SUBTYPE;
      case SetSubclassResult():
        return null;
    }
  }

  ClassEntity? toClassEntity(SubclassResult result, ClassEntity cls1,
      ClassQuery query1, ClassEntity cls2, ClassQuery query2) {
    switch (result) {
      case SimpleSubclassResult.empty:
        return null;
      case SimpleSubclassResult.exact1:
        return cls1;
      case SimpleSubclassResult.exact2:
        return cls2;
      case SimpleSubclassResult.subclass1:
        return cls1;
      case SimpleSubclassResult.subclass2:
        return cls2;
      case SimpleSubclassResult.subtype1:
        return cls1;
      case SimpleSubclassResult.subtype2:
        return cls2;
      case SetSubclassResult():
        return null;
    }
  }

  void check(ClassEntity cls1, ClassQuery query1, ClassEntity cls2,
      ClassQuery query2, SubclassResult expectedResult) {
    SubclassResult result1 =
        closedWorld.classHierarchy.commonSubclasses(cls1, query1, cls2, query2);
    SubclassResult result2 =
        closedWorld.classHierarchy.commonSubclasses(cls2, query2, cls1, query1);
    Expect.equals(
        toClassQuery(result1, cls1, query1, cls2, query2),
        toClassQuery(result2, cls2, query2, cls1, query1),
        "Asymmetric results for ($cls1,$query1) vs ($cls2,$query2):"
        "\n a vs b: $result1\n b vs a: $result2");
    Expect.equals(
        toClassEntity(result1, cls1, query1, cls2, query2),
        toClassEntity(result2, cls2, query2, cls1, query1),
        "Asymmetric results for ($cls1,$query1) vs ($cls2,$query2):"
        "\n a vs b: $result1\n b vs a: $result2");
    switch (expectedResult) {
      case SimpleSubclassResult():
        Expect.equals(
            expectedResult,
            result1,
            "Unexpected results for ($cls1,$query1) vs ($cls2,$query2):"
            "\n expected: $expectedResult\n actual: $result1");
      case SetSubclassResult():
        Expect.type<SetSubclassResult>(result1);
        Expect.type<SetSubclassResult>(result2);
        result1 as SetSubclassResult;
        result2 as SetSubclassResult;
        Expect.setEquals(
            result1.classes,
            result2.classes,
            "Asymmetric results for ($cls1,$query1) vs ($cls2,$query2):"
            "\n a vs b: $result1\n b vs a: $result2");
        Expect.setEquals(
            expectedResult.classes,
            result1.classes,
            "Unexpected results for ($cls1,$query1) vs ($cls2,$query2):"
            "\n expected: $expectedResult\n actual: $result1");
    }
  }

  check(A, ClassQuery.EXACT, A, ClassQuery.EXACT, SimpleSubclassResult.exact1);
  check(
      A, ClassQuery.EXACT, A, ClassQuery.SUBCLASS, SimpleSubclassResult.exact1);
  check(
      A, ClassQuery.EXACT, A, ClassQuery.SUBTYPE, SimpleSubclassResult.exact1);
  check(A, ClassQuery.SUBCLASS, A, ClassQuery.SUBCLASS,
      SimpleSubclassResult.subclass1);
  check(A, ClassQuery.SUBCLASS, A, ClassQuery.SUBTYPE,
      SimpleSubclassResult.subclass1);
  check(A, ClassQuery.SUBTYPE, A, ClassQuery.SUBTYPE,
      SimpleSubclassResult.subtype1);

  check(A, ClassQuery.EXACT, B, ClassQuery.EXACT, SimpleSubclassResult.empty);
  check(
      A, ClassQuery.EXACT, B, ClassQuery.SUBCLASS, SimpleSubclassResult.empty);
  check(
      A, ClassQuery.SUBCLASS, B, ClassQuery.EXACT, SimpleSubclassResult.empty);
  check(A, ClassQuery.EXACT, B, ClassQuery.SUBTYPE, SimpleSubclassResult.empty);
  check(A, ClassQuery.SUBTYPE, B, ClassQuery.EXACT, SimpleSubclassResult.empty);
  check(A, ClassQuery.SUBCLASS, B, ClassQuery.SUBCLASS,
      SimpleSubclassResult.empty);
  check(A, ClassQuery.SUBCLASS, B, ClassQuery.SUBTYPE, SetSubclassResult([G]));
  check(A, ClassQuery.SUBTYPE, B, ClassQuery.SUBCLASS, SetSubclassResult([J]));
  check(A, ClassQuery.SUBTYPE, B, ClassQuery.SUBTYPE,
      SetSubclassResult([F, G, I, J]));

  check(A, ClassQuery.EXACT, C, ClassQuery.EXACT, SimpleSubclassResult.empty);
  check(
      A, ClassQuery.EXACT, C, ClassQuery.SUBCLASS, SimpleSubclassResult.empty);
  check(
      A, ClassQuery.SUBCLASS, C, ClassQuery.EXACT, SimpleSubclassResult.exact2);
  check(A, ClassQuery.EXACT, C, ClassQuery.SUBTYPE, SimpleSubclassResult.empty);
  check(
      A, ClassQuery.SUBTYPE, C, ClassQuery.EXACT, SimpleSubclassResult.exact2);
  check(A, ClassQuery.SUBCLASS, C, ClassQuery.SUBCLASS,
      SimpleSubclassResult.subclass2);
  check(A, ClassQuery.SUBCLASS, C, ClassQuery.SUBTYPE, SetSubclassResult([C]));
  check(A, ClassQuery.SUBTYPE, C, ClassQuery.SUBCLASS,
      SimpleSubclassResult.subclass2);
  check(A, ClassQuery.SUBTYPE, C, ClassQuery.SUBTYPE,
      SimpleSubclassResult.subtype2);

  check(B, ClassQuery.EXACT, C, ClassQuery.EXACT, SimpleSubclassResult.empty);
  check(
      B, ClassQuery.EXACT, C, ClassQuery.SUBCLASS, SimpleSubclassResult.empty);
  check(
      B, ClassQuery.SUBCLASS, C, ClassQuery.EXACT, SimpleSubclassResult.empty);
  check(B, ClassQuery.EXACT, C, ClassQuery.SUBTYPE, SimpleSubclassResult.empty);
  check(B, ClassQuery.SUBTYPE, C, ClassQuery.EXACT, SimpleSubclassResult.empty);
  check(B, ClassQuery.SUBCLASS, C, ClassQuery.SUBCLASS,
      SimpleSubclassResult.empty);
  check(B, ClassQuery.SUBCLASS, C, ClassQuery.SUBTYPE, SetSubclassResult([]));
  check(B, ClassQuery.SUBTYPE, C, ClassQuery.SUBCLASS, SetSubclassResult([G]));
  check(
      B, ClassQuery.SUBTYPE, C, ClassQuery.SUBTYPE, SetSubclassResult([F, G]));
}

testLiveMembers() async {
  final env = await TypeEnvironment.create(r"""
      class A { int a() => 1; }

      mixin B { int b(); }
      class C with B { int b() => 2; }

      mixin D { int d(); }
      mixin E on D { int e() => d(); }
      class F implements D { int d() => 3; }
      class G extends F with E {}

      abstract class H { int h(); }
      class I implements H { int h() => 4; }

      abstract class J { int j(); }

      abstract class K { int k(); }
      class L extends K { int k() => 5; }

      abstract class M { int m(); }
      class N extends M { int m() => 6; }

      main() {
        A().a();
        C().b();
        G().e();
        I().h();
        L().k();
        N();
      }
      """, testBackendWorld: true);

  JClosedWorld closedWorld = env.jClosedWorld;

  void check(String clsName, String memberName,
      {bool expectExists = true,
      bool expectAbstract = false,
      bool expectConcrete = false}) {
    final cls = env.getClass(clsName);
    final member = closedWorld.elementEnvironment
        .lookupLocalClassMember(cls, Name(memberName, Uri()));
    if (expectExists) {
      Expect.isNotNull(
          member, "Expected $clsName to contain member $memberName.");
    } else {
      Expect.isNull(
          member, "Expected $clsName not to contain member $memberName.");
      return;
    }
    Expect.isTrue(
        expectAbstract ^ expectConcrete,
        "Can only expect to be in one of liveAbstractInstanceMembers and "
        "liveInstanceMembers.");
    if (expectAbstract) {
      Expect.isTrue(closedWorld.liveAbstractInstanceMembers.contains(member),
          "Expected $member to exist in liveAbstractInstanceMembers.");
      Expect.isFalse(closedWorld.liveInstanceMembers.contains(member),
          "Expected $member to not exist in liveInstanceMembers.");
    } else {
      Expect.isTrue(closedWorld.liveInstanceMembers.contains(member),
          "Expected $member to exist in liveInstanceMembers.");
      Expect.isFalse(closedWorld.liveAbstractInstanceMembers.contains(member),
          "Expected $member to not exist in liveAbstractInstanceMembers.");
    }
  }

  check('A', 'a', expectConcrete: true);
  check('B', 'b', expectAbstract: true);
  check('C', 'b', expectConcrete: true);
  check('D', 'd', expectAbstract: true);
  check('E', 'e', expectConcrete: true);
  check('F', 'd', expectConcrete: true);
  check('H', 'h', expectAbstract: true);
  check('I', 'h', expectConcrete: true);
  check('J', 'j', expectExists: false);
  check('K', 'k', expectAbstract: true);
  check('L', 'k', expectConcrete: true);
  check('M', 'm', expectExists: false);
  check('N', 'm', expectExists: false);
}
