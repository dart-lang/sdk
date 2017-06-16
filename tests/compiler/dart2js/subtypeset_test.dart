// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for iterators on for [SubclassNode].

library subtypeset_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/elements/elements.dart' show ClassElement;
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/world.dart';

void main() {
  asyncTest(() => TypeEnvironment
          .create(
              r"""
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
      class H implements C {}
      class I implements H {}
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
              useMockCompiler: false)
          .then((env) {
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

        void checkClass(ClassElement cls, List<ClassElement> subtypes) {
          ClassSet node = world.getClassSet(cls);
          print('$cls:\n${node}');
          Expect.listEquals(
              subtypes,
              node.subtypes().toList(),
              "Unexpected subtypes of ${cls.name}:\n"
              "Expected: $subtypes\n"
              "Found   : ${node.subtypes().toList()}");
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
      }));
}
