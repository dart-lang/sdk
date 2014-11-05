// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'type_test_helper.dart';
import 'package:compiler/src/dart_types.dart';
import "package:compiler/src/elements/elements.dart"
       show Element, ClassElement, MemberSignature, PublicName;

void main() {
  test();
}

void test() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A<T> {
        T foo;
      }
      class B<S> extends A<A<S>> {
        S bar;
      }
      class C<U> extends B<String> with D<B<U>> {
        U baz;
      }
      class D<V> {
        V boz;
      }
      """).then((env) {
    void expect(InterfaceType receiverType, String memberName,
                DartType expectedType) {
      MemberSignature member = receiverType.lookupInterfaceMember(
          new PublicName(memberName));
      Expect.isNotNull(member);
      DartType memberType = member.type;
      Expect.equals(expectedType, memberType,
          'Wrong member type for $receiverType.$memberName.');
    }

    DartType int_ = env['int'];
    DartType String_ = env['String'];

    ClassElement A = env.getElement('A');
    DartType T = A.typeVariables.first;
    DartType A_T = A.thisType;
    expect(A_T, 'foo', T);

    DartType A_int = instantiate(A, [int_]);
    expect(A_int, 'foo', int_);

    ClassElement B = env.getElement('B');
    DartType S = B.typeVariables.first;
    DartType B_S = B.thisType;
    expect(B_S, 'foo', instantiate(A, [S]));
    expect(B_S, 'bar', S);

    DartType B_int = instantiate(B, [int_]);
    expect(B_int, 'foo', A_int);
    expect(B_int, 'bar', int_);

    ClassElement C = env.getElement('C');
    DartType U = C.typeVariables.first;
    DartType C_U = C.thisType;
    expect(C_U, 'foo', instantiate(A, [String_]));
    expect(C_U, 'bar', String_);
    expect(C_U, 'baz', U);
    expect(C_U, 'boz', instantiate(B, [U]));

    DartType C_int = instantiate(C, [int_]);
    expect(C_int, 'foo', instantiate(A, [String_]));
    expect(C_int, 'bar', String_);
    expect(C_int, 'baz', int_);
    expect(C_int, 'boz', instantiate(B, [int_]));
  }));
}

