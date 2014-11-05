// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/dart_types.dart';
import "package:compiler/src/elements/elements.dart"
       show Element, ClassElement, TypedefElement;

void main() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A<AT, AS> {}
      typedef BS B<BT, BS>(BT t);
      class C<CT, CS> extends A<CS, CT> {}
      class X {}
      class Y {}
      class Z {}
      """).then((env) {

    List types = [];
    DartType add(DartType type) {
      types.add(type);
      return type;
    }

    DartType dynamic_ = add(env['dynamic']);
    DartType void_ = add(env['void']);

    ClassElement A = env.getElement('A');
    TypedefElement B = env.getElement('B');
    ClassElement C = env.getElement('C');
    DartType X = add(env['X']);
    DartType Y = add(env['Y']);
    DartType Z = add(env['Z']);

    InterfaceType A_this = add(A.thisType);
    InterfaceType A_raw = add(A.rawType);
    TypeVariableType AT = add(A_this.typeArguments[0]);
    TypeVariableType AS = add(A_this.typeArguments[1]);
    InterfaceType A_X_Y = add(instantiate(A, [X, Y]));
    InterfaceType A_Y_X = add(instantiate(A, [Y, X]));

    TypedefType B_this = add(B.computeType(env.compiler));
    TypedefType B_raw = add(B.rawType);
    TypeVariableType BT = add(B_this.typeArguments[0]);
    TypeVariableType BS = add(B_this.typeArguments[1]);
    FunctionType B_this_alias = add(B.alias);
    TypedefType B_X_Y = add(instantiate(B, [X, Y]));
    FunctionType B_X_Y_alias = add(B_X_Y.unalias(env.compiler));
    TypedefType B_Y_X = add(instantiate(B, [Y, X]));
    FunctionType B_Y_X_alias = add(B_Y_X.unalias(env.compiler));

    InterfaceType C_this = add(C.thisType);
    InterfaceType C_raw = add(C.rawType);
    TypeVariableType CT = add(C_this.typeArguments[0]);
    TypeVariableType CS = add(C_this.typeArguments[1]);

    Expect.listEquals(
        [void_, dynamic_,
         A_raw, A_this, A_X_Y, A_Y_X, AT, AS,
         B_raw, B_this, B_X_Y, B_Y_X, BT, BS,
         C_raw, C_this, CT, CS,
         X, Y, Z,
         B_this_alias, B_Y_X_alias, B_X_Y_alias,
        ],
        Types.sorted(types));
  }));
}