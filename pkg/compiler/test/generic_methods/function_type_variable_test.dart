// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

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

class ToStringTestData {
  final DartType type;
  final String expected;

  const ToStringTestData(this.type, this.expected);
}

class InstantiateTestData {
  final DartType type;
  final List<DartType> instantiation;
  final String expected;

  const InstantiateTestData(this.type, this.instantiation, this.expected);
}

class SubstTestData {
  final List<DartType> arguments;
  final List<DartType> parameters;
  final DartType type;
  final String expected;

  const SubstTestData(
      this.arguments, this.parameters, this.type, this.expected);
}

main() {
  asyncTest(() async {
    var env = await TypeEnvironment.create(
        createTypedefs(existentialTypeData, additionalData: """
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
    void F11<Q extends C3<Q>?>(Q q) {}
    void F12<P extends C3<P>?>(P p) {}
    class C5<T> {
      Map<T,A>? F15<A extends B, B extends T>(A a, B b) => null;
      Map<T,A>? F16<A extends T, B extends A>(A a, B b) => null;
      T? F17<A extends List<B>?, B extends Map<T,A>?>(A a, B b, T? t) => null;
      T? F18<P extends T>(
         [Q Function<Q extends P>(P, Q, T)? f1,
          X Function<X extends P>(P, X, T)? f2]) => null;
    }

    main() {
      ${createUses(existentialTypeData)}

      C1();
      C2();
      C3.fact();
      C4();

      F9(null, null);
      F10();
      F11(null);
      F12(null);
      C5<num>().F15<int, int>(1, 2);
      C5<num>().F16<int, int>(1, 2);
      C5<num>().F17(null, null, null);
      C5<num>().F18();
    }
    """));

    var types = env.types;

    testToString(DartType type, String expected) {
      Expect.equals(expected, env.printType(type));
    }

    testBounds(DartType type, List<DartType> expectedBounds) {
      FunctionType functionType = type.withoutNullabilityAs<FunctionType>();
      Expect.equals(expectedBounds.length, functionType.typeVariables.length,
          "Unexpected type variable count in ${env.printType(type)}.");
      for (int i = 0; i < expectedBounds.length; i++) {
        Expect.equals(expectedBounds[i], functionType.typeVariables[i].bound,
            "Unexpected ${i}th bound in ${env.printType(type)}.");
      }
    }

    testInstantiate(
        DartType type, List<DartType> instantiation, String expectedToString) {
      DartType result = types.instantiate(
          type.withoutNullabilityAs<FunctionType>(), instantiation);
      String resultString = env.printType(result);
      Expect.equals(
          expectedToString,
          resultString,
          "Unexpected instantiation of ${env.printType(type)} with $instantiation: "
          "$resultString");
    }

    void testSubst(List<DartType> arguments, List<DartType> parameters,
        DartType type1, String expectedToString) {
      DartType subst = types.subst(arguments, parameters, type1);
      Expect.equals(expectedToString, env.printType(subst),
          "${env.printType(type1)}.subst(${env.printTypes(arguments)},${env.printTypes(parameters)})");
    }

    testRelations(DartType a, DartType b,
        {bool areEqual = false, bool isSubtype = false}) {
      if (areEqual) {
        isSubtype = true;
      }
      String aString = env.printType(a);
      String bString = env.printType(b);
      Expect.equals(
          areEqual,
          a == b,
          "Expected `$aString` and `$bString` to be "
          "${areEqual ? 'equal' : 'non-equal'}, but they are not.");
      Expect.equals(
          isSubtype,
          env.isSubtype(a, b),
          "Expected `$aString` ${isSubtype ? '' : 'not '}to be a subtype of "
          "`$bString`, but it is${isSubtype ? ' not' : ''}.");
      if (isSubtype) {
        Expect.isTrue(env.isPotentialSubtype(a, b),
            '$aString <: $bString but not a potential subtype.');
      }
    }

    final Object_ = env['Object'] as InterfaceType;
    final nullableObject = types.nullableType(Object_);
    final num_ = env['num'] as InterfaceType;
    final int_ = env['int'] as InterfaceType;
    final C1 = env.instantiate(env.getClass('C1'), []) as InterfaceType;
    final C2 = env.instantiate(env.getClass('C2'), []) as InterfaceType;
    final C3 = env.getClass('C3');
    final C4 = env.instantiate(env.getClass('C4'), []) as InterfaceType;
    final F1 = env.getFieldType('F1');
    final F2 = env.getFieldType('F2');
    final F3 = env.getFieldType('F3');
    final F4 = env.getFieldType('F4');
    final F5 = env.getFieldType('F5');
    final F6 = env.getFieldType('F6');
    final F7 = env.getFieldType('F7');
    final F8 = env.getFieldType('F8');
    final F9 = env.getMemberType('F9') as FunctionType;
    final F10 = env.getClosureType('F10') as FunctionType;
    final F11 = env.getMemberType('F11') as FunctionType;
    final F12 = env.getMemberType('F12') as FunctionType;
    final F13 = env.getFieldType('F13');
    final F14 = env.getFieldType('F14');
    final C5 = env.getClass('C5');
    final C5_T = (env.getElementType('C5') as InterfaceType)
        .typeArguments
        .single as TypeVariableType;
    final F15 = env.getMemberType('F15', C5) as FunctionType;
    final F16 = env.getMemberType('F16', C5) as FunctionType;
    final F17 = env.getMemberType('F17', C5) as FunctionType;
    final F18 = env.getMemberType('F18', C5) as FunctionType;

    List<DartType> all = [
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
      F15,
      F16,
      F17,
      F18,
    ];

    all.forEach(print);

    List<ToStringTestData> toStringExpected = [
      ToStringTestData(F1, 'void Function<#A>(#A)'),
      ToStringTestData(F2, 'void Function<#A>(#A)'),
      ToStringTestData(F3, 'void Function<#A,#B>(#A,#B)'),
      ToStringTestData(F4, 'void Function<#A,#B>(#B,#A)'),
      ToStringTestData(F5, 'void Function<#A extends num>(#A)'),
      ToStringTestData(F6, 'void Function<#A extends int>(#A)'),
      ToStringTestData(F7, 'void Function<#A extends num>(#A,[int])'),
      ToStringTestData(F8, '#A Function<#A extends num>(#A)'),
      ToStringTestData(F9, 'void Function<#A extends #B,#B>(#A,#B)'),
      ToStringTestData(F10, 'void Function<#A extends #B,#B>(#A,#B)'),
      ToStringTestData(F11, 'void Function<#A extends C3<#A>?>(#A)'),
      ToStringTestData(F12, 'void Function<#A extends C3<#A>?>(#A)'),
      ToStringTestData(F13, '#A Function<#A>(#A,#A)'),
      ToStringTestData(F14, '#A Function<#A>(#A,#A)'),
      ToStringTestData(
          F15, 'Map<C5.T,#A>? Function<#A extends #B,#B extends C5.T>(#A,#B)'),
      ToStringTestData(
          F16, 'Map<C5.T,#A>? Function<#A extends C5.T,#B extends #A>(#A,#B)'),
      ToStringTestData(
          F17,
          'C5.T? Function<#A extends List<#B>?,'
          '#B extends Map<C5.T,#A>?>(#A,#B,Object?)'),
      ToStringTestData(
          F18,
          'C5.T? Function<#A extends C5.T>(['
          '#A2 Function<#A2 extends #A>(#A,#A2,C5.T)?,'
          '#A3 Function<#A3 extends #A>(#A,#A3,C5.T)?])'),
    ];

    for (var test in toStringExpected) {
      testToString(test.type, test.expected);
    }

    testBounds(F1, [nullableObject]);
    testBounds(F2, [nullableObject]);
    testBounds(F3, [nullableObject, nullableObject]);
    testBounds(F4, [nullableObject, nullableObject]);
    testBounds(F5, [num_]);
    testBounds(F6, [int_]);
    testBounds(F7, [num_]);
    testBounds(F8, [num_]);
    testBounds(F9, [F9.typeVariables.last, nullableObject]);
    testBounds(F10, [F10.typeVariables.last, nullableObject]);
    testBounds(F11, [
      types.nullableType(env.instantiate(C3, [F11.typeVariables.last]))
    ]);
    testBounds(F12, [
      types.nullableType(env.instantiate(C3, [F12.typeVariables.last]))
    ]);
    testBounds(F13, [nullableObject]);
    testBounds(F14, [nullableObject]);

    List<InstantiateTestData> instantiateExpected = [
      InstantiateTestData(F1, [C1], 'void Function(C1)'),
      InstantiateTestData(F2, [C2], 'void Function(C2)'),
      InstantiateTestData(F3, [C1, C2], 'void Function(C1,C2)'),
      InstantiateTestData(F4, [C1, C2], 'void Function(C2,C1)'),
      InstantiateTestData(F5, [num_], 'void Function(num)'),
      InstantiateTestData(F6, [int_], 'void Function(int)'),
      InstantiateTestData(F7, [int_], 'void Function(int,[int])'),
      InstantiateTestData(F8, [int_], 'int Function(int)'),
      InstantiateTestData(F9, [int_, num_], 'void Function(int,num)'),
      InstantiateTestData(F10, [int_, num_], 'void Function(int,num)'),
      InstantiateTestData(F11, [C4], 'void Function(C4)'),
      InstantiateTestData(F12, [C4], 'void Function(C4)'),
      InstantiateTestData(F13, [C1], 'C1 Function(C1,C1)'),
      InstantiateTestData(F14, [C2], 'C2 Function(C2,C2)'),
      InstantiateTestData(
          F15, [int_, num_], 'Map<C5.T,int>? Function(int,num)'),
      InstantiateTestData(
          F16, [num_, int_], 'Map<C5.T,num>? Function(num,int)'),
    ];

    for (var test in instantiateExpected) {
      testInstantiate(test.type, test.instantiation, test.expected);
    }

    List<SubstTestData> substExpected = [
      SubstTestData([num_], [C5_T], F15,
          'Map<num,#A>? Function<#A extends #B,#B extends num>(#A,#B)'),
      SubstTestData([num_], [C5_T], F16,
          'Map<num,#A>? Function<#A extends num,#B extends #A>(#A,#B)'),
      SubstTestData(
          [num_],
          [C5_T],
          F17,
          'num? Function<#A extends List<#B>?,'
          '#B extends Map<num,#A>?>(#A,#B,Object?)'),
      SubstTestData(
          [num_],
          [C5_T],
          F18,
          'num? Function<#A extends num>(['
          '#A2 Function<#A2 extends #A>(#A,#A2,num)?,'
          '#A3 Function<#A3 extends #A>(#A,#A3,num)?])'),
    ];

    for (var test in substExpected) {
      testSubst(test.arguments, test.parameters, test.type, test.expected);
    }

    Map<DartType, List<DartType>> expectedEquals = {
      F1: [F2],
      F2: [F1],
      F9: [F10],
      F10: [F9],
      F11: [F12],
      F12: [F11],
      F13: [F14],
      F14: [F13],
    };

    Map<DartType, List<DartType>> expectedSubtype = {
      F7: [F5],
      F8: [F5],
    };

    for (DartType f1 in all) {
      for (DartType f2 in all) {
        testRelations(f1, f2,
            areEqual: identical(f1, f2) ||
                (expectedEquals[f1]?.contains(f2) ?? false),
            isSubtype: expectedSubtype[f1]?.contains(f2) ?? false);
      }
    }

    var functionF1 = F1.withoutNullabilityAs<FunctionType>();
    var functionF2 = F2.withoutNullabilityAs<FunctionType>();
    testRelations(
        functionF1.typeVariables.first, functionF1.typeVariables.first,
        areEqual: true);
    testRelations(
        functionF1.typeVariables.first, functionF2.typeVariables.first);

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
          "${env.printTypes(functionTypeVariables)}");
    });
  });
}
