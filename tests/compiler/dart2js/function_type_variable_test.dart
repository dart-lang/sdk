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
  const FunctionTypeData('void', 'F5', '<W extends num>(W w)'),
  const FunctionTypeData('void', 'F6', '<X extends int>(X x)'),
];

main() {
  DartTypeConverter.enableFunctionTypeVariables = true;
  asyncTest(() async {
    var env = await TypeEnvironment
        .create(createTypedefs(existentialTypeData, additionalData: """
    class C1 {}
    class C2 {}
  """), compileMode: CompileMode.kernel);

    testToString(FunctionType type, String expectedToString) {
      Expect.equals(expectedToString, type.toString());
    }

    testBounds(FunctionType type, List<DartType> expectedBounds) {
      Expect.equals(expectedBounds.length, type.typeVariables.length,
          "Unexpected type variable count in $type.");
      for (int i = 0; i < expectedBounds.length; i++) {
        Expect.equals(expectedBounds[i], type.typeVariables[i].bound,
            "Unexpected ${i}th bound in $type.");
      }
    }

    testInstantiate(FunctionType type, List<DartType> instantiation,
        String expectedToString) {
      DartType result = type.instantiate(instantiation);
      Expect.equals(expectedToString, result.toString(),
          "Unexpected instantiation of $type with $instantiation: $result");
    }

    testRelations(DartType a, DartType b, bool areEqual, bool isSubtype) {
      Expect.equals(
          areEqual,
          a == b,
          "Expected `$a` and `$b` to be ${areEqual ? 'equal' : 'non-equal'}, "
          "but they are not.");
      Expect.equals(
          isSubtype,
          env.isSubtype(a, b),
          "Expected `$a` ${isSubtype ? '' : 'not '}to be a subtype of `$b`, "
          "but it is${isSubtype ? ' not' : ''}.");
    }

    InterfaceType Object_ = env['Object'];
    InterfaceType num_ = env['num'];
    InterfaceType int_ = env['int'];
    InterfaceType C1 = instantiate(env.getClass('C1'), []);
    InterfaceType C2 = instantiate(env.getClass('C2'), []);
    FunctionType F1 = env.getFieldType('F1');
    FunctionType F2 = env.getFieldType('F2');
    FunctionType F3 = env.getFieldType('F3');
    FunctionType F4 = env.getFieldType('F4');
    FunctionType F5 = env.getFieldType('F5');
    FunctionType F6 = env.getFieldType('F6');

    testToString(F1, 'void Function<#A>(#A)');
    testToString(F2, 'void Function<#A>(#A)');
    testToString(F3, 'void Function<#A,#B>(#A,#B)');
    testToString(F4, 'void Function<#A,#B>(#B,#A)');
    testToString(F5, 'void Function<#A extends num>(#A)');
    testToString(F6, 'void Function<#A extends int>(#A)');

    testBounds(F1, [Object_]);
    testBounds(F2, [Object_]);
    testBounds(F3, [Object_, Object_]);
    testBounds(F4, [Object_, Object_]);
    testBounds(F5, [num_]);
    testBounds(F6, [int_]);

    testInstantiate(F1, [C1], 'void Function(C1)');
    testInstantiate(F2, [C2], 'void Function(C2)');
    testInstantiate(F3, [C1, C2], 'void Function(C1,C2)');
    testInstantiate(F4, [C1, C2], 'void Function(C2,C1)');
    testInstantiate(F5, [num_], 'void Function(num)');
    testInstantiate(F6, [int_], 'void Function(int)');

    testRelations(F1, F1, true, true);
    testRelations(F1, F2, true, true);
    testRelations(F1, F3, false, false);
    testRelations(F1, F4, false, false);
    testRelations(F1, F5, false, false);
    testRelations(F1, F6, false, false);

    testRelations(F2, F1, true, true);
    testRelations(F2, F2, true, true);
    testRelations(F2, F3, false, false);
    testRelations(F2, F4, false, false);
    testRelations(F2, F5, false, false);
    testRelations(F2, F6, false, false);

    testRelations(F3, F1, false, false);
    testRelations(F3, F2, false, false);
    testRelations(F3, F3, true, true);
    testRelations(F3, F4, false, false);
    testRelations(F3, F5, false, false);
    testRelations(F3, F6, false, false);

    testRelations(F4, F1, false, false);
    testRelations(F4, F2, false, false);
    testRelations(F4, F3, false, false);
    testRelations(F4, F4, true, true);
    testRelations(F4, F5, false, false);
    testRelations(F4, F6, false, false);

    testRelations(F5, F1, false, false);
    testRelations(F5, F2, false, false);
    testRelations(F5, F3, false, false);
    testRelations(F5, F4, false, false);
    testRelations(F5, F5, true, true);
    testRelations(F5, F6, false, false);

    testRelations(F6, F1, false, false);
    testRelations(F6, F2, false, false);
    testRelations(F6, F3, false, false);
    testRelations(F6, F4, false, false);
    testRelations(F6, F5, false, false);
    testRelations(F6, F6, true, true);

    testRelations(F1.typeVariables.first, F1.typeVariables.first, true, true);
    testRelations(F1.typeVariables.first, F2.typeVariables.first, false, false);
  });
}
