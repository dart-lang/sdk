// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/implementation/dart_types.dart';
import "package:compiler/implementation/elements/elements.dart"
       show Element, ClassElement;
import 'package:compiler/implementation/util/util.dart'
       show Link;

void main() {
  testInterface1();
  testInterface2();
  testGeneric();
  testMixin();
  testFunction();
  testTypeVariable();
}

void testInterface1() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A {} // A and B have equal depth.
      class B {}
      class I implements A, B {}
      class J implements A, B {}
      """).then((env) {

    DartType Object_ = env['Object'];
    DartType A = env['A'];
    DartType B = env['B'];
    DartType I = env['I'];
    DartType J = env['J'];

    checkLub(DartType a, DartType b, DartType expect) {
      DartType lub = env.computeLeastUpperBound(a, b);
      Expect.equals(expect, lub,
          'Unexpected lub($a,$b) = $lub, expected $expect.');
    }

    checkLub(Object_, Object_, Object_);
    checkLub(Object_, A, Object_);
    checkLub(Object_, B, Object_);
    checkLub(Object_, I, Object_);
    checkLub(Object_, J, Object_);

    checkLub(A, Object_, Object_);
    checkLub(A, A, A);
    checkLub(A, B, Object_);
    checkLub(A, I, A);
    checkLub(A, J, A);

    checkLub(B, Object_, Object_);
    checkLub(B, A, Object_);
    checkLub(B, B, B);
    checkLub(B, I, B);
    checkLub(B, J, B);

    checkLub(I, Object_, Object_);
    checkLub(I, A, A);
    checkLub(I, B, B);
    checkLub(I, I, I);
    checkLub(I, J, Object_);

    checkLub(J, Object_, Object_);
    checkLub(J, A, A);
    checkLub(J, B, B);
    checkLub(J, I, Object_);
    checkLub(J, J, J);
  }));
}

void testInterface2() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends B {} // This makes C have higher depth than A.
      class I implements A, C {}
      class J implements A, C {}
      """).then((env) {

    DartType Object_ = env['Object'];
    DartType A = env['A'];
    DartType B = env['B'];
    DartType C = env['C'];
    DartType I = env['I'];
    DartType J = env['J'];

    checkLub(DartType a, DartType b, DartType expectedLub) {
      DartType lub = env.computeLeastUpperBound(a, b);
      Expect.equals(expectedLub, lub,
          'Unexpected lub($a,$b) = $lub, expected $expectedLub');
    }

    checkLub(Object_, Object_, Object_);
    checkLub(Object_, A, Object_);
    checkLub(Object_, B, Object_);
    checkLub(Object_, C, Object_);
    checkLub(Object_, I, Object_);
    checkLub(Object_, J, Object_);

    checkLub(A, Object_, Object_);
    checkLub(A, A, A);
    checkLub(A, B, Object_);
    checkLub(A, C, Object_);
    checkLub(A, I, A);
    checkLub(A, J, A);

    checkLub(B, Object_, Object_);
    checkLub(B, A, Object_);
    checkLub(B, B, B);
    checkLub(B, C, B);
    checkLub(B, I, B);
    checkLub(B, J, B);

    checkLub(C, Object_, Object_);
    checkLub(C, A, Object_);
    checkLub(C, B, B);
    checkLub(C, C, C);
    checkLub(C, I, C);
    checkLub(C, J, C);

    checkLub(I, Object_, Object_);
    checkLub(I, A, A);
    checkLub(I, B, B);
    checkLub(I, C, C);
    checkLub(I, I, I);
    checkLub(I, J, C);

    checkLub(J, Object_, Object_);
    checkLub(J, A, A);
    checkLub(J, B, B);
    checkLub(J, C, C);
    checkLub(J, I, C);
    checkLub(J, J, J);
  }));
}

