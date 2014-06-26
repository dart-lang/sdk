// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'type_test_helper.dart';
import 'package:compiler/implementation/dart_types.dart';
import "package:compiler/implementation/elements/elements.dart"
       show Element, ClassElement;

void main() {
  testTypeVariableOccurrence();
}

testTypeVariableOccurrence() {
  asyncTest(() => TypeEnvironment.create(r"""
      typedef S Typedef1<S>();
      typedef void Typedef2<S>(S s);
      typedef void Typedef3<S>(A<S> a);

      class A<T> {
        int field1;
        T field2;
        A<int> field3;
        A<T> field4;
        A<A<int>> field5;
        A<A<T>> field6;

        Typedef1 field7;
        Typedef1<int> field8;
        Typedef1<T> field9;
        Typedef1<Typedef1<T>> field10;

        Typedef2 field11;
        Typedef2<int> field12;
        Typedef2<T> field13;
        Typedef2<Typedef1<T>> field14;

        Typedef3 field15;
        Typedef3<int> field16;
        Typedef3<T> field17;
        Typedef3<Typedef1<T>> field18;

        void method1() {}
        T method2() => null;
        A<T> method3() => null;
        void method4(T t) {}
        void method5(A<T> t) {}
        void method6(void foo(T t)) {}
        void method7([T t]) {}
        void method8({T t}) {}
      }
      """).then((env) {

    ClassElement A = env.getElement('A');

    expect(bool expectResult, String memberName) {
      DartType memberType = env.getMemberType(A, memberName);
      TypeVariableType typeVariable = memberType.typeVariableOccurrence;
      if (expectResult) {
        Expect.isNotNull(typeVariable);
        Expect.equals(A, Types.getClassContext(memberType));
      } else {
        Expect.isNull(typeVariable);
        Expect.isNull(Types.getClassContext(memberType));
      }
    }

    // int field1;
    expect(false, 'field1');
    // T field2;
    expect(true, 'field2');
    // A<int> field3;
    expect(false, 'field3');
    // A<T> field4;
    expect(true, 'field4');
    // A<A<int>> field5;
    expect(false, 'field5');
    // A<A<T>> field6;
    expect(true, 'field6');

    // Typedef1 field7;
    expect(false, 'field7');
    // Typedef1<int> field8;
    expect(false, 'field8');
    // Typedef1<T> field9;
    expect(true, 'field9');
    // Typedef1<Typedef1<T>> field10;
    expect(true, 'field10');

    // Typedef2 field11;
    expect(false, 'field11');
    // Typedef2<int> field12;
    expect(false, 'field12');
    // Typedef2<T> field13;
    expect(true, 'field13');
    // Typedef2<Typedef1<T>> field14;
    expect(true, 'field14');

    // Typedef3 field15;
    expect(false, 'field15');
    // Typedef3<int> field16;
    expect(false, 'field16');
    // Typedef3<T> field17;
    expect(true, 'field17');
    // Typedef3<Typedef1<T>> field18;
    expect(true, 'field18');

    // void method1() {}
    expect(false, 'method1');
    // T method2() => null;
    expect(true, 'method2');
    // A<T> method3() => null;
    expect(true, 'method3');
    // void method4(T t) {}
    expect(true, 'method4');
    // void method5(A<T> t) {}
    expect(true, 'method5');
    // void method6(void foo(T t)) {}
    expect(true, 'method6');
    // void method7([T t]);
    expect(true, 'method7');
    // void method8({T t});
    expect(true, 'method8');
  }));
}
