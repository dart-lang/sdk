// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_order_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'type_test_helper.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import "package:compiler/src/elements/elements.dart"
    show ClassElement, TypedefElement;

void main() {
  asyncTest(() => TypeEnvironment.create(r"""
      class A<AT, AS> {}
      typedef BS B<BT, BS>(BT t);
      class C<CT, CS> extends A<CS, CT> {}
      class X {}
      class Y {}
      class Z {}
      """).then((env) {
        var types = <ResolutionDartType>[];
        ResolutionDartType add(ResolutionDartType type) {
          types.add(type);
          return type;
        }

        ResolutionDartType dynamic_ = add(env['dynamic']);
        ResolutionDartType void_ = add(env['void']);

        ClassElement A = env.getElement('A');
        TypedefElement B = env.getElement('B');
        ClassElement C = env.getElement('C');
        ResolutionDartType X = add(env['X']);
        ResolutionDartType Y = add(env['Y']);
        ResolutionDartType Z = add(env['Z']);

        ResolutionInterfaceType A_this = add(A.thisType);
        ResolutionInterfaceType A_raw = add(A.rawType);
        ResolutionTypeVariableType AT = add(A_this.typeArguments[0]);
        ResolutionTypeVariableType AS = add(A_this.typeArguments[1]);
        ResolutionInterfaceType A_X_Y = add(instantiate(A, [X, Y]));
        ResolutionInterfaceType A_Y_X = add(instantiate(A, [Y, X]));

        ResolutionTypedefType B_this =
            add(B.computeType(env.compiler.resolution));
        ResolutionTypedefType B_raw = add(B.rawType);
        ResolutionTypeVariableType BT = add(B_this.typeArguments[0]);
        ResolutionTypeVariableType BS = add(B_this.typeArguments[1]);
        ResolutionFunctionType B_this_alias = add(B.alias);
        ResolutionTypedefType B_X_Y = add(instantiate(B, [X, Y]));
        ResolutionFunctionType B_X_Y_alias = add(B_X_Y.unaliased);
        ResolutionTypedefType B_Y_X = add(instantiate(B, [Y, X]));
        ResolutionFunctionType B_Y_X_alias = add(B_Y_X.unaliased);

        ResolutionInterfaceType C_this = add(C.thisType);
        ResolutionInterfaceType C_raw = add(C.rawType);
        ResolutionTypeVariableType CT = add(C_this.typeArguments[0]);
        ResolutionTypeVariableType CS = add(C_this.typeArguments[1]);

        Expect.listEquals(<ResolutionDartType>[
          void_,
          dynamic_,
          A_raw,
          A_this,
          A_X_Y,
          A_Y_X,
          AT,
          AS,
          B_raw,
          B_this,
          B_X_Y,
          B_Y_X,
          BT,
          BS,
          C_raw,
          C_this,
          CT,
          CS,
          X,
          Y,
          Z,
          B_this_alias,
          B_Y_X_alias,
          B_X_Y_alias,
        ], Types.sorted(types));
      }));
}