void testGeneric() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends B {}
      class I<T> {}
      """).then((env) {

    DartType Object_ = env['Object'];
    DartType A = env['A'];
    DartType B = env['B'];
    DartType C = env['C'];
    ClassElement I = env.getElement('I');
    DartType I_A = instantiate(I, [A]);
    DartType I_B = instantiate(I, [B]);
    DartType I_C = instantiate(I, [C]);

    checkLub(DartType a, DartType b, DartType expectedLub) {
      DartType lub = env.computeLeastUpperBound(a, b);
      Expect.equals(expectedLub, lub,
          'Unexpected lub($a,$b) = $lub, expected $expectedLub');
    }

    checkLub(Object_, Object_, Object_);
    checkLub(Object_, A, Object_);
    checkLub(Object_, B, Object_);
    checkLub(Object_, C, Object_);
    checkLub(Object_, I_A, Object_);
    checkLub(Object_, I_B, Object_);
    checkLub(Object_, I_C, Object_);

    checkLub(A, Object_, Object_);
    checkLub(A, A, A);
    checkLub(A, B, Object_);
    checkLub(A, C, Object_);
    checkLub(A, I_A, Object_);
    checkLub(A, I_B, Object_);
    checkLub(A, I_C, Object_);

    checkLub(B, Object_, Object_);
    checkLub(B, A, Object_);
    checkLub(B, B, B);
    checkLub(B, C, B);
    checkLub(B, I_A, Object_);
    checkLub(B, I_B, Object_);
    checkLub(B, I_C, Object_);

    checkLub(C, Object_, Object_);
    checkLub(C, A, Object_);
    checkLub(C, B, B);
    checkLub(C, C, C);
    checkLub(C, I_A, Object_);
    checkLub(C, I_B, Object_);
    checkLub(C, I_C, Object_);

    checkLub(I_A, Object_, Object_);
    checkLub(I_A, A, Object_);
    checkLub(I_A, B, Object_);
    checkLub(I_A, C, Object_);
    checkLub(I_A, I_A, I_A);
    checkLub(I_A, I_B, Object_);
    checkLub(I_A, I_C, Object_);

    checkLub(I_B, Object_, Object_);
    checkLub(I_B, A, Object_);
    checkLub(I_B, B, Object_);
    checkLub(I_B, C, Object_);
    checkLub(I_B, I_A, Object_);
    checkLub(I_B, I_B, I_B);
    checkLub(I_B, I_C, Object_);

    checkLub(I_C, Object_, Object_);
    checkLub(I_C, A, Object_);
    checkLub(I_C, B, Object_);
    checkLub(I_C, C, Object_);
    checkLub(I_C, I_A, Object_);
    checkLub(I_C, I_B, Object_);
    checkLub(I_C, I_C, I_C);
  }));
}

void testMixin() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends B {}
      class D extends C {} // This makes D have higher depth than Object+A.
      class I extends Object with A, B implements A, D {}
      class I2 extends Object with A, B implements A, D {}
      class J extends Object with B, A implements A, D {}
      """).then((env) {

    DartType Object_ = env['Object'];
    DartType A = env['A'];
    DartType B = env['B'];
    DartType C = env['C'];
    DartType D = env['D'];
    DartType I = env['I'];
    DartType I2 = env['I2'];
    DartType J = env['J'];

    checkLub(DartType a, DartType b, DartType expectedLub) {
      DartType lub = env.computeLeastUpperBound(a, b);
      Expect.equals(expectedLub, lub,
          'Unexpected lub($a,$b) = $lub, expected $expectedLub');
    }

    checkLub(Object_, Object_, Object_);
    checkLub(Object_, A, Object_);
    checkLub(Object_, B, Object_);
    checkLub(Object_, C, Object_);
    checkLub(Object_, D, Object_);
    checkLub(Object_, I, Object_);
    checkLub(Object_, I2, Object_);
    checkLub(Object_, J, Object_);

    checkLub(A, Object_, Object_);
    checkLub(A, A, A);
    checkLub(A, B, Object_);
    checkLub(A, C, Object_);
    checkLub(A, D, Object_);
    checkLub(A, I, A);
    checkLub(A, I2, A);
    checkLub(A, J, A);

    checkLub(B, Object_, Object_);
    checkLub(B, A, Object_);
    checkLub(B, B, B);
    checkLub(B, C, B);
    checkLub(B, D, B);
    checkLub(B, I, B);
    checkLub(B, I2, B);
    checkLub(B, J, B);

    checkLub(C, Object_, Object_);
    checkLub(C, A, Object_);
    checkLub(C, B, B);
    checkLub(C, C, C);
    checkLub(C, D, C);
    checkLub(C, I, C);
    checkLub(C, I2, C);
    checkLub(C, J, C);

    checkLub(D, Object_, Object_);
    checkLub(D, A, Object_);
    checkLub(D, B, B);
    checkLub(D, C, C);
    checkLub(D, D, D);
    checkLub(D, I, D);
    checkLub(D, I2, D);
    checkLub(D, J, D);

    checkLub(I, Object_, Object_);
    checkLub(I, A, A);
    checkLub(I, B, B);
    checkLub(I, C, C);
    checkLub(I, D, D);
    checkLub(I, I, I);
    checkLub(I, I2, D);
    checkLub(I, J, D);

    checkLub(I2, Object_, Object_);
    checkLub(I2, A, A);
    checkLub(I2, B, B);
    checkLub(I2, C, C);
    checkLub(I2, D, D);
    checkLub(I2, I, D);
    checkLub(I2, I2, I2);
    checkLub(I2, J, D);

    checkLub(J, Object_, Object_);
    checkLub(J, A, A);
    checkLub(J, B, B);
    checkLub(J, C, C);
    checkLub(J, D, D);
    checkLub(J, I, D);
    checkLub(J, I2, D);
    checkLub(J, J, J);
  }));
}

