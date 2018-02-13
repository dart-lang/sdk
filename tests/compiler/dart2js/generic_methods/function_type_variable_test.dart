// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:expect/expect.dart';
import '../type_test_helper.dart';

const List<FunctionTypeData> existentialTypeData = const <FunctionTypeData>[
  // TODO(johnniwinther): Test generic bounds when #31531 is fixed.
  const FunctionTypeData('void', 'F1', '<T>(T t)'),
  const FunctionTypeData('void', 'F2', '<S>(S s)'),
  const FunctionTypeData('void', 'F3', '<U, V>(U u, V v)'),
  const FunctionTypeData('void', 'F4', '<U, V>(V v, U u)'),
  const FunctionTypeData('void', 'F5', '<W extends num>(W w)'),
  const FunctionTypeData('void', 'F6', '<X extends int>(X x)'),
  const FunctionTypeData('void', 'F7', '<Y extends num>(Y y, [int i])'),
  const FunctionTypeData('Z', 'F8', '<Z extends num>(Z z)'),
];

main() {
  asyncTest(() async {
    var env = await TypeEnvironment
        .create(createTypedefs(existentialTypeData, additionalData: """
    class C1 {}
    class C2 {}
    class C3<T> {
      factory C3.fact() => C3.gen();
      C3.gen();
    }
  """), compileMode: CompileMode.kernel, options: [Flags.strongMode]);

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

    testRelations(DartType a, DartType b,
        {bool areEqual: false, bool isSubtype: false}) {
      if (areEqual) {
        isSubtype = true;
      }
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
    FunctionType F7 = env.getFieldType('F7');
    FunctionType F8 = env.getFieldType('F8');

    testToString(F1, 'void Function<#A>(#A)');
    testToString(F2, 'void Function<#A>(#A)');
    testToString(F3, 'void Function<#A,#B>(#A,#B)');
    testToString(F4, 'void Function<#A,#B>(#B,#A)');
    testToString(F5, 'void Function<#A extends num>(#A)');
    testToString(F6, 'void Function<#A extends int>(#A)');
    testToString(F7, 'void Function<#A extends num>(#A,[int])');
    testToString(F8, '#A Function<#A extends num>(#A)');

    testBounds(F1, [Object_]);
    testBounds(F2, [Object_]);
    testBounds(F3, [Object_, Object_]);
    testBounds(F4, [Object_, Object_]);
    testBounds(F5, [num_]);
    testBounds(F6, [int_]);
    testBounds(F7, [num_]);
    testBounds(F8, [num_]);

    testInstantiate(F1, [C1], 'void Function(C1)');
    testInstantiate(F2, [C2], 'void Function(C2)');
    testInstantiate(F3, [C1, C2], 'void Function(C1,C2)');
    testInstantiate(F4, [C1, C2], 'void Function(C2,C1)');
    testInstantiate(F5, [num_], 'void Function(num)');
    testInstantiate(F6, [int_], 'void Function(int)');
    testInstantiate(F7, [int_], 'void Function(int,[int])');
    testInstantiate(F8, [int_], 'int Function(int)');

    testRelations(F1, F1, areEqual: true);
    testRelations(F1, F2, areEqual: true);
    testRelations(F1, F3);
    testRelations(F1, F4);
    testRelations(F1, F5);
    testRelations(F1, F6);
    testRelations(F1, F7);
    testRelations(F1, F8);

    testRelations(F2, F1, areEqual: true);
    testRelations(F2, F2, areEqual: true);
    testRelations(F2, F3);
    testRelations(F2, F4);
    testRelations(F2, F5);
    testRelations(F2, F6);
    testRelations(F2, F7);
    testRelations(F2, F8);

    testRelations(F3, F1);
    testRelations(F3, F2);
    testRelations(F3, F3, areEqual: true);
    testRelations(F3, F4);
    testRelations(F3, F5);
    testRelations(F3, F6);
    testRelations(F3, F7);
    testRelations(F3, F8);

    testRelations(F4, F1);
    testRelations(F4, F2);
    testRelations(F4, F3);
    testRelations(F4, F4, areEqual: true);
    testRelations(F4, F5);
    testRelations(F4, F6);
    testRelations(F4, F7);
    testRelations(F4, F8);

    testRelations(F5, F1);
    testRelations(F5, F2);
    testRelations(F5, F3);
    testRelations(F5, F4);
    testRelations(F5, F5, areEqual: true);
    testRelations(F5, F6);
    testRelations(F5, F7);
    testRelations(F5, F8);

    testRelations(F6, F1);
    testRelations(F6, F2);
    testRelations(F6, F3);
    testRelations(F6, F4);
    testRelations(F6, F5);
    testRelations(F6, F6, areEqual: true);
    testRelations(F6, F7);
    testRelations(F6, F8);

    testRelations(F7, F1);
    testRelations(F7, F2);
    testRelations(F7, F3);
    testRelations(F7, F4);
    testRelations(F7, F5, isSubtype: true);
    testRelations(F7, F6);
    testRelations(F7, F7, areEqual: true);
    testRelations(F7, F8);

    testRelations(F8, F1);
    testRelations(F8, F2);
    testRelations(F8, F3);
    testRelations(F8, F4);
    testRelations(F8, F5, isSubtype: true);
    testRelations(F8, F6);
    testRelations(F8, F7);
    testRelations(F8, F8, areEqual: true);

    testRelations(F1.typeVariables.first, F1.typeVariables.first,
        areEqual: true);
    testRelations(F1.typeVariables.first, F2.typeVariables.first);

    ClassEntity cls = env.getClass('C3');
    env.elementEnvironment.forEachConstructor(cls,
        (ConstructorEntity constructor) {
      Expect.equals(
          0,
          constructor.parameterStructure.typeParameters,
          "Type parameters found on constructor $constructor: "
          "${constructor.parameterStructure}");
      List<TypeVariableType> functionTypeVariables =
          env.elementEnvironment.getFunctionTypeVariables(constructor);
      Expect.isTrue(
          functionTypeVariables.isEmpty,
          "Function type variables found on constructor $constructor: "
          "$functionTypeVariables");
    });
  });
}
