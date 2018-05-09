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
  const FunctionTypeData('void', 'F1', '<T>(T t)'),
  const FunctionTypeData('void', 'F2', '<S>(S s)'),
  const FunctionTypeData('void', 'F3', '<U, V>(U u, V v)'),
  const FunctionTypeData('void', 'F4', '<U, V>(V v, U u)'),
  const FunctionTypeData('void', 'F5', '<W extends num>(W w)'),
  const FunctionTypeData('void', 'F6', '<X extends int>(X x)'),
  const FunctionTypeData('void', 'F7', '<Y extends num>(Y y, [int i])'),
  const FunctionTypeData('Z', 'F8', '<Z extends num>(Z z)'),
  const FunctionTypeData('T', 'F13', '<T>(T t1, T t2)'),
  const FunctionTypeData('S', 'F14', '<S>(S s1, S s2)'),
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
    class C4 implements C3<C4> {}
    void F9<U extends V, V>(U u, V v) {}
    F10() {
      void local<A extends B, B>(A a, B b) {}
    }
    void F11<Q extends C3<Q>>(Q q) {}
    void F12<P extends C3<P>>(P p) {}
  """), options: [Flags.strongMode]);

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
      if (isSubtype) {
        Expect.isTrue(env.isPotentialSubtype(a, b),
            '$a <: $b but not a potential subtype.');
      }
    }

    InterfaceType Object_ = env['Object'];
    InterfaceType num_ = env['num'];
    InterfaceType int_ = env['int'];
    InterfaceType C1 = instantiate(env.getClass('C1'), []);
    InterfaceType C2 = instantiate(env.getClass('C2'), []);
    ClassEntity C3 = env.getClass('C3');
    InterfaceType C4 = instantiate(env.getClass('C4'), []);
    FunctionType F1 = env.getFieldType('F1');
    FunctionType F2 = env.getFieldType('F2');
    FunctionType F3 = env.getFieldType('F3');
    FunctionType F4 = env.getFieldType('F4');
    FunctionType F5 = env.getFieldType('F5');
    FunctionType F6 = env.getFieldType('F6');
    FunctionType F7 = env.getFieldType('F7');
    FunctionType F8 = env.getFieldType('F8');
    FunctionType F9 = env.getMemberType('F9');
    FunctionType F10 = env.getClosureType('F10');
    FunctionType F11 = env.getMemberType('F11');
    FunctionType F12 = env.getMemberType('F12');
    FunctionType F13 = env.getFieldType('F13');
    FunctionType F14 = env.getFieldType('F14');

    List<FunctionType> all = <FunctionType>[
      F1,
      F2,
      F3,
      F4,
      F5,
      F6,
      F7,
      F8,
      F9,
      F10,
      F11,
      F12,
      F13,
      F14,
    ];

    testToString(F1, 'void Function<#A>(#A)');
    testToString(F2, 'void Function<#A>(#A)');
    testToString(F3, 'void Function<#A,#B>(#A,#B)');
    testToString(F4, 'void Function<#A,#B>(#B,#A)');
    testToString(F5, 'void Function<#A extends num>(#A)');
    testToString(F6, 'void Function<#A extends int>(#A)');
    testToString(F7, 'void Function<#A extends num>(#A,[int])');
    testToString(F8, '#A Function<#A extends num>(#A)');
    testToString(F9, 'void Function<#A extends #B,#B>(#A,#B)');
    testToString(F10, 'void Function<#A extends #B,#B>(#A,#B)');
    testToString(F11, 'void Function<#A extends C3<#A>>(#A)');
    testToString(F12, 'void Function<#A extends C3<#A>>(#A)');
    testToString(F13, '#A Function<#A>(#A,#A)');
    testToString(F14, '#A Function<#A>(#A,#A)');

    testBounds(F1, [Object_]);
    testBounds(F2, [Object_]);
    testBounds(F3, [Object_, Object_]);
    testBounds(F4, [Object_, Object_]);
    testBounds(F5, [num_]);
    testBounds(F6, [int_]);
    testBounds(F7, [num_]);
    testBounds(F8, [num_]);
    testBounds(F9, [F9.typeVariables.last, Object_]);
    testBounds(F10, [F10.typeVariables.last, Object_]);
    testBounds(F11, [
      instantiate(C3, [F11.typeVariables.last])
    ]);
    testBounds(F12, [
      instantiate(C3, [F12.typeVariables.last])
    ]);
    testBounds(F13, [Object_]);
    testBounds(F14, [Object_]);

    testInstantiate(F1, [C1], 'void Function(C1)');
    testInstantiate(F2, [C2], 'void Function(C2)');
    testInstantiate(F3, [C1, C2], 'void Function(C1,C2)');
    testInstantiate(F4, [C1, C2], 'void Function(C2,C1)');
    testInstantiate(F5, [num_], 'void Function(num)');
    testInstantiate(F6, [int_], 'void Function(int)');
    testInstantiate(F7, [int_], 'void Function(int,[int])');
    testInstantiate(F8, [int_], 'int Function(int)');
    testInstantiate(F9, [int_, num_], 'void Function(int,num)');
    testInstantiate(F10, [int_, num_], 'void Function(int,num)');
    testInstantiate(F11, [C4], 'void Function(C4)');
    testInstantiate(F12, [C4], 'void Function(C4)');
    testInstantiate(F13, [C1], 'C1 Function(C1,C1)');
    testInstantiate(F14, [C2], 'C2 Function(C2,C2)');

    Map<FunctionType, List<FunctionType>> expectedEquals =
        <FunctionType, List<FunctionType>>{
      F1: [F2],
      F2: [F1],
      F9: [F10],
      F10: [F9],
      F11: [F12],
      F12: [F11],
      F13: [F14],
      F14: [F13],
    };

    Map<FunctionType, List<FunctionType>> expectedSubtype =
        <FunctionType, List<FunctionType>>{
      F7: [F5],
      F8: [F5],
    };

    for (FunctionType f1 in all) {
      for (FunctionType f2 in all) {
        testRelations(f1, f2,
            areEqual: identical(f1, f2) ||
                (expectedEquals[f1]?.contains(f2) ?? false),
            isSubtype: expectedSubtype[f1]?.contains(f2) ?? false);
      }
    }

    testRelations(F1.typeVariables.first, F1.typeVariables.first,
        areEqual: true);
    testRelations(F1.typeVariables.first, F2.typeVariables.first);

    env.elementEnvironment.forEachConstructor(C3,
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