void testFunction() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends B {}

      typedef dynamic__();
      typedef void void__();
      typedef A A__();
      typedef B B__();
      typedef C C__();

      typedef void void__A_B(A a, B b);
      typedef void void__A_C(A a, C b);
      typedef void void__B_A(B a, A b);
      typedef void void__B_C(B a, C b);

      typedef void void___B([B a]);
      typedef void void___B_C([B a, C b]);
      typedef void void___C_C([C a, C b]);

      typedef void void____B({B a});
      typedef void void____B_C({B a, C b});
      typedef void void____C_C({C a, C b});
      """).then((env) {

    DartType Object_ = env['Object'];
    DartType Function_ = env['Function'];
    DartType dynamic__ = env['dynamic__'];
    DartType void__ = env['void__'];
    DartType A__ = env['A__'];
    DartType B__ = env['B__'];
    DartType C__ = env['C__'];
    DartType void__A_B = env['void__A_B'];
    DartType void__A_C = env['void__A_C'];
    DartType void__B_A = env['void__B_A'];
    DartType void__B_C = env['void__B_C'];
    DartType void___B = env['void___B'];
    DartType void___B_C = env['void___B_C'];
    DartType void___C_C = env['void___C_C'];
    DartType void____B = env['void____B'];
    DartType void____B_C = env['void____B_C'];
    DartType void____C_C = env['void____C_C'];

    // Types used only for checking results.
    DartType void_ = env['void'];
    DartType B = env['B'];
    DartType C = env['C'];
    FunctionType Object__ = env.functionType(Object_, []);
    FunctionType void__Object_Object =
        env.functionType(void_, [Object_, Object_]);
    FunctionType void__Object_B =
        env.functionType(void_, [Object_, B]);
    FunctionType void__Object_C =
        env.functionType(void_, [Object_, C]);
    FunctionType void__B_Object =
        env.functionType(void_, [B, Object_]);

    checkLub(DartType a, DartType b, DartType expectedLub) {
      DartType lub = env.computeLeastUpperBound(a, b);
      if (a != b) {
        expectedLub = expectedLub.unalias(env.compiler);
        lub = lub.unalias(env.compiler);
      }
      Expect.equals(expectedLub, lub,
          'Unexpected lub(${a.unalias(env.compiler)},'
                         '${b.unalias(env.compiler)}) = '
                         '${lub}, expected ${expectedLub}');
    }

    checkLub(Object_, Object_, Object_);
    checkLub(Object_, Function_, Object_);
    checkLub(Object_, dynamic__, Object_);
    checkLub(Object_, void__, Object_);
    checkLub(Object_, A__, Object_);
    checkLub(Object_, B__, Object_);
    checkLub(Object_, C__, Object_);
    checkLub(Object_, void__A_B, Object_);
    checkLub(Object_, void__A_C, Object_);
    checkLub(Object_, void__B_A, Object_);
    checkLub(Object_, void__B_C, Object_);
    checkLub(Object_, void___B, Object_);
    checkLub(Object_, void___B_C, Object_);
    checkLub(Object_, void___C_C, Object_);
    checkLub(Object_, void____B, Object_);
    checkLub(Object_, void____B_C, Object_);
    checkLub(Object_, void____C_C, Object_);

    checkLub(Function_, Object_, Object_);
    checkLub(Function_, Function_, Function_);
    checkLub(Function_, dynamic__, Function_);
    checkLub(Function_, void__, Function_);
    checkLub(Function_, A__, Function_);
    checkLub(Function_, B__, Function_);
    checkLub(Function_, C__, Function_);
    checkLub(Function_, void__A_B, Function_);
    checkLub(Function_, void__A_C, Function_);
    checkLub(Function_, void__B_A, Function_);
    checkLub(Function_, void__B_C, Function_);
    checkLub(Function_, void___B, Function_);
    checkLub(Function_, void___B_C, Function_);
    checkLub(Function_, void___C_C, Function_);
    checkLub(Function_, void____B, Function_);
    checkLub(Function_, void____B_C, Function_);
    checkLub(Function_, void____C_C, Function_);

    checkLub(dynamic__, Object_, Object_);
    checkLub(dynamic__, Function_, Function_);
    checkLub(dynamic__, dynamic__, dynamic__);
    checkLub(dynamic__, void__, dynamic__);
    checkLub(dynamic__, A__, dynamic__);
    checkLub(dynamic__, B__, dynamic__);
    checkLub(dynamic__, C__, dynamic__);
    checkLub(dynamic__, void__A_B, Function_);
    checkLub(dynamic__, void__A_C, Function_);
    checkLub(dynamic__, void__B_A, Function_);
    checkLub(dynamic__, void__B_C, Function_);
    checkLub(dynamic__, void___B, dynamic__);
    checkLub(dynamic__, void___B_C, dynamic__);
    checkLub(dynamic__, void___C_C, dynamic__);
    checkLub(dynamic__, void____B, dynamic__);
    checkLub(dynamic__, void____B_C, dynamic__);
    checkLub(dynamic__, void____C_C, dynamic__);

    checkLub(void__, Object_, Object_);
    checkLub(void__, Function_, Function_);
    checkLub(void__, dynamic__, dynamic__);
    checkLub(void__, void__, void__);
    checkLub(void__, A__, void__);
    checkLub(void__, B__, void__);
    checkLub(void__, C__, void__);
    checkLub(void__, void__A_B, Function_);
    checkLub(void__, void__A_C, Function_);
    checkLub(void__, void__B_A, Function_);
    checkLub(void__, void__B_C, Function_);
    checkLub(void__, void___B, void__);
    checkLub(void__, void___B_C, void__);
    checkLub(void__, void___C_C, void__);
    checkLub(void__, void____B, void__);
    checkLub(void__, void____B_C, void__);
    checkLub(void__, void____C_C, void__);

    checkLub(A__, Object_, Object_);
    checkLub(A__, Function_, Function_);
    checkLub(A__, dynamic__, dynamic__);
    checkLub(A__, void__, void__);
    checkLub(A__, A__, A__);
    checkLub(A__, B__, Object__);
    checkLub(A__, C__, Object__);
    checkLub(A__, void__A_B, Function_);
    checkLub(A__, void__A_C, Function_);
    checkLub(A__, void__B_A, Function_);
    checkLub(A__, void__B_C, Function_);
    checkLub(A__, void___B, void__);
    checkLub(A__, void___B_C, void__);
    checkLub(A__, void___C_C, void__);
    checkLub(A__, void____B, void__);
    checkLub(A__, void____B_C, void__);
    checkLub(A__, void____C_C, void__);

    checkLub(B__, Object_, Object_);
    checkLub(B__, Function_, Function_);
    checkLub(B__, dynamic__, dynamic__);
    checkLub(B__, void__, void__);
    checkLub(B__, A__, Object__);
    checkLub(B__, B__, B__);
    checkLub(B__, C__, B__);
    checkLub(B__, void__A_B, Function_);
    checkLub(B__, void__A_C, Function_);
    checkLub(B__, void__B_A, Function_);
    checkLub(B__, void__B_C, Function_);
    checkLub(B__, void___B, void__);
    checkLub(B__, void___B_C, void__);
    checkLub(B__, void___C_C, void__);
    checkLub(B__, void____B, void__);
    checkLub(B__, void____B_C, void__);
    checkLub(B__, void____C_C, void__);

    checkLub(C__, Object_, Object_);
    checkLub(C__, Function_, Function_);
    checkLub(C__, dynamic__, dynamic__);
    checkLub(C__, void__, void__);
    checkLub(C__, A__, Object__);
    checkLub(C__, B__, B__);
    checkLub(C__, C__, C__);
    checkLub(C__, void__A_B, Function_);
    checkLub(C__, void__A_C, Function_);
    checkLub(C__, void__B_A, Function_);
    checkLub(C__, void__B_C, Function_);
    checkLub(C__, void___B, void__);
    checkLub(C__, void___B_C, void__);
    checkLub(C__, void___C_C, void__);
    checkLub(C__, void____B, void__);
    checkLub(C__, void____B_C, void__);
    checkLub(C__, void____C_C, void__);

    checkLub(void__A_B, Object_, Object_);
    checkLub(void__A_B, Function_, Function_);
    checkLub(void__A_B, dynamic__, Function_);
    checkLub(void__A_B, void__, Function_);
    checkLub(void__A_B, A__, Function_);
    checkLub(void__A_B, B__, Function_);
    checkLub(void__A_B, C__, Function_);
    checkLub(void__A_B, void__A_B, void__A_B);
    checkLub(void__A_B, void__A_C, void__A_B);
    checkLub(void__A_B, void__B_A, void__Object_Object);
    checkLub(void__A_B, void__B_C, void__Object_B);
    checkLub(void__A_B, void___B, Function_);
    checkLub(void__A_B, void___B_C, Function_);
    checkLub(void__A_B, void___C_C, Function_);
    checkLub(void__A_B, void____B, Function_);
    checkLub(void__A_B, void____B_C, Function_);
    checkLub(void__A_B, void____C_C, Function_);

    checkLub(void__A_C, Object_, Object_);
    checkLub(void__A_C, Function_, Function_);
    checkLub(void__A_C, dynamic__, Function_);
    checkLub(void__A_C, void__, Function_);
    checkLub(void__A_C, A__, Function_);
    checkLub(void__A_C, B__, Function_);
    checkLub(void__A_C, C__, Function_);
    checkLub(void__A_C, void__A_B, void__A_B);
    checkLub(void__A_C, void__A_C, void__A_C);
    checkLub(void__A_C, void__B_A, void__Object_Object);
    checkLub(void__A_C, void__B_C, void__Object_C);
    checkLub(void__A_C, void___B, Function_);
    checkLub(void__A_C, void___B_C, Function_);
    checkLub(void__A_C, void___C_C, Function_);
    checkLub(void__A_C, void____B, Function_);
    checkLub(void__A_C, void____B_C, Function_);
    checkLub(void__A_C, void____C_C, Function_);

    checkLub(void__B_A, Object_, Object_);
    checkLub(void__B_A, Function_, Function_);
    checkLub(void__B_A, dynamic__, Function_);
    checkLub(void__B_A, void__, Function_);
    checkLub(void__B_A, A__, Function_);
    checkLub(void__B_A, B__, Function_);
    checkLub(void__B_A, C__, Function_);
    checkLub(void__B_A, void__A_B, void__Object_Object);
    checkLub(void__B_A, void__A_C, void__Object_Object);
    checkLub(void__B_A, void__B_A, void__B_A);
    checkLub(void__B_A, void__B_C, void__B_Object);
    checkLub(void__B_A, void___B, Function_);
    checkLub(void__B_A, void___B_C, Function_);
    checkLub(void__B_A, void___C_C, Function_);
    checkLub(void__B_A, void____B, Function_);
    checkLub(void__B_A, void____B_C, Function_);
    checkLub(void__B_A, void____C_C, Function_);

    checkLub(void__B_C, Object_, Object_);
    checkLub(void__B_C, Function_, Function_);
    checkLub(void__B_C, dynamic__, Function_);
    checkLub(void__B_C, void__, Function_);
    checkLub(void__B_C, A__, Function_);
    checkLub(void__B_C, B__, Function_);
    checkLub(void__B_C, C__, Function_);
    checkLub(void__B_C, void__A_B, void__Object_B);
    checkLub(void__B_C, void__A_C, void__Object_C);
    checkLub(void__B_C, void__B_A, void__B_Object);
    checkLub(void__B_C, void__B_C, void__B_C);
    checkLub(void__B_C, void___B, Function_);
    checkLub(void__B_C, void___B_C, Function_);
    checkLub(void__B_C, void___C_C, Function_);
    checkLub(void__B_C, void____B, Function_);
    checkLub(void__B_C, void____B_C, Function_);
    checkLub(void__B_C, void____C_C, Function_);

    checkLub(void___B, Object_, Object_);
    checkLub(void___B, Function_, Function_);
    checkLub(void___B, dynamic__, dynamic__);
    checkLub(void___B, void__, void__);
    checkLub(void___B, A__, void__);
    checkLub(void___B, B__, void__);
    checkLub(void___B, C__, void__);
    checkLub(void___B, void__A_B, Function_);
    checkLub(void___B, void__A_C, Function_);
    checkLub(void___B, void__B_A, Function_);
    checkLub(void___B, void__B_C, Function_);
    checkLub(void___B, void___B, void___B);
    checkLub(void___B, void___B_C, void___B);
    checkLub(void___B, void___C_C, void___B);
    checkLub(void___B, void____B, void__);
    checkLub(void___B, void____B_C, void__);
    checkLub(void___B, void____C_C, void__);

    checkLub(void___B_C, Object_, Object_);
    checkLub(void___B_C, Function_, Function_);
    checkLub(void___B_C, dynamic__, dynamic__);
    checkLub(void___B_C, void__, void__);
    checkLub(void___B_C, A__, void__);
    checkLub(void___B_C, B__, void__);
    checkLub(void___B_C, C__, void__);
    checkLub(void___B_C, void__A_B, Function_);
    checkLub(void___B_C, void__A_C, Function_);
    checkLub(void___B_C, void__B_A, Function_);
    checkLub(void___B_C, void__B_C, Function_);
    checkLub(void___B_C, void___B, void___B);
    checkLub(void___B_C, void___B_C, void___B_C);
    checkLub(void___B_C, void___C_C, void___B_C);
    checkLub(void___B_C, void____B, void__);
    checkLub(void___B_C, void____B_C, void__);
    checkLub(void___B_C, void____C_C, void__);

    checkLub(void___C_C, Object_, Object_);
    checkLub(void___C_C, Function_, Function_);
    checkLub(void___C_C, dynamic__, dynamic__);
    checkLub(void___C_C, void__, void__);
    checkLub(void___C_C, A__, void__);
    checkLub(void___C_C, B__, void__);
    checkLub(void___C_C, C__, void__);
    checkLub(void___C_C, void__A_B, Function_);
    checkLub(void___C_C, void__A_C, Function_);
    checkLub(void___C_C, void__B_A, Function_);
    checkLub(void___C_C, void__B_C, Function_);
    checkLub(void___C_C, void___B, void___B);
    checkLub(void___C_C, void___B_C, void___B_C);
    checkLub(void___C_C, void___C_C, void___C_C);
    checkLub(void___C_C, void____B, void__);
    checkLub(void___C_C, void____B_C, void__);
    checkLub(void___C_C, void____C_C, void__);

    checkLub(void____B, Object_, Object_);
    checkLub(void____B, Function_, Function_);
    checkLub(void____B, dynamic__, dynamic__);
    checkLub(void____B, void__, void__);
    checkLub(void____B, A__, void__);
    checkLub(void____B, B__, void__);
    checkLub(void____B, C__, void__);
    checkLub(void____B, void__A_B, Function_);
    checkLub(void____B, void__A_C, Function_);
    checkLub(void____B, void__B_A, Function_);
    checkLub(void____B, void__B_C, Function_);
    checkLub(void____B, void___B, void__);
    checkLub(void____B, void___B_C, void__);
    checkLub(void____B, void___C_C, void__);
    checkLub(void____B, void____B, void____B);
    checkLub(void____B, void____B_C, void____B);
    checkLub(void____B, void____C_C, void____B);

    checkLub(void____B_C, Object_, Object_);
    checkLub(void____B_C, Function_, Function_);
    checkLub(void____B_C, dynamic__, dynamic__);
    checkLub(void____B_C, void__, void__);
    checkLub(void____B_C, A__, void__);
    checkLub(void____B_C, B__, void__);
    checkLub(void____B_C, C__, void__);
    checkLub(void____B_C, void__A_B, Function_);
    checkLub(void____B_C, void__A_C, Function_);
    checkLub(void____B_C, void__B_A, Function_);
    checkLub(void____B_C, void__B_C, Function_);
    checkLub(void____B_C, void___B, void__);
    checkLub(void____B_C, void___B_C, void__);
    checkLub(void____B_C, void___C_C, void__);
    checkLub(void____B_C, void____B, void____B);
    checkLub(void____B_C, void____B_C, void____B_C);
    checkLub(void____B_C, void____C_C, void____B_C);

    checkLub(void____C_C, Object_, Object_);
    checkLub(void____C_C, Function_, Function_);
    checkLub(void____C_C, dynamic__, dynamic__);
    checkLub(void____C_C, void__, void__);
    checkLub(void____C_C, A__, void__);
    checkLub(void____C_C, B__, void__);
    checkLub(void____C_C, C__, void__);
    checkLub(void____C_C, void__A_B, Function_);
    checkLub(void____C_C, void__A_C, Function_);
    checkLub(void____C_C, void__B_A, Function_);
    checkLub(void____C_C, void__B_C, Function_);
    checkLub(void____C_C, void___B, void__);
    checkLub(void____C_C, void___B_C, void__);
    checkLub(void____C_C, void___C_C, void__);
    checkLub(void____C_C, void____B, void____B);
    checkLub(void____C_C, void____B_C, void____B_C);
    checkLub(void____C_C, void____C_C, void____C_C);
  }));
}

void testTypeVariable() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A {}
      class B {}
      class C extends B {}
      class I<S extends A,
              T extends B,
              U extends C,
              V extends T,
              W extends V,
              X extends T> {}
      """).then((env) {

    //  A     B
    //  |    / \
    //  S   T   C
    //     / \   \
    //    V   X   U
    //   /
    //  W

    DartType Object_ = env['Object'];
    DartType A = env['A'];
    DartType B = env['B'];
    DartType C = env['C'];
    ClassElement I = env.getElement('I');
    DartType S = I.typeVariables.head;
    DartType T = I.typeVariables.tail.head;
    DartType U = I.typeVariables.tail.tail.head;
    DartType V = I.typeVariables.tail.tail.tail.head;
    DartType W = I.typeVariables.tail.tail.tail.tail.head;
    DartType X = I.typeVariables.tail.tail.tail.tail.tail.head;

    checkLub(DartType a, DartType b, DartType expectedLub) {
      DartType lub = env.computeLeastUpperBound(a, b);
      Expect.equals(expectedLub, lub,
          'Unexpected lub($a,$b) = $lub, expected $expectedLub');
    }

    checkLub(Object_, Object_, Object_);
    checkLub(Object_, A, Object_);
    checkLub(Object_, B, Object_);
    checkLub(Object_, C, Object_);
    checkLub(Object_, S, Object_);
    checkLub(Object_, T, Object_);
    checkLub(Object_, U, Object_);
    checkLub(Object_, V, Object_);
    checkLub(Object_, W, Object_);
    checkLub(Object_, X, Object_);

    checkLub(A, Object_, Object_);
    checkLub(A, A, A);
    checkLub(A, B, Object_);
    checkLub(A, C, Object_);
    checkLub(A, S, A);
    checkLub(A, T, Object_);
    checkLub(A, U, Object_);
    checkLub(A, V, Object_);
    checkLub(A, W, Object_);
    checkLub(A, X, Object_);

    checkLub(B, Object_, Object_);
    checkLub(B, A, Object_);
    checkLub(B, B, B);
    checkLub(B, C, B);
    checkLub(B, S, Object_);
    checkLub(B, T, B);
    checkLub(B, U, B);
    checkLub(B, V, B);
    checkLub(B, W, B);
    checkLub(B, X, B);

    checkLub(C, Object_, Object_);
    checkLub(C, A, Object_);
    checkLub(C, B, B);
    checkLub(C, C, C);
    checkLub(C, S, Object_);
    checkLub(C, T, B);
    checkLub(C, U, C);
    checkLub(C, V, B);
    checkLub(C, W, B);
    checkLub(C, X, B);

    checkLub(S, Object_, Object_);
    checkLub(S, A, A);
    checkLub(S, B, Object_);
    checkLub(S, C, Object_);
    checkLub(S, S, S);
    checkLub(S, T, Object_);
    checkLub(S, U, Object_);
    checkLub(S, V, Object_);
    checkLub(S, W, Object_);
    checkLub(S, X, Object_);

    checkLub(T, Object_, Object_);
    checkLub(T, A, Object_);
    checkLub(T, B, B);
    checkLub(T, C, B);
    checkLub(T, S, Object_);
    checkLub(T, T, T);
    checkLub(T, U, B);
    checkLub(T, V, T);
    checkLub(T, W, T);
    checkLub(T, X, T);

    checkLub(U, Object_, Object_);
    checkLub(U, A, Object_);
    checkLub(U, B, B);
    checkLub(U, C, C);
    checkLub(U, S, Object_);
    checkLub(U, T, B);
    checkLub(U, U, U);
    checkLub(U, V, B);
    checkLub(U, W, B);
    checkLub(U, X, B);

    checkLub(V, Object_, Object_);
    checkLub(V, A, Object_);
    checkLub(V, B, B);
    checkLub(V, C, B);
    checkLub(V, S, Object_);
    checkLub(V, T, T);
    checkLub(V, U, B);
    checkLub(V, V, V);
    checkLub(V, W, V);
    checkLub(V, X, T);

    checkLub(W, Object_, Object_);
    checkLub(W, A, Object_);
    checkLub(W, B, B);
    checkLub(W, C, B);
    checkLub(W, S, Object_);
    checkLub(W, T, T);
    checkLub(W, U, B);
    checkLub(W, V, V);
    checkLub(W, W, W);
    checkLub(W, X, T);

    checkLub(X, Object_, Object_);
    checkLub(X, A, Object_);
    checkLub(X, B, B);
    checkLub(X, C, B);
    checkLub(X, S, Object_);
    checkLub(X, T, T);
    checkLub(X, U, B);
    checkLub(X, V, T);
    checkLub(X, W, T);
    checkLub(X, X, X);
  }));
}


