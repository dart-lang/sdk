// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for iterators on for [SubclassNode].

library class_set_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/elements/elements.dart' show ClassElement;
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/util/enumset.dart';
import 'package:compiler/src/util/util.dart';
import 'package:compiler/src/world.dart';

void main() {
  asyncTest(() async {
    await testIterators();
    await testForEach();
  });
}

testIterators() async {
  var env = await TypeEnvironment.create(
      r"""
      ///        A
      ///       / \
      ///      B   C
      ///     /   /|\
      ///    D   E F G
      ///
      class A {}
      class B extends A {}
      class C extends A {}
      class D extends B {}
      class E extends C {}
      class F extends C {}
      class G extends C {}
      """,
      mainSource: r"""
      main() {
        new A();
        new C();
        new D();
        new E();
        new F();
        new G();
      }
      """,
      useMockCompiler: false);
  ClosedWorld world = env.closedWorld;

  ClassElement A = env.getElement("A");
  ClassElement B = env.getElement("B");
  ClassElement C = env.getElement("C");
  ClassElement D = env.getElement("D");
  ClassElement E = env.getElement("E");
  ClassElement F = env.getElement("F");
  ClassElement G = env.getElement("G");

  void checkClass(ClassElement cls,
      {bool directlyInstantiated: false, bool indirectlyInstantiated: false}) {
    ClassHierarchyNode node = world.getClassHierarchyNode(cls);
    Expect.isNotNull(node, "Expected ClassHierarchyNode for $cls.");
    Expect.equals(
        directlyInstantiated || indirectlyInstantiated,
        node.isInstantiated,
        "Unexpected `isInstantiated` on ClassHierarchyNode for $cls.");
    Expect.equals(
        directlyInstantiated,
        node.isDirectlyInstantiated,
        "Unexpected `isDirectlyInstantiated` on ClassHierarchyNode for "
        "$cls.");
    Expect.equals(
        indirectlyInstantiated,
        node.isIndirectlyInstantiated,
        "Unexpected `isIndirectlyInstantiated` on ClassHierarchyNode for "
        "$cls.");
  }

  checkClass(A, directlyInstantiated: true, indirectlyInstantiated: true);
  checkClass(B, indirectlyInstantiated: true);
  checkClass(C, directlyInstantiated: true, indirectlyInstantiated: true);
  checkClass(D, directlyInstantiated: true);
  checkClass(E, directlyInstantiated: true);
  checkClass(F, directlyInstantiated: true);
  checkClass(G, directlyInstantiated: true);

  ClassHierarchyNodeIterator iterator;

  void checkState(ClassElement root,
      {ClassElement currentNode, List<ClassElement> stack}) {
    ClassElement classOf(ClassHierarchyNode node) {
      return node != null ? node.cls : null;
    }

    List<ClassElement> classesOf(Link<ClassHierarchyNode> link) {
      if (link == null) return null;
      return link.map(classOf).toList();
    }

    ClassElement foundRoot = iterator.root.cls;
    ClassElement foundCurrentNode = classOf(iterator.currentNode);
    List<ClassElement> foundStack = classesOf(iterator.stack);

    StringBuffer sb = new StringBuffer();
    sb.write('{\n root: $foundRoot');
    sb.write('\n currentNode: $foundCurrentNode');
    sb.write('\n stack: $foundStack\n}');

    Expect.equals(root, foundRoot, "Expected root $root in $sb.");
    if (currentNode == null) {
      Expect.isNull(
          iterator.currentNode, "Unexpected non-null currentNode in $sb.");
    } else {
      Expect.isNotNull(foundCurrentNode,
          "Expected non-null currentNode ${currentNode} in $sb.");
      Expect.equals(currentNode, foundCurrentNode,
          "Expected currentNode $currentNode in $sb.");
    }
    if (stack == null) {
      Expect.isNull(foundStack, "Unexpected non-null stack in $sb.");
    } else {
      Expect.isNotNull(foundStack, "Expected non-null stack ${stack} in $sb.");
      Expect.listEquals(
          stack,
          foundStack,
          "Expected stack ${stack}, "
          "found ${foundStack} in $sb.");
    }
  }

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(G), ClassHierarchyNode.ALL)
      .iterator;
  checkState(G, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(G, currentNode: G, stack: []);
  Expect.equals(G, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(G, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(G), ClassHierarchyNode.ALL,
          includeRoot: false)
      .iterator;
  checkState(G, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(G, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(C), ClassHierarchyNode.ALL)
      .iterator;
  checkState(C, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(C, currentNode: C, stack: [E, F, G]);
  Expect.equals(C, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(C, currentNode: E, stack: [F, G]);
  Expect.equals(E, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(C, currentNode: F, stack: [G]);
  Expect.equals(F, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(C, currentNode: G, stack: []);
  Expect.equals(G, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(C, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(D), ClassHierarchyNode.ALL)
      .iterator;
  checkState(D, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(D, currentNode: D, stack: []);
  Expect.equals(D, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(D, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(B), ClassHierarchyNode.ALL)
      .iterator;
  checkState(B, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(B, currentNode: B, stack: [D]);
  Expect.equals(B, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(B, currentNode: D, stack: []);
  Expect.equals(D, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(B, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(B), ClassHierarchyNode.ALL,
          includeRoot: false)
      .iterator;
  checkState(B, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(B, currentNode: D, stack: []);
  Expect.equals(D, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(B, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
      world.getClassHierarchyNode(B),
      new EnumSet<Instantiation>.fromValues(<Instantiation>[
        Instantiation.DIRECTLY_INSTANTIATED,
        Instantiation.UNINSTANTIATED
      ])).iterator;
  checkState(B, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(B, currentNode: D, stack: []);
  Expect.equals(D, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(B, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(A), ClassHierarchyNode.ALL)
      .iterator;
  checkState(A, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: A, stack: [C, B]);
  Expect.equals(A, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: C, stack: [E, F, G, B]);
  Expect.equals(C, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: E, stack: [F, G, B]);
  Expect.equals(E, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: F, stack: [G, B]);
  Expect.equals(F, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: G, stack: [B]);
  Expect.equals(G, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: B, stack: [D]);
  Expect.equals(B, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: D, stack: []);
  Expect.equals(D, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(A, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(A), ClassHierarchyNode.ALL,
          includeRoot: false)
      .iterator;
  checkState(A, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: C, stack: [E, F, G, B]);
  Expect.equals(C, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: E, stack: [F, G, B]);
  Expect.equals(E, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: F, stack: [G, B]);
  Expect.equals(F, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: G, stack: [B]);
  Expect.equals(G, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: B, stack: [D]);
  Expect.equals(B, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: D, stack: []);
  Expect.equals(D, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(A, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
      world.getClassHierarchyNode(A),
      new EnumSet<Instantiation>.fromValues(<Instantiation>[
        Instantiation.DIRECTLY_INSTANTIATED,
        Instantiation.UNINSTANTIATED
      ])).iterator;
  checkState(A, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: A, stack: [C, B]);
  Expect.equals(A, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: C, stack: [E, F, G, B]);
  Expect.equals(C, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: E, stack: [F, G, B]);
  Expect.equals(E, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: F, stack: [G, B]);
  Expect.equals(F, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: G, stack: [B]);
  Expect.equals(G, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: D, stack: []);
  Expect.equals(D, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(A, currentNode: null, stack: []);
  Expect.isNull(iterator.current);

  iterator = new ClassHierarchyNodeIterable(
          world.getClassHierarchyNode(A),
          new EnumSet<Instantiation>.fromValues(<Instantiation>[
            Instantiation.DIRECTLY_INSTANTIATED,
            Instantiation.UNINSTANTIATED
          ]),
          includeRoot: false)
      .iterator;
  checkState(A, currentNode: null, stack: null);
  Expect.isNull(iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: C, stack: [E, F, G, B]);
  Expect.equals(C, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: E, stack: [F, G, B]);
  Expect.equals(E, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: F, stack: [G, B]);
  Expect.equals(F, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: G, stack: [B]);
  Expect.equals(G, iterator.current);
  Expect.isTrue(iterator.moveNext());
  checkState(A, currentNode: D, stack: []);
  Expect.equals(D, iterator.current);
  Expect.isFalse(iterator.moveNext());
  checkState(A, currentNode: null, stack: []);
  Expect.isNull(iterator.current);
}

testForEach() async {
  var env = await TypeEnvironment.create(
      r"""
      ///        A
      ///       / \
      ///      B   C
      ///     /   /|\
      ///    D   E F G
      ///         / \
      ///         H I
      ///
      class A implements X {}
      class B extends A {}
      class C extends A {}
      class D extends B {}
      class E extends C {}
      class F extends C implements B {}
      class G extends C implements D {}
      class H extends F {}
      class I extends F {}
      class X {}
      """,
      mainSource: r"""
      main() {
        new A();
        new C();
        new D();
        new E();
        new F();
        new G();
        new H();
        new I();
      }
      """,
      useMockCompiler: false);
  ClosedWorld world = env.closedWorld;

  ClassElement A = env.getElement("A");
  ClassElement B = env.getElement("B");
  ClassElement C = env.getElement("C");
  ClassElement D = env.getElement("D");
  ClassElement E = env.getElement("E");
  ClassElement F = env.getElement("F");
  ClassElement G = env.getElement("G");
  ClassElement H = env.getElement("H");
  ClassElement I = env.getElement("I");
  ClassElement X = env.getElement("X");

  void checkForEachSubclass(ClassElement cls, List<ClassElement> expected) {
    ClassSet classSet = world.getClassSet(cls);
    List<ClassElement> visited = <ClassElement>[];
    classSet.forEachSubclass((cls) {
      visited.add(cls);
    }, ClassHierarchyNode.ALL);

    Expect.listEquals(
        expected,
        visited,
        "Unexpected classes on $cls.forEachSubclass:\n"
        "Actual: $visited, expected: $expected\n$classSet");

    visited = <ClassElement>[];
    classSet.forEachSubclass((cls) {
      visited.add(cls);
      return IterationStep.CONTINUE;
    }, ClassHierarchyNode.ALL);

    Expect.listEquals(
        expected,
        visited,
        "Unexpected classes on $cls.forEachSubclass:\n"
        "Actual: $visited, expected: $expected\n$classSet");
  }

  checkForEachSubclass(A, [A, B, D, C, G, F, I, H, E]);
  checkForEachSubclass(B, [B, D]);
  checkForEachSubclass(C, [C, G, F, I, H, E]);
  checkForEachSubclass(D, [D]);
  checkForEachSubclass(E, [E]);
  checkForEachSubclass(F, [F, I, H]);
  checkForEachSubclass(G, [G]);
  checkForEachSubclass(H, [H]);
  checkForEachSubclass(I, [I]);
  checkForEachSubclass(X, [X]);

  void checkForEachSubtype(ClassElement cls, List<ClassElement> expected) {
    ClassSet classSet = world.getClassSet(cls);
    List<ClassElement> visited = <ClassElement>[];
    classSet.forEachSubtype((cls) {
      visited.add(cls);
    }, ClassHierarchyNode.ALL);

    Expect.listEquals(
        expected,
        visited,
        "Unexpected classes on $cls.forEachSubtype:\n"
        "Actual: $visited, expected: $expected\n$classSet");

    visited = <ClassElement>[];
    classSet.forEachSubtype((cls) {
      visited.add(cls);
      return IterationStep.CONTINUE;
    }, ClassHierarchyNode.ALL);

    Expect.listEquals(
        expected,
        visited,
        "Unexpected classes on $cls.forEachSubtype:\n"
        "Actual: $visited, expected: $expected\n$classSet");
  }

  checkForEachSubtype(A, [A, B, D, C, G, F, I, H, E]);
  checkForEachSubtype(B, [B, D, F, I, H, G]);
  checkForEachSubtype(C, [C, G, F, I, H, E]);
  checkForEachSubtype(D, [D, G]);
  checkForEachSubtype(E, [E]);
  checkForEachSubtype(F, [F, I, H]);
  checkForEachSubtype(G, [G]);
  checkForEachSubtype(H, [H]);
  checkForEachSubtype(I, [I]);
  checkForEachSubtype(X, [X, A, B, D, C, G, F, I, H, E]);

  void checkForEach(ClassElement cls, List<ClassElement> expected,
      {ClassElement stop,
      List<ClassElement> skipSubclasses: const <ClassElement>[],
      bool forEachSubtype: false,
      EnumSet<Instantiation> mask}) {
    if (mask == null) {
      mask = ClassHierarchyNode.ALL;
    }

    ClassSet classSet = world.getClassSet(cls);
    List<ClassElement> visited = <ClassElement>[];

    IterationStep visit(_cls) {
      ClassElement cls = _cls;
      visited.add(cls);
      if (cls == stop) {
        return IterationStep.STOP;
      } else if (skipSubclasses.contains(cls)) {
        return IterationStep.SKIP_SUBCLASSES;
      }
      return IterationStep.CONTINUE;
    }

    if (forEachSubtype) {
      classSet.forEachSubtype(visit, mask);
    } else {
      classSet.forEachSubclass(visit, mask);
    }

    Expect.listEquals(
        expected,
        visited,
        "Unexpected classes on $cls."
        "forEach${forEachSubtype ? 'Subtype' : 'Subclass'} "
        "(stop:$stop, skipSubclasses:$skipSubclasses):\n"
        "Actual: $visited, expected: $expected\n$classSet");
  }

  checkForEach(A, [A, B, D, C, G, F, I, H, E]);
  checkForEach(A, [A], stop: A);
  checkForEach(A, [A, B, C, G, F, I, H, E], skipSubclasses: [B]);
  checkForEach(A, [A, B, C], skipSubclasses: [B, C]);
  checkForEach(A, [A, B, C, G], stop: G, skipSubclasses: [B]);

  checkForEach(B, [B, D, F, I, H, G], forEachSubtype: true);
  checkForEach(B, [B, D], stop: D, forEachSubtype: true);
  checkForEach(B, [B, D, F, G], skipSubclasses: [F], forEachSubtype: true);
  checkForEach(B, [B, F, I, H, G], skipSubclasses: [B], forEachSubtype: true);
  checkForEach(B, [B, D, F, I, H, G],
      skipSubclasses: [D], forEachSubtype: true);

  checkForEach(X, [X, A, B, D, C, G, F, I, H, E], forEachSubtype: true);
  checkForEach(X, [X, A, B, D], stop: D, forEachSubtype: true);
  checkForEach(X, [X, A, B, D, C, G, F, E],
      skipSubclasses: [F], forEachSubtype: true);
  checkForEach(X, [X, A, B, D, C, G, F, I, H, E],
      skipSubclasses: [X], forEachSubtype: true);
  checkForEach(X, [X, A, B, D, C, G, F, I, H, E],
      skipSubclasses: [D], forEachSubtype: true);
  checkForEach(X, [A, D, C, G, F, I, H, E],
      forEachSubtype: true, mask: ClassHierarchyNode.EXPLICITLY_INSTANTIATED);
  checkForEach(X, [A, B, D, C, G, F, I, H, E],
      forEachSubtype: true, mask: ClassHierarchyNode.INSTANTIATED);

  void checkAny(ClassElement cls, List<ClassElement> expected,
      {ClassElement find, bool expectedResult, bool anySubtype: false}) {
    ClassSet classSet = world.getClassSet(cls);
    List<ClassElement> visited = <ClassElement>[];

    bool visit(cls) {
      visited.add(cls);
      return cls == find;
    }

    bool result;
    if (anySubtype) {
      result = classSet.anySubtype(visit, ClassHierarchyNode.ALL);
    } else {
      result = classSet.anySubclass(visit, ClassHierarchyNode.ALL);
    }

    Expect.equals(
        expectedResult,
        result,
        "Unexpected result on $cls."
        "any${anySubtype ? 'Subtype' : 'Subclass'} "
        "(find:$find).");

    Expect.listEquals(
        expected,
        visited,
        "Unexpected classes on $cls."
        "any${anySubtype ? 'Subtype' : 'Subclass'} "
        "(find:$find):\n"
        "Actual: $visited, expected: $expected\n$classSet");
  }

  checkAny(A, [A, B, D, C, G, F, I, H, E], expectedResult: false);
  checkAny(A, [A], find: A, expectedResult: true);
  checkAny(A, [A, B, D, C, G, F, I], find: I, expectedResult: true);

  checkAny(B, [B, D, F, I, H, G], anySubtype: true, expectedResult: false);
  checkAny(B, [B, D, F, I, H, G],
      find: A, anySubtype: true, expectedResult: false);
  checkAny(B, [B, D], find: D, anySubtype: true, expectedResult: true);
  checkAny(B, [B, D, F, I], find: I, anySubtype: true, expectedResult: true);

  checkAny(X, [X, A, B, D, C, G, F, I, H, E],
      anySubtype: true, expectedResult: false);
  checkAny(X, [X, A], find: A, anySubtype: true, expectedResult: true);
  checkAny(X, [X, A, B, D], find: D, anySubtype: true, expectedResult: true);
  checkAny(X, [X, A, B, D, C, G, F, I],
      find: I, anySubtype: true, expectedResult: true);
}
