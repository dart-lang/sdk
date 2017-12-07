// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:expect/expect.dart';
import 'type_test_helper.dart';

const List<FunctionTypeData> existentialTypeData = const <FunctionTypeData>[
  // TODO(johnniwinther): Test generic bounds when #31531 is fixed.
  const FunctionTypeData('void', 'F1', '<T>(T t)'),
  const FunctionTypeData('void', 'F2', '<S>(S s)'),
  const FunctionTypeData('void', 'F3', '<U, V>(U u, V v)'),
  const FunctionTypeData('void', 'F4', '<U, V>(V v, U u)'),
];

main() {
  DartTypeConverter.enableFunctionTypeVariables = true;
  asyncTest(() async {
    var env = await TypeEnvironment
        .create(createTypedefs(existentialTypeData, additionalData: """
    class C1 {}
    class C2 {}
  """), compileMode: CompileMode.dill);

    testToString(FunctionType type, String expectedToString) {
      Expect.equals(expectedToString, type.toString());
    }

    testInstantiate(FunctionType type, List<DartType> instantiation,
        String expectedToString) {
      DartType result = type.instantiate(instantiation);
      Expect.equals(expectedToString, result.toString(),
          "Unexpected instantiation of $type with $instantiation: $result");
    }

    testEquals(DartType a, DartType b, bool expectedEquals) {
      Expect.equals(
          expectedEquals, a == b, "Unexpected equality for $a and $b.");
    }

    InterfaceType C1 = instantiate(env.getClass('C1'), []);
    InterfaceType C2 = instantiate(env.getClass('C2'), []);
    FunctionType F1 = env.getFieldType('F1');
    FunctionType F2 = env.getFieldType('F2');
    FunctionType F3 = env.getFieldType('F3');
    FunctionType F4 = env.getFieldType('F4');

    testToString(F1, 'void Function<#A>(#A)');
    testToString(F2, 'void Function<#A>(#A)');
    testToString(F3, 'void Function<#A,#B>(#A,#B)');
    testToString(F4, 'void Function<#A,#B>(#B,#A)');

    testInstantiate(F1, [C1], 'void Function(C1)');
    testInstantiate(F2, [C2], 'void Function(C2)');
    testInstantiate(F3, [C1, C2], 'void Function(C1,C2)');
    testInstantiate(F4, [C1, C2], 'void Function(C2,C1)');

    testEquals(F1, F1, true);
    testEquals(F1, F2, true);
    testEquals(F1, F3, false);
    testEquals(F1, F4, false);

    testEquals(F2, F1, true);
    testEquals(F2, F2, true);
    testEquals(F2, F3, false);
    testEquals(F2, F4, false);

    testEquals(F3, F1, false);
    testEquals(F3, F2, false);
    testEquals(F3, F3, true);
    testEquals(F3, F4, false);

    testEquals(F4, F1, false);
    testEquals(F4, F2, false);
    testEquals(F4, F3, false);
    testEquals(F4, F4, true);

    testEquals(F1.typeVariables.first, F1.typeVariables.first, true);
    testEquals(F1.typeVariables.first, F2.typeVariables.first, false);

    // TODO(johnniwinther): Test subtyping.
  });
}
