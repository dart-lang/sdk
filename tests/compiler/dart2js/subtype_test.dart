// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'type_test_helper.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart_types.dart';
import "../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart"
       show Element, ClassElement;

void main() {
  testInterfaceSubtype();
  testCallableSubtype();
}

void testInterfaceSubtype() {
  var env = new TypeEnvironment(r"""
      class A<T> {}
      class B<T1, T2> extends A<T1> {}
      // TODO(johnniwinther): Inheritance with different type arguments is
      // currently not supported by the implementation.
      class C<T1, T2> extends B<T2, T1> /*implements A<A<T1>>*/ {}
      """);

  void expect(bool value, DartType T, DartType S) {
    Expect.equals(value, env.isSubtype(T, S), '$T <: $S');
  }

  ClassElement A = env.getElement('A');
  ClassElement B = env.getElement('B');
  ClassElement C = env.getElement('C');
  DartType Object_ = env['Object'];
  DartType num_ = env['num'];
  DartType int_ = env['int'];
  DartType String_ = env['String'];
  DartType dynamic_ = env['dynamic'];

  expect(true, Object_, Object_);
  expect(true, num_, Object_);
  expect(true, int_, Object_);
  expect(true, String_, Object_);
  expect(true, dynamic_, Object_);

  expect(false, Object_, num_);
  expect(true, num_, num_);
  expect(true, int_, num_);
  expect(false, String_, num_);
  expect(true, dynamic_, num_);

  expect(false, Object_, int_);
  expect(false, num_, int_);
  expect(true, int_, int_);
  expect(false, String_, int_);
  expect(true, dynamic_, int_);

  expect(false, Object_, String_);
  expect(false, num_, String_);
  expect(false, int_, String_);
  expect(true, String_, String_);
  expect(true, dynamic_, String_);

  expect(true, Object_, dynamic_);
  expect(true, num_, dynamic_);
  expect(true, int_, dynamic_);
  expect(true, String_, dynamic_);
  expect(true, dynamic_, dynamic_);

  DartType A_Object = instantiate(A, [Object_]);
  DartType A_num = instantiate(A, [num_]);
  DartType A_int = instantiate(A, [int_]);
  DartType A_String = instantiate(A, [String_]);
  DartType A_dynamic = instantiate(A, [dynamic_]);

  expect(true, A_Object, Object_);
  expect(false, A_Object, num_);
  expect(false, A_Object, int_);
  expect(false, A_Object, String_);
  expect(true, A_Object, dynamic_);

  expect(true, A_Object, A_Object);
  expect(true, A_num, A_Object);
  expect(true, A_int, A_Object);
  expect(true, A_String, A_Object);
  expect(true, A_dynamic, A_Object);

  expect(false, A_Object, A_num);
  expect(true, A_num, A_num);
  expect(true, A_int, A_num);
  expect(false, A_String, A_num);
  expect(true, A_dynamic, A_num);

  expect(false, A_Object, A_int);
  expect(false, A_num, A_int);
  expect(true, A_int, A_int);
  expect(false, A_String, A_int);
  expect(true, A_dynamic, A_int);

  expect(false, A_Object, A_String);
  expect(false, A_num, A_String);
  expect(false, A_int, A_String);
  expect(true, A_String, A_String);
  expect(true, A_dynamic, A_String);

  expect(true, A_Object, A_dynamic);
  expect(true, A_num, A_dynamic);
  expect(true, A_int, A_dynamic);
  expect(true, A_String, A_dynamic);
  expect(true, A_dynamic, A_dynamic);

  DartType B_Object_Object = instantiate(B, [Object_, Object_]);
  DartType B_num_num = instantiate(B, [num_, num_]);
  DartType B_int_num = instantiate(B, [int_, num_]);
  DartType B_dynamic_dynamic = instantiate(B, [dynamic_, dynamic_]);
  DartType B_String_dynamic = instantiate(B, [String_, dynamic_]);

  expect(true, B_Object_Object, Object_);
  expect(true, B_Object_Object, A_Object);
  expect(false, B_Object_Object, A_num);
  expect(false, B_Object_Object, A_int);
  expect(false, B_Object_Object, A_String);
  expect(true, B_Object_Object, A_dynamic);

  expect(true, B_num_num, Object_);
  expect(true, B_num_num, A_Object);
  expect(true, B_num_num, A_num);
  expect(false, B_num_num, A_int);
  expect(false, B_num_num, A_String);
  expect(true, B_num_num, A_dynamic);

  expect(true, B_int_num, Object_);
  expect(true, B_int_num, A_Object);
  expect(true, B_int_num, A_num);
  expect(true, B_int_num, A_int);
  expect(false, B_int_num, A_String);
  expect(true, B_int_num, A_dynamic);

  expect(true, B_dynamic_dynamic, Object_);
  expect(true, B_dynamic_dynamic, A_Object);
  expect(true, B_dynamic_dynamic, A_num);
  expect(true, B_dynamic_dynamic, A_int);
  expect(true, B_dynamic_dynamic, A_String);
  expect(true, B_dynamic_dynamic, A_dynamic);

  expect(true, B_String_dynamic, Object_);
  expect(true, B_String_dynamic, A_Object);
  expect(false, B_String_dynamic, A_num);
  expect(false, B_String_dynamic, A_int);
  expect(true, B_String_dynamic, A_String);
  expect(true, B_String_dynamic, A_dynamic);

  expect(true, B_Object_Object, B_Object_Object);
  expect(true, B_num_num, B_Object_Object);
  expect(true, B_int_num, B_Object_Object);
  expect(true, B_dynamic_dynamic, B_Object_Object);
  expect(true, B_String_dynamic, B_Object_Object);

  expect(false, B_Object_Object, B_num_num);
  expect(true, B_num_num, B_num_num);
  expect(true, B_int_num, B_num_num);
  expect(true, B_dynamic_dynamic, B_num_num);
  expect(false, B_String_dynamic, B_num_num);

  expect(false, B_Object_Object, B_int_num);
  expect(false, B_num_num, B_int_num);
  expect(true, B_int_num, B_int_num);
  expect(true, B_dynamic_dynamic, B_int_num);
  expect(false, B_String_dynamic, B_int_num);

  expect(true, B_Object_Object, B_dynamic_dynamic);
  expect(true, B_num_num, B_dynamic_dynamic);
  expect(true, B_int_num, B_dynamic_dynamic);
  expect(true, B_dynamic_dynamic, B_dynamic_dynamic);
  expect(true, B_String_dynamic, B_dynamic_dynamic);

  expect(false, B_Object_Object, B_String_dynamic);
  expect(false, B_num_num, B_String_dynamic);
  expect(false, B_int_num, B_String_dynamic);
  expect(true, B_dynamic_dynamic, B_String_dynamic);
  expect(true, B_String_dynamic, B_String_dynamic);

  DartType C_Object_Object = instantiate(C, [Object_, Object_]);
  DartType C_num_num = instantiate(C, [num_, num_]);
  DartType C_int_String = instantiate(C, [int_, String_]);
  DartType C_dynamic_dynamic = instantiate(C, [dynamic_, dynamic_]);

  expect(true, C_Object_Object, B_Object_Object);
  expect(false, C_Object_Object, B_num_num);
  expect(false, C_Object_Object, B_int_num);
  expect(true, C_Object_Object, B_dynamic_dynamic);
  expect(false, C_Object_Object, B_String_dynamic);

  expect(true, C_num_num, B_Object_Object);
  expect(true, C_num_num, B_num_num);
  expect(false, C_num_num, B_int_num);
  expect(true, C_num_num, B_dynamic_dynamic);
  expect(false, C_num_num, B_String_dynamic);

  expect(true, C_int_String, B_Object_Object);
  expect(false, C_int_String, B_num_num);
  expect(false, C_int_String, B_int_num);
  expect(true, C_int_String, B_dynamic_dynamic);
  expect(true, C_int_String, B_String_dynamic);

  expect(true, C_dynamic_dynamic, B_Object_Object);
  expect(true, C_dynamic_dynamic, B_num_num);
  expect(true, C_dynamic_dynamic, B_int_num);
  expect(true, C_dynamic_dynamic, B_dynamic_dynamic);
  expect(true, C_dynamic_dynamic, B_String_dynamic);

  expect(false, C_int_String, A_int);
  expect(true, C_int_String, A_String);
  // TODO(johnniwinther): Inheritance with different type arguments is
  // currently not supported by the implementation.
  //expect(true, C_int_String, instantiate(A, [A_int]));
  expect(false, C_int_String, instantiate(A, [A_String]));
}

void testCallableSubtype() {

  var env = new TypeEnvironment(r"""
      class U {}
      class V extends U {}
      class W extends V {}
      class A {
        int call(V v, int i);

        int m1(U u, int i);
        int m2(W w, num n);
        U m3(V v, int i);
        int m4(V v, U u);
        void m5(V v, int i);
      }
      """);

  void expect(bool value, DartType T, DartType S) {
    Expect.equals(value, env.isSubtype(T, S), '$T <: $S');
  }

  ClassElement classA = env.getElement('A');
  DartType A = classA.rawType;
  DartType function = env['Function'];
  DartType m1 = env.getMemberType(classA, 'm1');
  DartType m2 = env.getMemberType(classA, 'm2');
  DartType m3 = env.getMemberType(classA, 'm3');
  DartType m4 = env.getMemberType(classA, 'm4');
  DartType m5 = env.getMemberType(classA, 'm5');

  expect(true, A, function);
  expect(true, A, m1);
  expect(true, A, m2);
  expect(false, A, m3);
  expect(false, A, m4);
  expect(true, A, m5);
}
