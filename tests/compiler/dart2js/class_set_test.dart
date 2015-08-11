// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for iterators on for [SubclassNode].

library world_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/elements/elements.dart'
       show Element, ClassElement;
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/util/util.dart';
import 'package:compiler/src/world.dart';

void main() {
  asyncTest(() => TypeEnvironment.create(r"""
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
      useMockCompiler: false).then((env) {
    World world = env.compiler.world;

    ClassElement A = env.getElement("A");
    ClassElement B = env.getElement("B");
    ClassElement C = env.getElement("C");
    ClassElement D = env.getElement("D");
    ClassElement E = env.getElement("E");
    ClassElement F = env.getElement("F");
    ClassElement G = env.getElement("G");

    void checkClass(ClassElement cls,
                    {bool directlyInstantiated: false,
                     bool indirectlyInstantiated: false}) {
      ClassHierarchyNode node = world.classHierarchyNode(cls);
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

    void checkState(
        ClassElement root,
        {ClassElement currentNode,
         List<List<ClassElement>> stack}) {

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

      Expect.equals(root, foundRoot,
          "Expected root $root in $sb.");
      if (currentNode == null) {
        Expect.isNull(iterator.currentNode,
            "Unexpected non-null currentNode in $sb.");
      } else {
        Expect.isNotNull(foundCurrentNode,
            "Expected non-null currentNode ${currentNode} in $sb.");
        Expect.equals(currentNode, foundCurrentNode,
            "Expected currentNode $currentNode in $sb.");
      }
      if (stack == null) {
        Expect.isNull(foundStack,
            "Unexpected non-null stack in $sb.");
      } else {
        Expect.isNotNull(foundStack,
            "Expected non-null stack ${stack} in $sb.");
        Expect.listEquals(stack, foundStack,
            "Expected stack ${stack}, "
            "found ${foundStack} in $sb.");
      }
    }

    iterator = new ClassHierarchyNodeIterable(
        world.classHierarchyNode(G)).iterator;
    checkState(G, currentNode: null, stack: null);
    Expect.isNull(iterator.current);
    Expect.isTrue(iterator.moveNext());
    checkState(G, currentNode: G, stack: []);
    Expect.equals(G, iterator.current);
    Expect.isFalse(iterator.moveNext());
    checkState(G, currentNode: null, stack: []);
    Expect.isNull(iterator.current);

    iterator = new ClassHierarchyNodeIterable(
        world.classHierarchyNode(G), includeRoot: false).iterator;
    checkState(G, currentNode: null, stack: null);
    Expect.isNull(iterator.current);
    Expect.isFalse(iterator.moveNext());
    checkState(G, currentNode: null, stack: []);
    Expect.isNull(iterator.current);

    iterator = new ClassHierarchyNodeIterable(
        world.classHierarchyNode(C)).iterator;
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
        world.classHierarchyNode(D)).iterator;
    checkState(D, currentNode: null, stack: null);
    Expect.isNull(iterator.current);
    Expect.isTrue(iterator.moveNext());
    checkState(D, currentNode: D, stack: []);
    Expect.equals(D, iterator.current);
    Expect.isFalse(iterator.moveNext());
    checkState(D, currentNode: null, stack: []);
    Expect.isNull(iterator.current);

    iterator = new ClassHierarchyNodeIterable(
        world.classHierarchyNode(B)).iterator;
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
        world.classHierarchyNode(B), includeRoot: false).iterator;
    checkState(B, currentNode: null, stack: null);
    Expect.isNull(iterator.current);
    Expect.isTrue(iterator.moveNext());
    checkState(B, currentNode: D, stack: []);
    Expect.equals(D, iterator.current);
    Expect.isFalse(iterator.moveNext());
    checkState(B, currentNode: null, stack: []);
    Expect.isNull(iterator.current);

    iterator = new ClassHierarchyNodeIterable(
        world.classHierarchyNode(B), directlyInstantiatedOnly: true).iterator;
    checkState(B, currentNode: null, stack: null);
    Expect.isNull(iterator.current);
    Expect.isTrue(iterator.moveNext());
    checkState(B, currentNode: D, stack: []);
    Expect.equals(D, iterator.current);
    Expect.isFalse(iterator.moveNext());
    checkState(B, currentNode: null, stack: []);
    Expect.isNull(iterator.current);

    iterator = new ClassHierarchyNodeIterable(
        world.classHierarchyNode(A)).iterator;
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
        world.classHierarchyNode(A), includeRoot: false).iterator;
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
        world.classHierarchyNode(A), directlyInstantiatedOnly: true).iterator;
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
        world.classHierarchyNode(A),
        includeRoot: false, directlyInstantiatedOnly: true).iterator;
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
  }));
}
