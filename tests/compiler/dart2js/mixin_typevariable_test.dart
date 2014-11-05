// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mixin_typevariable_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'type_test_helper.dart';
import 'package:compiler/src/dart_types.dart';
import "package:compiler/src/elements/elements.dart"
       show Element, ClassElement;

void main() {
  testMixinSupertypes();
  testNonTrivialSubstitutions();
}

void testMixinSupertypes() {
  asyncTest(() => TypeEnvironment.create(r"""
      class S<S_T> {}
      class M1<M1_T> {}
      class M2<M2_T> {}
      class M3<M3_T> {}

      class C1<C1_T> extends S<C1_T> with M1<C1_T>, M2<C1_T>, M3<C1_T> {}
      class C2<C2_T> = S<C2_T> with M1<C2_T>, M2<C2_T>, M3<C2_T>;
      """, expectNoWarningsOrErrors: true).then((env) {

    ClassElement Object = env.getElement('Object');
    ClassElement S = env.getElement('S');
    ClassElement M1 = env.getElement('M1');
    ClassElement M2 = env.getElement('M2');
    ClassElement M3 = env.getElement('M3');
    ClassElement C1 = env.getElement('C1');
    ClassElement C2 = env.getElement('C2');

    ClassElement C1_S_M1_M2_M3 = C1.superclass;
    ClassElement C1_S_M1_M2 = C1_S_M1_M2_M3.superclass;
    ClassElement C1_S_M1 = C1_S_M1_M2.superclass;

    ClassElement C2_S_M1_M2 = C2.superclass;
    ClassElement C2_S_M1 = C2_S_M1_M2.superclass;

    void testSupertypes(ClassElement element) {
      if (element != Object) {
        Expect.isTrue(element.typeVariables.length == 1);
        Expect.equals(element,
                      element.typeVariables.first.element.enclosingElement);
      }
      for (InterfaceType supertype in element.allSupertypesAndSelf.types) {
        if (!supertype.typeArguments.isEmpty) {
          Expect.listEquals(element.typeVariables, supertype.typeArguments,
              "Type argument mismatch on supertype $supertype of $element.");
        } else {
          Expect.equals(Object, supertype.element);
        }
      }
    }

    testSupertypes(Object);
    testSupertypes(S);
    testSupertypes(M1);
    testSupertypes(M2);
    testSupertypes(C1_S_M1);
    testSupertypes(C1_S_M1_M2);
    testSupertypes(C1_S_M1_M2_M3);
    testSupertypes(C1);
    testSupertypes(C2_S_M1);
    testSupertypes(C2_S_M1_M2);
    testSupertypes(C2);
  }));
}

void testNonTrivialSubstitutions() {
  asyncTest(() => TypeEnvironment.create(r"""
      class _ {}
      class A<A_T> {}
      class B<B_T, B_S> {}

      class C1<C1_T> extends A with B {}
      class C2<C2_T> = A with B;

      class D1<D1_T> extends A<D1_T> with B<D1_T, A<D1_T>> {}
      class D2<D2_T> = A<D2_T> with B<D2_T, A<D2_T>>;

      class E1<E1_T> extends A<_> with B<_, A<_>> {}
      class E2<E2_T> = A<_> with B<_, A<_>>;

      class F1<F1_T> extends A<_> with B<_, B<F1_T, _>> {}
      class F2<F2_T> = A<_> with B<_, B<F2_T, _>>;
      """, expectNoWarningsOrErrors: true).then((env) {
    DartType _dynamic = env['dynamic'];
    DartType _ = env['_'];

    ClassElement Object = env.getElement('Object');
    ClassElement A = env.getElement('A');
    ClassElement B = env.getElement('B');
    ClassElement C1 = env.getElement('C1');
    ClassElement C2 = env.getElement('C2');
    ClassElement D1 = env.getElement('D1');
    ClassElement D2 = env.getElement('D2');
    ClassElement E1 = env.getElement('E1');
    ClassElement E2 = env.getElement('E2');
    ClassElement F1 = env.getElement('F1');
    ClassElement F2 = env.getElement('F2');

    ClassElement C1_A_B = C1.superclass;
    ClassElement D1_A_B = D1.superclass;
    ClassElement E1_A_B = E1.superclass;
    ClassElement F1_A_B = F1.superclass;

    void testSupertypes(ClassElement element,
                        Map<ClassElement, List<DartType>> typeArguments) {
      if (element != Object) {
        Expect.isTrue(element.typeVariables.length == 1);
        Expect.equals(element,
                      element.typeVariables.first.element.enclosingElement);
      }
      for (InterfaceType supertype in element.allSupertypesAndSelf.types) {
        if (typeArguments.containsKey(supertype.element)) {
          Expect.listEquals(typeArguments[supertype.element],
                            supertype.typeArguments,
              "Type argument mismatch on supertype $supertype of $element.");
        } else if (!supertype.typeArguments.isEmpty) {
          Expect.listEquals(element.typeVariables, supertype.typeArguments,
              "Type argument mismatch on supertype $supertype of $element.");
        } else {
          Expect.equals(Object, supertype.element);
        }
      }
    }

    testSupertypes(C1, {A: [_dynamic], B: [_dynamic, _dynamic]});
    testSupertypes(C1.superclass, {A: [_dynamic], B: [_dynamic, _dynamic]});
    testSupertypes(C2, {A: [_dynamic], B: [_dynamic, _dynamic]});

    DartType D1_T = D1.typeVariables.first;
    testSupertypes(D1, {A: [D1_T], B: [D1_T, instantiate(A, [D1_T])]});
    DartType D1_superclass_T = D1.superclass.typeVariables.first;
    testSupertypes(D1.superclass,
        {A: [D1_superclass_T],
         B: [D1_superclass_T, instantiate(A, [D1_superclass_T])]});
    DartType D2_T = D2.typeVariables.first;
    testSupertypes(D2, {A: [D2_T], B: [D2_T, instantiate(A, [D2_T])]});

    testSupertypes(E1, {A: [_], B: [_, instantiate(A, [_])]});
    testSupertypes(E1.superclass, {A: [_], B: [_, instantiate(A, [_])]});
    testSupertypes(E2, {A: [_], B: [_, instantiate(A, [_])]});

    DartType F1_T = F1.typeVariables.first;
    testSupertypes(F1, {A: [_], B: [_, instantiate(B, [F1_T, _])]});
    DartType F1_superclass_T = F1.superclass.typeVariables.first;
    testSupertypes(F1.superclass, {A: [_], B: [_, instantiate(B, [F1_superclass_T, _])]});
    DartType F2_T = F2.typeVariables.first;
    testSupertypes(F2, {A: [_], B: [_, instantiate(B, [F2_T, _])]});
  }));
}
