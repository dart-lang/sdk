// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
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
    void F11<Q extends C3<Q>>(Q q) {}
    void F12<P extends C3<P>>(P p) {}
    class C5<T> {
      Map<T,A> F15<A extends B, B extends T>(A a, B b) => null;
      Map<T,A> F16<A extends T, B extends A>(A a, B b) => null;
      T F17<A extends List<B>, B extends Map<T,A>>(A a, B b, T t) => null;
      T F18<P extends T>(
         [Q Function<Q extends P>(P, Q, T) f1,
          X Function<X extends P>(P, X, T) f2]) => null;
    }

    main() {
      ${createUses(existentialTypeData)}
      
      new C1();
      new C2();
      new C3.fact();
      new C4();
      
      F9(null, null);
      F10();
      F11(null);
      F12(null);
      new C5<num>().F15<int, int>(1, 2);
      new C5<num>().F16<int, int>(1, 2);
      new C5<num>().F17(null, null, null);
      new C5<num>().F18();
    }
    """));

    var types = env.types;

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
      DartType result = types.instantiate(type, instantiation);
      Expect.equals(expectedToString, result.toString(),
          "Unexpected instantiation of $type with $instantiation: $result");
    }

    void testSubst(List<DartType> arguments, List<DartType> parameters,
        DartType type1, String expectedToString) {
      DartType subst = types.subst(arguments, parameters, type1);
      Expect.equals(expectedToString, subst.toString(),
          "$type1.subst($arguments,$parameters)");
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
    InterfaceType C1 = instantiate(types, env.getClass('C1'), []);
    InterfaceType C2 = instantiate(types, env.getClass('C2'), []);
    ClassEntity C3 = env.getClass('C3');
    InterfaceType C4 = instantiate(types, env.getClass('C4'), []);
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
    ClassEntity C5 = env.getClass('C5');
    TypeVariableType C5_T =
        (env.getElementType('C5') as InterfaceType).typeArguments.single;
    FunctionType F15 = env.getMemberType('F15', C5);
    FunctionType F16 = env.getMemberType('F16', C5);
    FunctionType F17 = env.getMemberType('F17', C5);
    FunctionType F18 = env.getMemberType('F18', C5);

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
      F15,
      F16,
      F17,
      F18,
    ];

    all.forEach(print);

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
    testToString(
        F15, 'Map<C5.T,#A> Function<#A extends #B,#B extends C5.T>(#A,#B)');
    testToString(
        F16, 'Map<C5.T,#A> Function<#A extends C5.T,#B extends #A>(#A,#B)');
    testToString(F17,
        'C5.T Function<#A extends List<#B>,#B extends Map<C5.T,#A>>(#A,#B,Object)');
    testToString(
        F18,
        'C5.T Function<#A extends C5.T>(['
        '#A2 Function<#A2 extends #A>(#A,#A2,C5.T),'
        '#A3 Function<#A3 extends #A>(#A,#A3,C5.T)])');

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
      instantiate(types, C3, [F11.typeVariables.last])
    ]);
    testBounds(F12, [
      instantiate(types, C3, [F12.typeVariables.last])
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
    testInstantiate(F15, [int_, num_], 'Map<C5.T,int> Function(int,num)');
    testInstantiate(F16, [num_, int_], 'Map<C5.T,num> Function(num,int)');

    testSubst([num_], [C5_T], F15,
        'Map<num,#A> Function<#A extends #B,#B extends num>(#A,#B)');
    testSubst([num_], [C5_T], F16,
        'Map<num,#A> Function<#A extends num,#B extends #A>(#A,#B)');
    testSubst([num_], [C5_T], F17,
        'num Function<#A extends List<#B>,#B extends Map<num,#A>>(#A,#B,Object)');

    testSubst(
        [num_],
        [C5_T],
        F18,
        'num Function<#A extends num>(['
        '#A2 Function<#A2 extends #A>(#A,#A2,num),'
        '#A3 Function<#A3 extends #A>(#A,#A3,num)])');
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
