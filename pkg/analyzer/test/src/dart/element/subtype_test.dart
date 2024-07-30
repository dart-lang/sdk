// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    show Variance;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/type_system_base.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeTest);
    defineReflectiveTests(SubtypingCompoundTest);
  });
}

@reflectiveTest
class SubtypeTest extends _SubtypingTestBase with StringTypes {
  void isNotSubtype(
    DartType T0,
    DartType T1, {
    String? strT0,
    String? strT1,
  }) {
    assertExpectedString(T0, strT0);
    assertExpectedString(T1, strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isFalse);
  }

  void isNotSubtype2(
    String strT0,
    String strT1,
  ) {
    var T0 = typeOfString(strT0);
    var T1 = typeOfString(strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isFalse);
  }

  void isNotSubtype3({
    required String strT0,
    required String strT1,
  }) {
    isNotSubtype2(strT0, strT1);
  }

  void isSubtype(
    DartType T0,
    DartType T1, {
    String? strT0,
    String? strT1,
  }) {
    assertExpectedString(T0, strT0);
    assertExpectedString(T1, strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isTrue);
  }

  void isSubtype2(
    String strT0,
    String strT1,
  ) {
    var T0 = typeOfString(strT0);
    var T1 = typeOfString(strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isTrue);
  }

  @override
  void setUp() {
    super.setUp();
    defineStringTypes();
  }

  test_extensionType_implementsNotNullable() {
    var element = extensionType(
      'A',
      representationType: intNone,
      interfaces: [intNone],
    );
    var type = interfaceTypeNone(element);

    isSubtype(type, objectQuestion);
    isSubtype(type, objectNone);
    isSubtype(type, intNone);
    isSubtype(type, numNone);
    isSubtype(neverNone, type);
  }

  test_extensionType_noImplementedInterfaces() {
    var element = extensionType('A', representationType: intNone);
    var type = interfaceTypeNone(element);

    isSubtype(type, objectQuestion);
    isNotSubtype(type, objectNone);
    isNotSubtype(type, intNone);
  }

  test_extensionType_superinterfaces() {
    var A = class_(name: 'A');
    var B = class_(name: 'B');

    var element = extensionType(
      'X',
      representationType: intNone,
      interfaces: [
        interfaceTypeNone(A),
      ],
    );
    var type = interfaceTypeNone(element);

    isSubtype(type, interfaceTypeNone(A));
    isNotSubtype(type, interfaceTypeNone(B));
  }

  test_extensionType_typeArguments() {
    var A = extensionType(
      'A',
      representationType: intNone,
      typeParameters: [
        typeParameter('T'),
      ],
    );

    var A_object = interfaceTypeNone(
      A,
      typeArguments: [objectNone],
    );

    var A_int = interfaceTypeNone(
      A,
      typeArguments: [intNone],
    );

    var A_num = interfaceTypeNone(
      A,
      typeArguments: [numNone],
    );

    isSubtype(A_int, A_num);
    isSubtype(A_int, A_object);
    isNotSubtype(A_num, A_int);
  }

  test_functionType_01() {
    var E0 = typeParameter('E0');
    var E1 = typeParameter('E1', bound: numNone);

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numNone),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0>(E0, num)',
      strT1: 'E1 Function<E1 extends num>(E1, E1)',
    );
  }

  test_functionType_02() {
    var E0 = typeParameter('E0', bound: numNone);
    var E1 = typeParameter('E1', bound: intNone);

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: intNone,
      ),
      strT0: 'int Function<E0 extends num>(E0)',
      strT1: 'int Function<E1 extends int>(E1)',
    );
  }

  test_functionType_03() {
    var E0 = typeParameter('E0', bound: numNone);
    var E1 = typeParameter('E1', bound: intNone);

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0 extends num>(E0)',
      strT1: 'E1 Function<E1 extends int>(E1)',
    );
  }

  test_functionType_04() {
    var E0 = typeParameter('E0', bound: numNone);
    var E1 = typeParameter('E1', bound: intNone);

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0 extends num>(int)',
      strT1: 'E1 Function<E1 extends int>(int)',
    );
  }

  test_functionType_05() {
    var E0 = typeParameter('E0', bound: numNone);
    var E1 = typeParameter('E1', bound: numNone);

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: numNone,
      ),
      strT0: 'E0 Function<E0 extends num>(E0)',
      strT1: 'num Function<E1 extends num>(E1)',
    );
  }

  test_functionType_06() {
    var E0 = typeParameter('E0', bound: intNone);
    var E1 = typeParameter('E1', bound: intNone);

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: numNone,
      ),
      strT0: 'E0 Function<E0 extends int>(E0)',
      strT1: 'num Function<E1 extends int>(E1)',
    );
  }

  test_functionType_07() {
    var E0 = typeParameter('E0', bound: intNone);
    var E1 = typeParameter('E1', bound: intNone);

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: intNone,
      ),
      strT0: 'E0 Function<E0 extends int>(E0)',
      strT1: 'int Function<E1 extends int>(E1)',
    );
  }

  test_functionType_08() {
    var E0 = typeParameter('E0');

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      strT0: 'int Function<E0>(int)',
      strT1: 'int Function(int)',
    );
  }

  test_functionType_09() {
    var E0 = typeParameter('E0');
    var F0 = typeParameter('F0');
    var E1 = typeParameter('E1');

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      strT0: 'int Function<E0, F0>(int)',
      strT1: 'int Function<E1>(int)',
    );
  }

  test_functionType_10() {
    var E0 = typeParameter('E0');
    E0.bound = listNone(
      typeParameterTypeNone(E0),
    );

    var E1 = typeParameter('E1');
    E1.bound = listNone(
      typeParameterTypeNone(E1),
    );

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0 extends List<E0>>(E0)',
      strT1: 'E1 Function<E1 extends List<E1>>(E1)',
    );
  }

  test_functionType_11() {
    var E0 = typeParameter('E0');
    E0.bound = iterableNone(
      typeParameterTypeNone(E0),
    );

    var E1 = typeParameter('E1');
    E1.bound = listNone(
      typeParameterTypeNone(E1),
    );

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0 extends Iterable<E0>>(E0)',
      strT1: 'E1 Function<E1 extends List<E1>>(E1)',
    );
  }

  test_functionType_12() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listNone(
      typeParameterTypeNone(E1),
    );

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listNone(objectNone)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0>(E0, List<Object>)',
      strT1: 'E1 Function<E1 extends List<E1>>(E1, E1)',
    );
  }

  test_functionType_13() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listNone(
      typeParameterTypeNone(E1),
    );

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listNone(objectNone)),
        ],
        returnType: listNone(
          typeParameterTypeNone(E0),
        ),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'List<E0> Function<E0>(E0, List<Object>)',
      strT1: 'E1 Function<E1 extends List<E1>>(E1, E1)',
    );
  }

  test_functionType_14() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listNone(
      typeParameterTypeNone(E1),
    );

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listNone(objectNone)),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'int Function<E0>(E0, List<Object>)',
      strT1: 'E1 Function<E1 extends List<E1>>(E1, E1)',
    );
  }

  test_functionType_15() {
    var E0 = typeParameter('E0');

    var E1 = typeParameter('E1');
    E1.bound = listNone(
      typeParameterTypeNone(E1),
    );

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: listNone(objectNone)),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: voidNone,
      ),
      strT0: 'E0 Function<E0>(E0, List<Object>)',
      strT1: 'void Function<E1 extends List<E1>>(E1, E1)',
    );
  }

  test_functionType_16() {
    isSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      functionNone,
      strT0: 'int Function()',
      strT1: 'Function',
    );
  }

  test_functionType_17() {
    isNotSubtype(
      functionNone,
      functionTypeNone(
        returnType: intNone,
      ),
      strT0: 'Function',
      strT1: 'int Function()',
    );
  }

  test_functionType_18() {
    isSubtype(
      functionTypeNone(
        returnType: dynamicType,
      ),
      functionTypeNone(
        returnType: dynamicType,
      ),
      strT0: 'dynamic Function()',
      strT1: 'dynamic Function()',
    );
  }

  test_functionType_19() {
    isSubtype(
      functionTypeNone(
        returnType: dynamicType,
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'dynamic Function()',
      strT1: 'void Function()',
    );
  }

  test_functionType_20() {
    isSubtype(
      functionTypeNone(
        returnType: voidNone,
      ),
      functionTypeNone(
        returnType: dynamicType,
      ),
      strT0: 'void Function()',
      strT1: 'dynamic Function()',
    );
  }

  test_functionType_21() {
    isSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'int Function()',
      strT1: 'void Function()',
    );
  }

  test_functionType_22() {
    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
      ),
      functionTypeNone(
        returnType: intNone,
      ),
      strT0: 'void Function()',
      strT1: 'int Function()',
    );
  }

  test_functionType_23() {
    isSubtype(
      functionTypeNone(
        returnType: voidNone,
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'void Function()',
      strT1: 'void Function()',
    );
  }

  test_functionType_24() {
    isSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      functionTypeNone(
        returnType: intNone,
      ),
      strT0: 'int Function()',
      strT1: 'int Function()',
    );
  }

  test_functionType_25() {
    isSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      functionTypeNone(
        returnType: objectNone,
      ),
      strT0: 'int Function()',
      strT1: 'Object Function()',
    );
  }

  test_functionType_26() {
    isNotSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      functionTypeNone(
        returnType: doubleNone,
      ),
      strT0: 'int Function()',
      strT1: 'double Function()',
    );
  }

  test_functionType_27() {
    isNotSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'int Function()',
      strT1: 'void Function(int)',
    );
  }

  test_functionType_28() {
    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      strT0: 'void Function()',
      strT1: 'int Function(int)',
    );
  }

  test_functionType_29() {
    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function()',
      strT1: 'void Function(int)',
    );
  }

  test_functionType_30() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      strT0: 'int Function(int)',
      strT1: 'int Function(int)',
    );
  }

  test_functionType_31() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: objectNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: objectNone,
      ),
      strT0: 'int Function(Object)',
      strT1: 'Object Function(int)',
    );
  }

  test_functionType_32() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: doubleNone),
        ],
        returnType: intNone,
      ),
      strT0: 'int Function(int)',
      strT1: 'int Function(double)',
    );
  }

  test_functionType_33() {
    isNotSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      strT0: 'int Function()',
      strT1: 'int Function(int)',
    );
  }

  test_functionType_34() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      strT0: 'int Function(int)',
      strT1: 'int Function(int, int)',
    );
  }

  test_functionType_35() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      strT0: 'int Function(int, int)',
      strT1: 'int Function(int)',
    );
  }

  test_functionType_36() {
    var f = functionTypeNone(
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    var g = functionTypeNone(
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: intNone),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );

    isNotSubtype(
      f,
      g,
      strT0: 'void Function(void Function())',
      strT1: 'void Function(void Function(int))',
    );

    isNotSubtype(
      g,
      f,
      strT0: 'void Function(void Function(int))',
      strT1: 'void Function(void Function())',
    );
  }

  test_functionType_37() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'void Function([int])',
      strT1: 'void Function()',
    );
  }

  test_functionType_38() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int])',
      strT1: 'void Function(int)',
    );
  }

  test_functionType_39() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int)',
      strT1: 'void Function([int])',
    );
  }

  test_functionType_40() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int])',
      strT1: 'void Function([int])',
    );
  }

  test_functionType_41() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: objectNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([Object])',
      strT1: 'void Function([int])',
    );
  }

  test_functionType_42() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          positionalParameter(type: objectNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int])',
      strT1: 'void Function([Object])',
    );
  }

  test_functionType_43() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int, [int])',
      strT1: 'void Function(int)',
    );
  }

  test_functionType_44() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int, [int])',
      strT1: 'void Function(int, [int])',
    );
  }

  test_functionType_45() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int, int])',
      strT1: 'void Function(int)',
    );
  }

  test_functionType_46() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int, int])',
      strT1: 'void Function(int, [int])',
    );
  }

  test_functionType_47() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int, int])',
      strT1: 'void Function(int, [int, int])',
    );
  }

  test_functionType_48() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int, int, int])',
      strT1: 'void Function(int, [int, int])',
    );
  }

  test_functionType_49() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: doubleNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int])',
      strT1: 'void Function(double)',
    );
  }

  test_functionType_50() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int])',
      strT1: 'void Function([int, int])',
    );
  }

  test_functionType_51() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([int, int])',
      strT1: 'void Function([int])',
    );
  }

  test_functionType_52() {
    isSubtype(
      functionTypeNone(
        parameters: [
          positionalParameter(type: objectNone),
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          positionalParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function([Object, int])',
      strT1: 'void Function([int])',
    );
  }

  test_functionType_53() {
    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'void Function({int a})',
      strT1: 'void Function()',
    );
  }

  test_functionType_54() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a})',
      strT1: 'void Function(int)',
    );
  }

  test_functionType_55() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int)',
      strT1: 'void Function({int a})',
    );
  }

  test_functionType_56() {
    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a})',
      strT1: 'void Function({int a})',
    );
  }

  test_functionType_57() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'b', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a})',
      strT1: 'void Function({int b})',
    );
  }

  test_functionType_58() {
    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: objectNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({Object a})',
      strT1: 'void Function({int a})',
    );
  }

  test_functionType_59() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: objectNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a})',
      strT1: 'void Function({Object a})',
    );
  }

  test_functionType_60() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function(int, {int a})',
      strT1: 'void Function(int, {int a})',
    );
  }

  test_functionType_61() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: doubleNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a})',
      strT1: 'void Function({double a})',
    );
  }

  test_functionType_62() {
    isNotSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a})',
      strT1: 'void Function({int a, int b})',
    );
  }

  test_functionType_63() {
    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a, int b})',
      strT1: 'void Function({int a})',
    );
  }

  test_functionType_64() {
    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: intNone),
          namedParameter(name: 'c', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedParameter(name: 'c', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a, int b, int c})',
      strT1: 'void Function({int a, int c})',
    );
  }

  test_functionType_66() {
    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: intNone),
          namedParameter(name: 'c', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'b', type: intNone),
          namedParameter(name: 'c', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a, int b, int c})',
      strT1: 'void Function({int b, int c})',
    );
  }

  test_functionType_68() {
    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: intNone),
          namedParameter(name: 'c', type: intNone),
        ],
        returnType: voidNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'c', type: intNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'void Function({int a, int b, int c})',
      strT1: 'void Function({int c})',
    );
  }

  test_functionType_70() {
    isSubtype(
      functionTypeNone(
        returnType: numNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      objectNone,
      strT0: 'num Function(int)',
      strT1: 'Object',
    );
  }

  test_functionType_71() {
    isSubtype(
      functionTypeNone(
        returnType: numNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      objectNone,
      strT0: 'num Function(int)',
      strT1: 'Object',
    );
  }

  test_functionType_72() {
    isNotSubtype(
      functionTypeQuestion(
        returnType: numNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      objectNone,
      strT0: 'num Function(int)?',
      strT1: 'Object',
    );
  }

  test_functionType_73() {
    var E0 = typeParameter('E0', bound: objectNone);
    var E1 = typeParameter('E1', bound: futureOrNone(objectNone));

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        returnType: voidNone,
      ),
      functionTypeNone(
        typeFormals: [E1],
        returnType: voidNone,
      ),
      strT0: 'void Function<E0 extends Object>()',
      strT1: 'void Function<E1 extends FutureOr<Object>>()',
    );
  }

  test_functionType_74() {
    var T1 = typeParameter('T');
    var R1 = typeParameter(
      'R',
      bound: typeParameterType(
        T1,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );

    var T2 = typeParameter('T');
    var R2 = typeParameter(
      'R',
      bound: typeParameterType(
        T2,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );

    // Note, the order `R extends T`, then `T` is important.
    // We test that all type parameters replaced at once, not as we go.
    isSubtype(
      functionTypeNone(
        typeFormals: [R1, T1],
        returnType: voidNone,
      ),
      functionTypeNone(
        typeFormals: [R2, T2],
        returnType: voidNone,
      ),
      strT0: 'void Function<R extends T, T>()',
      strT1: 'void Function<R extends T, T>()',
    );
  }

  test_functionType_generic_nested() {
    var E0 = typeParameter('E0');
    var F0 = typeParameter('F0');
    var E1 = typeParameter('E1');
    var F1 = typeParameter('F1');

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(E0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeNone(
        typeFormals: [F1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(F1)),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(F1),
        ),
      ),
      strT0: 'E0 Function(E0) Function<E0>(E0)',
      strT1: 'F1 Function(F1) Function<F1>(F1)',
    );

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(
            type: functionTypeNone(
              parameters: [
                requiredParameter(type: intNone),
                requiredParameter(type: typeParameterTypeNone(E0)),
              ],
              returnType: typeParameterTypeNone(E0),
            ),
          ),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(
            type: functionTypeNone(
              parameters: [
                requiredParameter(type: numNone),
                requiredParameter(type: typeParameterTypeNone(E1)),
              ],
              returnType: typeParameterTypeNone(E1),
            ),
          ),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E0 Function<E0>(E0, E0 Function(int, E0))',
      strT1: 'E1 Function<E1>(E1, E1 Function(num, E1))',
    );

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: functionTypeNone(
          typeFormals: [F1],
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(E1),
        ),
      ),
      strT0: 'E0 Function(F0) Function<E0, F0>(E0)',
      strT1: 'E1 Function<F1>(F1) Function<E1>(E1)',
    );

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0, F0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F0)),
          ],
          returnType: typeParameterTypeNone(E0),
        ),
      ),
      functionTypeNone(
        typeFormals: [F1, E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: typeParameterTypeNone(F1)),
          ],
          returnType: typeParameterTypeNone(E1),
        ),
      ),
      strT0: 'E0 Function(F0) Function<E0, F0>(E0)',
      strT1: 'E1 Function(F1) Function<F1, E1>(E1)',
    );
  }

  test_functionType_generic_required() {
    var E0 = typeParameter('E');
    var E1 = typeParameter('E');

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: numNone,
      ),
      strT0: 'int Function<E>(E)',
      strT1: 'num Function<E>(E)',
    );

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(num)',
      strT1: 'E Function<E>(int)',
    );

    isSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numNone),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: intNone),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(E, num)',
      strT1: 'E Function<E>(E, int)',
    );

    isNotSubtype(
      functionTypeNone(
        typeFormals: [E0],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E0)),
          requiredParameter(type: numNone),
        ],
        returnType: typeParameterTypeNone(E0),
      ),
      functionTypeNone(
        typeFormals: [E1],
        parameters: [
          requiredParameter(type: typeParameterTypeNone(E1)),
          requiredParameter(type: typeParameterTypeNone(E1)),
        ],
        returnType: typeParameterTypeNone(E1),
      ),
      strT0: 'E Function<E>(E, num)',
      strT1: 'E Function<E>(E, E)',
    );
  }

  test_functionType_notGeneric_functionReturnType() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: numNone,
        ),
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: intNone),
          ],
          returnType: numNone,
        ),
      ),
      strT0: 'num Function(num) Function(num)',
      strT1: 'num Function(int) Function(num)',
    );

    isNotSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: intNone),
          ],
          returnType: intNone,
        ),
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: functionTypeNone(
          parameters: [
            requiredParameter(type: numNone),
          ],
          returnType: numNone,
        ),
      ),
      strT0: 'int Function(int) Function(int)',
      strT1: 'num Function(num) Function(num)',
    );
  }

  test_functionType_notGeneric_named() {
    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'x', type: numNone),
        ],
        returnType: numNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'x', type: intNone),
        ],
        returnType: numNone,
      ),
      strT0: 'num Function({num x})',
      strT1: 'num Function({int x})',
    );

    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
          namedParameter(name: 'x', type: numNone),
        ],
        returnType: numNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
          namedParameter(name: 'x', type: intNone),
        ],
        returnType: numNone,
      ),
      strT0: 'num Function(num, {num x})',
      strT1: 'num Function(int, {int x})',
    );

    isSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'x', type: numNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'x', type: numNone),
        ],
        returnType: numNone,
      ),
      strT0: 'int Function({num x})',
      strT1: 'num Function({num x})',
    );

    isNotSubtype(
      functionTypeNone(
        parameters: [
          namedParameter(name: 'x', type: intNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          namedParameter(name: 'x', type: numNone),
        ],
        returnType: numNone,
      ),
      strT0: 'int Function({int x})',
      strT1: 'num Function({num x})',
    );
  }

  test_functionType_notGeneric_required() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: numNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: numNone,
      ),
      strT0: 'num Function(num)',
      strT1: 'num Function(int)',
    );

    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: numNone,
      ),
      strT0: 'int Function(num)',
      strT1: 'num Function(num)',
    );

    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: numNone,
      ),
      strT0: 'int Function(num)',
      strT1: 'num Function(int)',
    );

    isNotSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: numNone),
        ],
        returnType: numNone,
      ),
      strT0: 'int Function(int)',
      strT1: 'num Function(num)',
    );

    isSubtype(
      nullQuestion,
      functionTypeQuestion(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: numNone,
      ),
      strT0: 'Null?',
      strT1: 'num Function(int)?',
    );
  }

  test_functionType_requiredNamedParameter_01() {
    var F0 = functionTypeNone(
      returnType: voidNone,
      parameters: [
        namedRequiredParameter(name: 'a', type: intNone),
      ],
    );

    var F1 = functionTypeNone(
      returnType: voidNone,
      parameters: [
        namedParameter(name: 'a', type: intNone),
      ],
    );

    isSubtype(
      F1,
      F0,
      strT0: 'void Function({int a})',
      strT1: 'void Function({required int a})',
    );

    isNotSubtype(
      F0,
      F1,
      strT0: 'void Function({required int a})',
      strT1: 'void Function({int a})',
    );
  }

  test_functionType_requiredNamedParameter_02() {
    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'void Function({required int a})',
      strT1: 'void Function()',
    );

    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
          namedParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'b', type: intNone),
        ],
      ),
      strT0: 'void Function({required int a, int b})',
      strT1: 'void Function({int b})',
    );
  }

  test_functionType_requiredNamedParameter_03() {
    var F0 = functionTypeNone(
      returnType: voidNone,
      parameters: [
        namedParameter(name: 'a', type: intQuestion),
      ],
    );

    var F1 = functionTypeNone(
      returnType: voidNone,
      parameters: [
        namedRequiredParameter(name: 'a', type: intNone),
      ],
    );

    isSubtype(
      F0,
      F1,
      strT0: 'void Function({int? a})',
      strT1: 'void Function({required int a})',
    );

    isNotSubtype(
      F1,
      F0,
      strT0: 'void Function({required int a})',
      strT1: 'void Function({int? a})',
    );
  }

  test_futureOr_01() {
    isSubtype(
      intNone,
      futureOrNone(intNone),
      strT0: 'int',
      strT1: 'FutureOr<int>',
    );
  }

  test_futureOr_02() {
    isSubtype(
      intNone,
      futureOrNone(numNone),
      strT0: 'int',
      strT1: 'FutureOr<num>',
    );
  }

  test_futureOr_03() {
    isSubtype(
      futureNone(intNone),
      futureOrNone(intNone),
      strT0: 'Future<int>',
      strT1: 'FutureOr<int>',
    );
  }

  test_futureOr_04() {
    isSubtype(
      futureNone(intNone),
      futureOrNone(numNone),
      strT0: 'Future<int>',
      strT1: 'FutureOr<num>',
    );
  }

  test_futureOr_05() {
    isSubtype(
      futureNone(intNone),
      futureOrNone(objectNone),
      strT0: 'Future<int>',
      strT1: 'FutureOr<Object>',
    );
  }

  test_futureOr_06() {
    isSubtype(
      futureOrNone(intNone),
      futureOrNone(intNone),
      strT0: 'FutureOr<int>',
      strT1: 'FutureOr<int>',
    );
  }

  test_futureOr_07() {
    isSubtype(
      futureOrNone(intNone),
      futureOrNone(numNone),
      strT0: 'FutureOr<int>',
      strT1: 'FutureOr<num>',
    );
  }

  test_futureOr_08() {
    isSubtype(
      futureOrNone(intNone),
      objectNone,
      strT0: 'FutureOr<int>',
      strT1: 'Object',
    );
  }

  test_futureOr_09() {
    isNotSubtype(
      intNone,
      futureOrNone(doubleNone),
      strT0: 'int',
      strT1: 'FutureOr<double>',
    );
  }

  test_futureOr_10() {
    isNotSubtype(
      futureOrNone(doubleNone),
      intNone,
      strT0: 'FutureOr<double>',
      strT1: 'int',
    );
  }

  test_futureOr_11() {
    isNotSubtype(
      futureOrNone(intNone),
      futureNone(numNone),
      strT0: 'FutureOr<int>',
      strT1: 'Future<num>',
    );
  }

  test_futureOr_12() {
    isNotSubtype(
      futureOrNone(intNone),
      numNone,
      strT0: 'FutureOr<int>',
      strT1: 'num',
    );
  }

  test_futureOr_13() {
    isNotSubtype(
      nullQuestion,
      futureOrNone(intNone),
      strT0: 'Null?',
      strT1: 'FutureOr<int>',
    );
  }

  test_futureOr_14() {
    isSubtype(
      nullQuestion,
      futureQuestion(intNone),
      strT0: 'Null?',
      strT1: 'Future<int>?',
    );
  }

  test_futureOr_15() {
    isSubtype(
      dynamicType,
      futureOrNone(dynamicType),
      strT0: 'dynamic',
      strT1: 'FutureOr<dynamic>',
    );
  }

  test_futureOr_16() {
    isNotSubtype(
      dynamicType,
      futureOrNone(stringNone),
      strT0: 'dynamic',
      strT1: 'FutureOr<String>',
    );
  }

  test_futureOr_17() {
    isSubtype(
      voidNone,
      futureOrNone(voidNone),
      strT0: 'void',
      strT1: 'FutureOr<void>',
    );
  }

  test_futureOr_18() {
    isNotSubtype(
      voidNone,
      futureOrNone(stringNone),
      strT0: 'void',
      strT1: 'FutureOr<String>',
    );
  }

  test_futureOr_19() {
    var E = typeParameter('E');

    isSubtype(
      typeParameterTypeNone(E),
      futureOrNone(
        typeParameterTypeNone(E),
      ),
      strT0: 'E',
      strT1: 'FutureOr<E>',
    );
  }

  test_futureOr_20() {
    var E = typeParameter('E');

    isNotSubtype(
      typeParameterTypeNone(E),
      futureOrNone(stringNone),
      strT0: 'E',
      strT1: 'FutureOr<String>',
    );
  }

  test_futureOr_21() {
    isSubtype(
      functionTypeNone(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()',
      strT1: 'FutureOr<void Function()>',
    );
  }

  test_futureOr_22() {
    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
      ),
      futureOrNone(
        functionTypeNone(
          returnType: stringNone,
        ),
      ),
      strT0: 'void Function()',
      strT1: 'FutureOr<String Function()>',
    );
  }

  test_futureOr_23() {
    isNotSubtype(
      futureOrNone(numNone),
      futureOrNone(intNone),
      strT0: 'FutureOr<num>',
      strT1: 'FutureOr<int>',
    );
  }

  test_futureOr_24() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numNone),
      strT0: 'T & int',
      strT1: 'FutureOr<num>',
    );
  }

  test_futureOr_25() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(numNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<num>',
      strT1: 'FutureOr<num>',
    );
  }

  test_futureOr_26() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<int>',
      strT1: 'FutureOr<num>',
    );
  }

  test_futureOr_27() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, numNone),
      futureOrNone(intNone),
      strT0: 'T & num',
      strT1: 'FutureOr<int>',
    );
  }

  test_futureOr_28() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureNone(numNone)),
      futureOrNone(intNone),
      strT0: 'T & Future<num>',
      strT1: 'FutureOr<int>',
    );
  }

  test_futureOr_29() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureOrNone(numNone)),
      futureOrNone(intNone),
      strT0: 'T & FutureOr<num>',
      strT1: 'FutureOr<int>',
    );
  }

  test_futureOr_30() {
    isSubtype(
      futureOrNone(objectNone),
      futureOrNone(
        futureOrNone(objectNone),
      ),
      strT0: 'FutureOr<Object>',
      strT1: 'FutureOr<FutureOr<Object>>',
    );
  }

  test_interfaceType_01() {
    isSubtype(intNone, intNone, strT0: 'int', strT1: 'int');
  }

  test_interfaceType_02() {
    isSubtype(intNone, numNone, strT0: 'int', strT1: 'num');
  }

  test_interfaceType_03() {
    isSubtype(
      intNone,
      comparableNone(numNone),
      strT0: 'int',
      strT1: 'Comparable<num>',
    );
  }

  test_interfaceType_04() {
    isSubtype(intNone, objectNone, strT0: 'int', strT1: 'Object');
  }

  test_interfaceType_05() {
    isSubtype(doubleNone, numNone, strT0: 'double', strT1: 'num');
  }

  test_interfaceType_06() {
    isNotSubtype(intNone, doubleNone, strT0: 'int', strT1: 'double');
  }

  test_interfaceType_07() {
    isNotSubtype(
      intNone,
      comparableNone(intNone),
      strT0: 'int',
      strT1: 'Comparable<int>',
    );
  }

  test_interfaceType_08() {
    isNotSubtype(
      intNone,
      iterableNone(intNone),
      strT0: 'int',
      strT1: 'Iterable<int>',
    );
  }

  test_interfaceType_09() {
    isNotSubtype(
      comparableNone(intNone),
      iterableNone(intNone),
      strT0: 'Comparable<int>',
      strT1: 'Iterable<int>',
    );
  }

  test_interfaceType_10() {
    isSubtype(
      listNone(intNone),
      listNone(intNone),
      strT0: 'List<int>',
      strT1: 'List<int>',
    );
  }

  test_interfaceType_11() {
    isSubtype(
      listNone(intNone),
      iterableNone(intNone),
      strT0: 'List<int>',
      strT1: 'Iterable<int>',
    );
  }

  test_interfaceType_12() {
    isSubtype(
      listNone(intNone),
      listNone(numNone),
      strT0: 'List<int>',
      strT1: 'List<num>',
    );
  }

  test_interfaceType_13() {
    isSubtype(
      listNone(intNone),
      iterableNone(numNone),
      strT0: 'List<int>',
      strT1: 'Iterable<num>',
    );
  }

  test_interfaceType_14() {
    isSubtype(
      listNone(intNone),
      listNone(objectNone),
      strT0: 'List<int>',
      strT1: 'List<Object>',
    );
  }

  test_interfaceType_15() {
    isSubtype(
      listNone(intNone),
      iterableNone(objectNone),
      strT0: 'List<int>',
      strT1: 'Iterable<Object>',
    );
  }

  test_interfaceType_16() {
    isSubtype(
      listNone(intNone),
      objectNone,
      strT0: 'List<int>',
      strT1: 'Object',
    );
  }

  test_interfaceType_17() {
    isSubtype(
      listNone(intNone),
      listNone(
        comparableNone(objectNone),
      ),
      strT0: 'List<int>',
      strT1: 'List<Comparable<Object>>',
    );
  }

  test_interfaceType_18() {
    isSubtype(
      listNone(intNone),
      listNone(
        comparableNone(numNone),
      ),
      strT0: 'List<int>',
      strT1: 'List<Comparable<num>>',
    );
  }

  test_interfaceType_19() {
    isSubtype(
      listNone(intNone),
      listNone(
        comparableNone(
          comparableNone(numNone),
        ),
      ),
      strT0: 'List<int>',
      strT1: 'List<Comparable<Comparable<num>>>',
    );
  }

  test_interfaceType_20() {
    isNotSubtype(
      listNone(intNone),
      listNone(doubleNone),
      strT0: 'List<int>',
      strT1: 'List<double>',
    );
  }

  test_interfaceType_21() {
    isNotSubtype(
      listNone(intNone),
      iterableNone(doubleNone),
      strT0: 'List<int>',
      strT1: 'Iterable<double>',
    );
  }

  test_interfaceType_22() {
    isNotSubtype(
      listNone(intNone),
      comparableNone(intNone),
      strT0: 'List<int>',
      strT1: 'Comparable<int>',
    );
  }

  test_interfaceType_23() {
    isNotSubtype(
      listNone(intNone),
      listNone(
        comparableNone(intNone),
      ),
      strT0: 'List<int>',
      strT1: 'List<Comparable<int>>',
    );
  }

  test_interfaceType_24() {
    isNotSubtype(
      listNone(intNone),
      listNone(
        comparableNone(
          comparableNone(intNone),
        ),
      ),
      strT0: 'List<int>',
      strT1: 'List<Comparable<Comparable<int>>>',
    );
  }

  test_interfaceType_25_interfaces() {
    var A = class_(name: 'A');
    var I = class_(name: 'I');

    A.interfaces = [
      I.instantiate(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    ];

    var A_none = A.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var I_none = I.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_none, I_none, strT0: 'A', strT1: 'I');
    isNotSubtype(I_none, A_none, strT0: 'I', strT1: 'A');
  }

  test_interfaceType_26_mixins() {
    var A = class_(name: 'A');
    var M = class_(name: 'M');

    A.mixins = [
      M.instantiate(
        typeArguments: const [],
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    ];

    var A_none = A.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var M_none = M.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_none, M_none, strT0: 'A', strT1: 'M');
    isNotSubtype(M_none, A_none, strT0: 'M', strT1: 'A');
  }

  test_interfaceType_27() {
    isSubtype(numNone, objectNone, strT0: 'num', strT1: 'Object');
  }

  test_interfaceType_28() {
    isSubtype(numNone, objectNone, strT0: 'num', strT1: 'Object');
  }

  test_interfaceType_39() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      listNone(
        promotedTypeParameterTypeNone(T, intNone),
      ),
      listNone(
        typeParameterTypeNone(T),
      ),
      strT0: 'List<T & int>, T extends Object?',
      strT1: 'List<T>, T extends Object?',
    );
  }

  test_interfaceType_40() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      listNone(
        promotedTypeParameterTypeNone(T, intQuestion),
      ),
      listNone(
        typeParameterTypeNone(T),
      ),
      strT0: 'List<T & int?>, T extends Object?',
      strT1: 'List<T>, T extends Object?',
    );
  }

  test_interfaceType_class_augmented_interfaces() {
    var A = class_(name: 'A');
    var I = class_(name: 'I');

    var A1 = class_(
      name: 'A',
      isAugmentation: true,
      interfaces: [
        interfaceTypeNone(I),
      ],
    );
    A.addAugmentations([A1]);

    var A_none = interfaceTypeNone(A);
    var I_none = interfaceTypeNone(I);

    isSubtype(A_none, I_none, strT0: 'A', strT1: 'I');
    isNotSubtype(I_none, A_none, strT0: 'I', strT1: 'A');
  }

  test_interfaceType_class_augmented_mixins() {
    var A = class_(name: 'A');
    var M = mixin_(name: 'M');

    var A1 = class_(
      name: 'A',
      isAugmentation: true,
      mixins: [
        interfaceTypeNone(M),
      ],
    );
    A.addAugmentations([A1]);

    var A_none = interfaceTypeNone(A);
    var M_none = interfaceTypeNone(M);

    isSubtype(A_none, M_none, strT0: 'A', strT1: 'M');
    isNotSubtype(M_none, A_none, strT0: 'M', strT1: 'A');
  }

  test_interfaceType_contravariant() {
    var T = typeParameter('T', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T]);

    var A_num = A.instantiate(
      typeArguments: [numNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
  }

  test_interfaceType_covariant() {
    var T = typeParameter('T', variance: Variance.covariant);
    var A = class_(name: 'A', typeParameters: [T]);

    var A_num = A.instantiate(
      typeArguments: [numNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
  }

  test_interfaceType_invariant() {
    var T = typeParameter('T', variance: Variance.invariant);
    var A = class_(name: 'A', typeParameters: [T]);

    var A_num = A.instantiate(
      typeArguments: [numNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
    isNotSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
  }

  test_interfaceType_mixin_augmented_interfaces() {
    var M = mixin_(name: 'M');
    var I = class_(name: 'I');

    var M1 = mixin_(
      name: 'M1',
      isAugmentation: true,
      interfaces: [
        interfaceTypeNone(I),
      ],
    );
    M.addAugmentations([M1]);

    var M_none = interfaceTypeNone(M);
    var I_none = interfaceTypeNone(I);

    isSubtype(M_none, I_none, strT0: 'M', strT1: 'I');
    isNotSubtype(I_none, M_none, strT0: 'I', strT1: 'M');
  }

  test_interfaceType_mixin_augmented_superclassConstraints() {
    var M = mixin_(name: 'M');
    var C = class_(name: 'C');

    var M1 = mixin_(
      name: 'M1',
      isAugmentation: true,
      constraints: [
        interfaceTypeNone(C),
      ],
    );
    M.addAugmentations([M1]);

    var M_none = interfaceTypeNone(M);
    var C_none = interfaceTypeNone(C);

    isSubtype(M_none, C_none, strT0: 'M', strT1: 'C');
    isNotSubtype(C_none, M_none, strT0: 'C', strT1: 'M');
  }

  test_invalidType() {
    isSubtype2('InvalidType', 'int');
    isSubtype2('int', 'InvalidType');
  }

  test_multi_function_nonGeneric_oneArgument() {
    isSubtype2('num Function(num)', 'num Function(int)');
    isSubtype2('int Function(num)', 'num Function(num)');
    isSubtype2('int Function(num)', 'num Function(int)');

    isNotSubtype2('int Function(int)', 'num Function(num)');

    isNotSubtype2('Null?', 'num Function(int)');
    isSubtype2('Null?', 'num Function(int)?');

    isSubtype2('Never', 'num Function(int)');
    isSubtype2('Never', 'num Function(int)?');
    isNotSubtype2('num Function(int)', 'Never');

    isSubtype2('num Function(num)', 'Object');
    isNotSubtype2('num Function(num)?', 'Object');

    isNotSubtype2('num', 'num Function(num)');
    isNotSubtype2('Object', 'num Function(num)');
    isNotSubtype2('Object?', 'num Function(num)');
    isNotSubtype2('dynamic', 'num Function(num)');

    isSubtype2('num Function(num)', 'num Function(num)?');
    isNotSubtype2('num Function(num)?', 'num Function(num)');

    isSubtype2('num Function(num)', 'num? Function(num)');
    isSubtype2('num Function(num?)', 'num Function(num)');
    isSubtype2('num Function(num?)', 'num? Function(num)');
    isNotSubtype2('num Function(num)', 'num? Function(num?)');

    isSubtype2('num Function({num x})', 'num? Function({num x})');
    isSubtype2('num Function({num? x})', 'num Function({num x})');
    isSubtype2('num Function({num? x})', 'num? Function({num x})');
    isNotSubtype2('num Function({num x})', 'num? Function({num? x})');

    isSubtype2('num Function([num])', 'num? Function([num])');
    isSubtype2('num Function([num?])', 'num Function([num])');
    isSubtype2('num Function([num?])', 'num? Function([num])');
    isNotSubtype2('num Function([num])', 'num? Function([num?])');
  }

  test_multi_function_nonGeneric_zeroArguments() {
    isSubtype2('int Function()', 'Function');
    isSubtype2('int Function()', 'Function?');

    isNotSubtype2('int Function()?', 'Function');
    isSubtype2('int Function()?', 'Function?');

    isSubtype2('int Function()', 'Object');
    isSubtype2('int Function()', 'Object?');

    isNotSubtype2('int Function()?', 'Object');
    isSubtype2('int Function()?', 'Object?');
  }

  test_multi_futureOr() {
    isSubtype2('int', 'FutureOr<int>');
    isSubtype2('int', 'FutureOr<num>');
    isSubtype2('Future<int>', 'FutureOr<int>');
    isSubtype2('Future<int>', 'FutureOr<num>');
    isSubtype2('Future<int>', 'FutureOr<Object>');
    isSubtype2('FutureOr<int>', 'FutureOr<int>');
    isSubtype2('FutureOr<int>', 'FutureOr<num>');
    isSubtype2('FutureOr<int>', 'Object');
    isSubtype2('Null?', 'FutureOr<num?>');
    isSubtype2('Null?', 'FutureOr<num>?');
    isSubtype2('num?', 'FutureOr<num?>');
    isSubtype2('num?', 'FutureOr<num>?');
    isSubtype2('Future<num>', 'FutureOr<num?>');
    isSubtype2('Future<num>', 'FutureOr<num>?');
    isSubtype2('Future<num>', 'FutureOr<num?>?');
    isSubtype2('Future<num?>', 'FutureOr<num?>');
    isNotSubtype2('Future<num?>', 'FutureOr<num>?');
    isSubtype2('Future<num?>', 'FutureOr<num?>?');

    isSubtype2('num?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype2('Future<num>?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype2('Future<Future<num>>?', 'FutureOr<FutureOr<FutureOr<num>>?>');
    isSubtype2(
      'Future<Future<Future<num>>>?',
      'FutureOr<FutureOr<FutureOr<num>>?>',
    );
    isSubtype2('Future<num>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype2('Future<Future<num>>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype2(
      'Future<Future<Future<num>>>?',
      'FutureOr<FutureOr<FutureOr<num?>>>',
    );
    isSubtype2('Future<num?>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype2('Future<Future<num?>?>?', 'FutureOr<FutureOr<FutureOr<num?>>>');
    isSubtype2(
      'Future<Future<Future<num?>?>?>?',
      'FutureOr<FutureOr<FutureOr<num?>>>',
    );

    isSubtype2('FutureOr<num>?', 'FutureOr<num?>');
    isNotSubtype2('FutureOr<num?>', 'FutureOr<num>?');

    isSubtype2('dynamic', 'FutureOr<Object?>');
    isSubtype2('dynamic', 'FutureOr<Object>?');
    isSubtype2('void', 'FutureOr<Object?>');
    isSubtype2('void', 'FutureOr<Object>?');
    isSubtype2('Object?', 'FutureOr<Object?>');
    isSubtype2('Object?', 'FutureOr<Object>?');
    isSubtype2('Object', 'FutureOr<Object?>');
    isSubtype2('Object', 'FutureOr<Object>?');
    isNotSubtype2('dynamic', 'FutureOr<Object>');
    isNotSubtype2('void', 'FutureOr<Object>');
    isNotSubtype2('Object?', 'FutureOr<Object>');
    isSubtype2('Object', 'FutureOr<Object>');

    isSubtype2('FutureOr<int>', 'Object');
    isSubtype2('FutureOr<int>', 'Object?');

    isSubtype2('FutureOr<int>', 'Object');
    isSubtype2('FutureOr<int>', 'Object?');

    isNotSubtype2('FutureOr<int>?', 'Object');
    isSubtype2('FutureOr<int>?', 'Object?');

    isSubtype2('FutureOr<int>', 'Object');
    isSubtype2('FutureOr<int>', 'Object?');

    isNotSubtype2('FutureOr<int?>', 'Object');
    isSubtype2('FutureOr<int?>', 'Object?');

    isSubtype2('FutureOr<Future<Object>>', 'Future<Object>');
    isNotSubtype2('FutureOr<Future<Object>>?', 'Future<Object>');
    isNotSubtype2('FutureOr<Future<Object>?>', 'Future<Object>');
    isNotSubtype2('FutureOr<Future<Object>?>?', 'Future<Object>');

    isSubtype2('FutureOr<num>', 'Object');
    isNotSubtype2('FutureOr<num>?', 'Object');
  }

  test_multi_futureOr_functionType() {
    isSubtype(
      functionTypeNone(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()',
      strT1: 'FutureOr<void Function()>',
    );

    isSubtype(
      functionTypeNone(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()',
      strT1: 'FutureOr<void Function()>',
    );

    isSubtype(
      functionTypeNone(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeQuestion(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()',
      strT1: 'FutureOr<void Function()?>',
    );

    isSubtype(
      functionTypeNone(
        returnType: stringNone,
      ),
      futureOrQuestion(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()',
      strT1: 'FutureOr<void Function()>?',
    );

    isSubtype(
      functionTypeQuestion(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeQuestion(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()?',
      strT1: 'FutureOr<void Function()?>',
    );

    isSubtype(
      functionTypeQuestion(
        returnType: stringNone,
      ),
      futureOrQuestion(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()?',
      strT1: 'FutureOr<void Function()>?',
    );

    isNotSubtype(
      functionTypeQuestion(
        returnType: stringNone,
      ),
      futureOrNone(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      strT0: 'String Function()?',
      strT1: 'FutureOr<void Function()>',
    );

    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
      ),
      futureOrNone(
        functionTypeNone(
          returnType: stringNone,
        ),
      ),
      strT0: 'void Function()',
      strT1: 'FutureOr<String Function()>',
    );
  }

  test_multi_futureOr_typeParameter() {
    TypeParameterElement E;

    E = typeParameter('E', bound: objectNone);
    isSubtype(
      typeParameterTypeNone(E),
      futureOrNone(
        typeParameterTypeNone(E),
      ),
      strT0: 'E, E extends Object',
      strT1: 'FutureOr<E>, E extends Object',
    );

    E = typeParameter('E', bound: objectNone);
    isSubtype(
      typeParameterTypeQuestion(E),
      futureOrQuestion(
        typeParameterTypeNone(E),
      ),
      strT0: 'E?, E extends Object',
      strT1: 'FutureOr<E>?, E extends Object',
    );
    isSubtype(
      typeParameterTypeQuestion(E),
      futureOrNone(
        typeParameterTypeQuestion(E),
      ),
      strT0: 'E?, E extends Object',
      strT1: 'FutureOr<E?>, E extends Object',
    );
    isNotSubtype(
      typeParameterTypeQuestion(E),
      futureOrNone(
        typeParameterTypeNone(E),
      ),
      strT0: 'E?, E extends Object',
      strT1: 'FutureOr<E>, E extends Object',
    );

    E = typeParameter('E', bound: objectQuestion);
    isSubtype(
      typeParameterTypeNone(E),
      futureOrQuestion(
        typeParameterTypeNone(E),
      ),
      strT0: 'E, E extends Object?',
      strT1: 'FutureOr<E>?, E extends Object?',
    );
    isSubtype(
      typeParameterTypeNone(E),
      futureOrNone(
        typeParameterTypeQuestion(E),
      ),
      strT0: 'E, E extends Object?',
      strT1: 'FutureOr<E?>, E extends Object?',
    );
    isSubtype(
      typeParameterTypeNone(E),
      futureOrNone(
        typeParameterTypeNone(E),
      ),
      strT0: 'E, E extends Object?',
      strT1: 'FutureOr<E>, E extends Object?',
    );

    E = typeParameter('E', bound: objectNone);
    isNotSubtype(
      typeParameterTypeNone(E),
      futureOrNone(stringNone),
      strT0: 'E, E extends Object',
      strT1: 'FutureOr<String>',
    );

    E = typeParameter('E', bound: stringNone);
    isSubtype(
      typeParameterTypeQuestion(E),
      futureOrQuestion(stringNone),
      strT0: 'E?, E extends String',
      strT1: 'FutureOr<String>?',
    );
    isSubtype(
      typeParameterTypeQuestion(E),
      futureOrNone(stringQuestion),
      strT0: 'E?, E extends String',
      strT1: 'FutureOr<String?>',
    );
    isNotSubtype(
      typeParameterTypeQuestion(E),
      futureOrNone(stringNone),
      strT0: 'E?, E extends String',
      strT1: 'FutureOr<String>',
    );

    E = typeParameter('E', bound: stringQuestion);
    isSubtype(
      typeParameterTypeNone(E),
      futureOrQuestion(stringNone),
      strT0: 'E, E extends String?',
      strT1: 'FutureOr<String>?',
    );
    isSubtype(
      typeParameterTypeNone(E),
      futureOrNone(stringQuestion),
      strT0: 'E, E extends String?',
      strT1: 'FutureOr<String?>',
    );
    isNotSubtype(
      typeParameterTypeNone(E),
      futureOrNone(stringNone),
      strT0: 'E, E extends String?',
      strT1: 'FutureOr<String>',
    );
  }

  test_multi_futureOr_typeParameter_promotion() {
    TypeParameterElement S;
    TypeParameterElement T;

    T = typeParameter('T', bound: objectNone);
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numNone),
      strT0: 'T & int, T extends Object',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numQuestion),
      strT0: 'T & int, T extends Object',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrQuestion(numNone),
      strT0: 'T & int, T extends Object',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectQuestion);
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numNone),
      strT0: 'T & int, T extends Object?',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrNone(numQuestion),
      strT0: 'T & int, T extends Object?',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      futureOrQuestion(numNone),
      strT0: 'T & int, T extends Object?',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectQuestion);
    isNotSubtype(
      promotedTypeParameterTypeNone(T, intQuestion),
      futureOrNone(numNone),
      strT0: 'T & int?, T extends Object?',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intQuestion),
      futureOrNone(numQuestion),
      strT0: 'T & int?, T extends Object?',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, intQuestion),
      futureOrQuestion(numNone),
      strT0: 'T & int?, T extends Object?',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectQuestion);
    S = typeParameter('S', bound: typeParameterTypeNone(T));
    isNotSubtype(
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(S)),
      futureOrNone(objectNone),
      strT0: 'T & S, T extends Object?',
      strT1: 'FutureOr<Object>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(S)),
      futureOrNone(objectQuestion),
      strT0: 'T & S, T extends Object?',
      strT1: 'FutureOr<Object?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(S)),
      futureOrQuestion(objectNone),
      strT0: 'T & S, T extends Object?',
      strT1: 'FutureOr<Object>?',
    );

    T = typeParameter('T', bound: objectNone);
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(numNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<num>, T extends Object',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<int>, T extends Object',
      strT1: 'FutureOr<num>',
    );

    T = typeParameter('T', bound: objectNone);
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<int>, T extends Object',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numQuestion),
      strT0: 'T & Future<int>, T extends Object',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrQuestion(numNone),
      strT0: 'T & Future<int>, T extends Object',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectQuestion);
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<int>, T extends Object?',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrNone(numQuestion),
      strT0: 'T & Future<int>, T extends Object?',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intNone)),
      futureOrQuestion(numNone),
      strT0: 'T & Future<int>, T extends Object?',
      strT1: 'FutureOr<num>?',
    );

    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureQuestion(intNone)),
      futureOrNone(numNone),
      strT0: 'T & Future<int>?, T extends Object?',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureQuestion(intNone)),
      futureOrNone(numQuestion),
      strT0: 'T & Future<int>?, T extends Object?',
      strT1: 'FutureOr<num?>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureQuestion(intNone)),
      futureOrQuestion(numNone),
      strT0: 'T & Future<int>?, T extends Object?',
      strT1: 'FutureOr<num>?',
    );

    T = typeParameter('T', bound: objectNone);
    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intQuestion)),
      futureOrNone(numNone),
      strT0: 'T & Future<int?>, T extends Object',
      strT1: 'FutureOr<num>',
    );
    isSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intQuestion)),
      futureOrNone(numQuestion),
      strT0: 'T & Future<int?>, T extends Object',
      strT1: 'FutureOr<num?>',
    );
    isNotSubtype(
      promotedTypeParameterTypeNone(T, futureNone(intQuestion)),
      futureOrQuestion(numNone),
      strT0: 'T & Future<int?>, T extends Object',
      strT1: 'FutureOr<num>?',
    );
  }

  test_multi_list_subTypes_superTypes() {
    isSubtype2('List<int>', 'List<int>');
    isSubtype2('List<int>', 'Iterable<int>');
    isSubtype2('List<int>', 'List<num>');
    isSubtype2('List<int>', 'Iterable<num>');
    isSubtype2('List<int>', 'List<Object>');
    isSubtype2('List<int>', 'Iterable<Object>');
    isSubtype2('List<int>', 'Object');
    isSubtype2('List<int>', 'List<Comparable<Object>>');
    isSubtype2('List<int>', 'List<Comparable<num>>');
    isSubtype2('List<int>', 'List<Comparable<Comparable<num>>>');
    isSubtype2('List<int>', 'Object');
    isNotSubtype2('Null?', 'List<int>');
    isSubtype2('Null?', 'List<int>?');
    isSubtype2('Never', 'List<int>');
    isSubtype2('Never', 'List<int>?');

    isSubtype2('List<int>', 'List<int>');
    isSubtype2('List<int>', 'List<int>?');
    isNotSubtype2('List<int>?', 'List<int>');
    isSubtype2('List<int>?', 'List<int>?');

    isSubtype2('List<int>', 'List<int?>');
    isNotSubtype2('List<int?>', 'List<int>');
    isSubtype2('List<int?>', 'List<int?>');
  }

  test_multi_never() {
    isSubtype2('Never', 'FutureOr<num>');
    isSubtype2('Never', 'FutureOr<num?>');
    isSubtype2('Never', 'FutureOr<num>?');
    isNotSubtype2('FutureOr<num>', 'Never');
  }

  test_multi_num_subTypes_superTypes() {
    isSubtype2('int', 'num');
    isSubtype2('int', 'Comparable<num>');
    isSubtype2('int', 'Comparable<Object>');
    isSubtype2('double', 'num');
    isSubtype2('num', 'Object');
    isSubtype2('Null?', 'num?');
    isSubtype2('Never', 'num');
    isSubtype2('Never', 'num?');

    isNotSubtype2('int', 'double');
    isNotSubtype2('int', 'Comparable<int>');
    isNotSubtype2('int', 'Iterable<int>');
    isNotSubtype2('Comparable<int>', 'Iterable<int>');
    isNotSubtype2('num?', 'Object');
    isNotSubtype2('Null?', 'num');
    isNotSubtype2('num', 'Never');
  }

  test_multi_object_topAndBottom() {
    isSubtype2('Never', 'Object');
    isSubtype2('Object', 'dynamic');
    isSubtype2('Object', 'void');
    isSubtype2('Object', 'Object?');

    isNotSubtype2('Object', 'Never');
    isNotSubtype2('Object', 'Null?');
    isNotSubtype2('dynamic', 'Object');
    isNotSubtype2('void', 'Object');
    isNotSubtype2('Object?', 'Object');
  }

  test_multi_special() {
    isNotSubtype2('dynamic', 'int');
    isNotSubtype2('dynamic', 'int?');

    isNotSubtype2('void', 'int');
    isNotSubtype2('void', 'int?');

    isNotSubtype2('Object', 'int');
    isNotSubtype2('Object', 'int?');

    isNotSubtype2('Object?', 'int');
    isNotSubtype2('Object?', 'int?');

    isNotSubtype2('int Function()', 'int');
  }

  test_multi_topAndBottom() {
    isSubtype2('Null?', 'Null?');
    isSubtype2('Never', 'Null?');
    isSubtype2('Never', 'Never');
    isNotSubtype2('Null?', 'Never');

    isSubtype2('Null?', 'Never?');
    isSubtype2('Never?', 'Null?');
    isSubtype2('Never', 'Never?');
    isNotSubtype2('Never?', 'Never');

    isSubtype2('dynamic', 'dynamic');
    isSubtype2('dynamic', 'void');
    isSubtype2('dynamic', 'Object?');
    isSubtype2('void', 'dynamic');
    isSubtype2('void', 'void');
    isSubtype2('void', 'Object?');
    isSubtype2('Object?', 'dynamic');
    isSubtype2('Object?', 'void');
    isSubtype2('Object?', 'Object?');

    isSubtype2('Never', 'Object?');
    isSubtype2('Never', 'dynamic');
    isSubtype2('Never', 'void');
    isSubtype2('Null?', 'Object?');
    isSubtype2('Null?', 'dynamic');
    isSubtype2('Null?', 'void');

    isNotSubtype2('Object?', 'Never');
    isNotSubtype2('Object?', 'Null?');
    isNotSubtype2('dynamic', 'Never');
    isNotSubtype2('dynamic', 'Null?');
    isNotSubtype2('void', 'Never');
    isNotSubtype2('void', 'Null?');
  }

  test_multi_typeParameter_promotion() {
    TypeParameterElement T;

    T = typeParameter('T', bound: intNone);
    isSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T, T extends int',
      strT1: 'T & int, T extends int',
    );
    isNotSubtype(
      typeParameterTypeQuestion(T),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T?, T extends int',
      strT1: 'T & int, T extends int',
    );

    T = typeParameter('T', bound: intQuestion);
    isNotSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T, T extends int?',
      strT1: 'T & int, T extends int?',
    );
    isSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intQuestion),
      strT0: 'T, T extends int?',
      strT1: 'T & int?, T extends int?',
    );
    isNotSubtype(
      typeParameterTypeQuestion(T),
      promotedTypeParameterTypeNone(T, intQuestion),
      strT0: 'T?, T extends int?',
      strT1: 'T & int?, T extends int?',
    );

    T = typeParameter('T', bound: numNone);
    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T, T extends num',
      strT1: 'T, T extends num',
    );
    isSubtype(
      typeParameterTypeQuestion(T),
      typeParameterTypeQuestion(T),
      strT0: 'T?, T extends num',
      strT1: 'T?, T extends num',
    );

    T = typeParameter('T', bound: numQuestion);
    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T, T extends num?',
      strT1: 'T, T extends num?',
    );
    isSubtype(
      typeParameterTypeQuestion(T),
      typeParameterTypeQuestion(T),
      strT0: 'T?, T extends num?',
      strT1: 'T?, T extends num?',
    );
  }

  test_never_01() {
    isSubtype(
      neverNone,
      neverNone,
      strT0: 'Never',
      strT1: 'Never',
    );
  }

  test_never_02() {
    isSubtype(neverNone, numNone, strT0: 'Never', strT1: 'num');
  }

  test_never_04() {
    isSubtype(neverNone, numQuestion, strT0: 'Never', strT1: 'num?');
  }

  test_never_05() {
    isNotSubtype(numNone, neverNone, strT0: 'num', strT1: 'Never');
  }

  test_never_06() {
    isSubtype(
      neverNone,
      listNone(intNone),
      strT0: 'Never',
      strT1: 'List<int>',
    );
  }

  test_never_09() {
    isNotSubtype(
      numNone,
      neverNone,
      strT0: 'num',
      strT1: 'Never',
    );
  }

  test_never_15() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      neverNone,
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'Never',
      strT1: 'T & num, T extends Object',
    );
  }

  test_never_16() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      promotedTypeParameterTypeNone(T, numNone),
      neverNone,
      strT0: 'T & num, T extends Object',
      strT1: 'Never',
    );
  }

  test_never_17() {
    var T = typeParameter('T', bound: neverNone);

    isSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Never',
      strT1: 'Never',
    );
  }

  test_never_18() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      promotedTypeParameterTypeNone(T, neverNone),
      neverNone,
      strT0: 'T & Never, T extends Object',
      strT1: 'Never',
    );
  }

  test_never_19() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      neverNone,
      typeParameterTypeQuestion(T),
      strT0: 'Never',
      strT1: 'T?, T extends Object',
    );
  }

  test_never_20() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      neverNone,
      typeParameterTypeQuestion(T),
      strT0: 'Never',
      strT1: 'T?, T extends Object?',
    );
  }

  test_never_21() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      neverNone,
      typeParameterTypeNone(T),
      strT0: 'Never',
      strT1: 'T, T extends Object',
    );
  }

  test_never_22() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      neverNone,
      typeParameterTypeNone(T),
      strT0: 'Never',
      strT1: 'T, T extends Object?',
    );
  }

  test_never_23() {
    var T = typeParameter('T', bound: neverNone);

    isSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Never',
      strT1: 'Never',
    );
  }

  test_never_24() {
    var T = typeParameter('T', bound: neverQuestion);

    isNotSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Never?',
      strT1: 'Never',
    );
  }

  test_never_25() {
    var T = typeParameter('T', bound: neverNone);

    isNotSubtype(
      typeParameterTypeQuestion(T),
      neverNone,
      strT0: 'T?, T extends Never',
      strT1: 'Never',
    );
  }

  test_never_26() {
    var T = typeParameter('T', bound: neverQuestion);

    isNotSubtype(
      typeParameterTypeQuestion(T),
      neverNone,
      strT0: 'T?, T extends Never?',
      strT1: 'Never',
    );
  }

  test_never_27() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Object',
      strT1: 'Never',
    );
  }

  test_never_28() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      typeParameterTypeNone(T),
      neverNone,
      strT0: 'T, T extends Object?',
      strT1: 'Never',
    );
  }

  test_never_29() {
    isSubtype(neverNone, nullQuestion, strT0: 'Never', strT1: 'Null?');
  }

  test_null_01() {
    isNotSubtype(
      nullQuestion,
      neverNone,
      strT0: 'Null?',
      strT1: 'Never',
    );
  }

  test_null_02() {
    isNotSubtype(
      nullQuestion,
      objectNone,
      strT0: 'Null?',
      strT1: 'Object',
    );
  }

  test_null_03() {
    isSubtype(
      nullQuestion,
      voidNone,
      strT0: 'Null?',
      strT1: 'void',
    );
  }

  test_null_04() {
    isSubtype(
      nullQuestion,
      dynamicType,
      strT0: 'Null?',
      strT1: 'dynamic',
    );
  }

  test_null_05() {
    isNotSubtype(
      nullQuestion,
      doubleNone,
      strT0: 'Null?',
      strT1: 'double',
    );
  }

  test_null_06() {
    isSubtype(
      nullQuestion,
      doubleQuestion,
      strT0: 'Null?',
      strT1: 'double?',
    );
  }

  test_null_07() {
    isNotSubtype(
      nullQuestion,
      comparableNone(objectNone),
      strT0: 'Null?',
      strT1: 'Comparable<Object>',
    );
  }

  test_null_08() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(T),
      strT0: 'Null?',
      strT1: 'T, T extends Object',
    );
  }

  test_null_09() {
    isSubtype(
      nullQuestion,
      nullQuestion,
      strT0: 'Null?',
      strT1: 'Null?',
    );
  }

  test_null_10() {
    isNotSubtype(
      nullQuestion,
      listNone(intNone),
      strT0: 'Null?',
      strT1: 'List<int>',
    );
  }

  test_null_13() {
    isNotSubtype(
      nullQuestion,
      functionTypeNone(
        returnType: numNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      strT0: 'Null?',
      strT1: 'num Function(int)',
    );
  }

  test_null_14() {
    isNotSubtype(
      nullQuestion,
      functionTypeNone(
        returnType: numNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      strT0: 'Null?',
      strT1: 'num Function(int)',
    );
  }

  test_null_15() {
    isSubtype(
      nullQuestion,
      functionTypeQuestion(
        returnType: numNone,
        parameters: [
          requiredParameter(type: intNone),
        ],
      ),
      strT0: 'Null?',
      strT1: 'num Function(int)?',
    );
  }

  test_null_16() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      nullQuestion,
      promotedTypeParameterTypeQuestion(T, numNone),
      strT0: 'Null?',
      strT1: '(T & num)?, T extends Object',
    );
  }

  test_null_17() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'Null?',
      strT1: 'T & num, T extends Object?',
    );
  }

  test_null_18() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, numQuestion),
      strT0: 'Null?',
      strT1: 'T & num?, T extends Object?',
    );
  }

  test_null_19() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'Null?',
      strT1: 'T & num, T extends Object',
    );
  }

  test_null_20() {
    var T = typeParameter('T', bound: objectQuestion);
    var S = typeParameter('S', bound: typeParameterTypeNone(T));

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, typeParameterTypeNone(S)),
      strT0: 'Null?',
      strT1: 'T & S, T extends Object?',
    );
  }

  test_null_21() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      nullQuestion,
      typeParameterTypeQuestion(T),
      strT0: 'Null?',
      strT1: 'T?, T extends Object',
    );
  }

  test_null_22() {
    var T = typeParameter('T', bound: objectQuestion);

    isSubtype(
      nullQuestion,
      typeParameterTypeQuestion(T),
      strT0: 'Null?',
      strT1: 'T?, T extends Object?',
    );
  }

  test_null_23() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(T),
      strT0: 'Null?',
      strT1: 'T, T extends Object',
    );
  }

  test_null_24() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(T),
      strT0: 'Null?',
      strT1: 'T, T extends Object?',
    );
  }

  test_null_25() {
    var T = typeParameter('T', bound: nullQuestion);

    isSubtype(
      typeParameterTypeNone(T),
      nullQuestion,
      strT0: 'T, T extends Null?',
      strT1: 'Null?',
    );
  }

  test_null_26() {
    var T = typeParameter('T', bound: nullQuestion);

    isSubtype(
      typeParameterTypeQuestion(T),
      nullQuestion,
      strT0: 'T?, T extends Null?',
      strT1: 'Null?',
    );
  }

  test_null_27() {
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      typeParameterTypeNone(T),
      nullQuestion,
      strT0: 'T, T extends Object',
      strT1: 'Null?',
    );
  }

  test_null_28() {
    var T = typeParameter('T', bound: objectQuestion);

    isNotSubtype(
      typeParameterTypeNone(T),
      nullQuestion,
      strT0: 'T, T extends Object?',
      strT1: 'Null?',
    );
  }

  test_null_29() {
    isSubtype(
      nullQuestion,
      comparableQuestion(objectNone),
      strT0: 'Null?',
      strT1: 'Comparable<Object>?',
    );
  }

  test_null_30() {
    isNotSubtype(nullQuestion, objectNone, strT0: 'Null?', strT1: 'Object');
  }

  test_nullabilitySuffix_01() {
    isSubtype(intNone, intNone, strT0: 'int', strT1: 'int');
    isSubtype(intNone, intQuestion, strT0: 'int', strT1: 'int?');

    isNotSubtype(intQuestion, intNone, strT0: 'int?', strT1: 'int');
    isSubtype(intQuestion, intQuestion, strT0: 'int?', strT1: 'int?');

    isSubtype(intNone, intNone, strT0: 'int', strT1: 'int');
    isSubtype(intNone, intQuestion, strT0: 'int', strT1: 'int?');
  }

  test_nullabilitySuffix_05() {
    isSubtype(
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: voidNone,
      ),
      objectNone,
      strT0: 'void Function(int)',
      strT1: 'Object',
    );
  }

  test_nullabilitySuffix_11() {
    isSubtype(
      intQuestion,
      intQuestion,
      strT0: 'int?',
      strT1: 'int?',
    );
  }

  test_nullabilitySuffix_12() {
    isSubtype(
      intNone,
      intNone,
      strT0: 'int',
      strT1: 'int',
    );
  }

  test_nullabilitySuffix_13() {
    var f = functionTypeQuestion(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: intNone,
    );
    isSubtype(
      f,
      f,
      strT0: 'int Function(int)?',
      strT1: 'int Function(int)?',
    );
  }

  test_nullabilitySuffix_14() {
    var f = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: intNone,
    );
    isSubtype(
      f,
      f,
      strT0: 'int Function(int)',
      strT1: 'int Function(int)',
    );
  }

  test_nullabilitySuffix_15() {
    var f = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: intNone),
        requiredParameter(type: intQuestion),
      ],
      returnType: intQuestion,
    );
    isSubtype(
      f,
      f,
      strT0: 'int? Function(int, int, int?)',
      strT1: 'int? Function(int, int, int?)',
    );
  }

  test_nullabilitySuffix_16() {
    var type = listQuestion(intNone);
    isSubtype(
      type,
      type,
      strT0: 'List<int>?',
      strT1: 'List<int>?',
    );
  }

  test_nullabilitySuffix_17() {
    var type = listQuestion(intQuestion);
    isSubtype(
      type,
      type,
      strT0: 'List<int?>?',
      strT1: 'List<int?>?',
    );
  }

  test_nullabilitySuffix_18() {
    var T = typeParameter('T', bound: objectNone);
    var type = promotedTypeParameterTypeNone(T, intQuestion);
    isSubtype(
      type,
      type,
      strT0: 'T & int?, T extends Object',
      strT1: 'T & int?, T extends Object',
    );
  }

  test_nullabilitySuffix_19() {
    var T = typeParameter('T', bound: objectNone);
    var type = promotedTypeParameterTypeQuestion(T, intQuestion);
    isSubtype(
      type,
      type,
      strT0: '(T & int?)?, T extends Object',
      strT1: '(T & int?)?, T extends Object',
    );
  }

  test_record_functionType() {
    isNotSubtype2('({int f1})', 'void Function()');
  }

  test_record_interfaceType() {
    isNotSubtype2('({int f1})', 'int');
    isNotSubtype2('int', '({int f1})');
  }

  test_record_Never() {
    isNotSubtype2('({int f1})', 'Never');
    isSubtype2('Never', '({int f1})');
  }

  test_record_record2_differentShape() {
    void check(String T1, String T2) {
      isNotSubtype2(T1, T2);
      isNotSubtype2(T2, T1);
    }

    check('(int,)', '(int, String)');
    check('(int,)', r'({int $1})');

    check('({int f1, String f2})', '({int f1})');
    check('({int f1})', '({int f2})');
  }

  test_record_record2_sameShape_mixed() {
    void check(String subType, String superType) {
      isSubtype2(subType, superType);
      isNotSubtype2(superType, subType);
    }

    check('(int, {String f2})', '(int, {Object f2})');
  }

  test_record_record2_sameShape_named() {
    void check(String subType, String superType) {
      isSubtype2(subType, superType);
      isNotSubtype2(superType, subType);
    }

    check('({int f1})', '({num f1})');

    isSubtype2('({int f1, String f2})', '({int f1, String f2})');
    check('({int f1, String f2})', '({int f1, Object f2})');
    check('({int f1, String f2})', '({num f1, String f2})');
    check('({int f1, String f2})', '({num f1, Object f2})');
  }

  test_record_record2_sameShape_named_order() {
    void check(RecordType subType, RecordType superType) {
      isSubtype(subType, superType);
      isSubtype(superType, subType);
    }

    check(
      recordTypeNone(
        namedTypes: {
          'f1': intNone,
          'f2': intNone,
          'f3': intNone,
          'f4': intNone,
        },
      ),
      recordTypeNone(
        namedTypes: {
          'f4': intNone,
          'f3': intNone,
          'f2': intNone,
          'f1': intNone,
        },
      ),
    );
  }

  test_record_record2_sameShape_positional() {
    void check(String subType, String superType) {
      isSubtype2(subType, superType);
      isNotSubtype2(superType, subType);
    }

    check('(int,)', '(num,)');

    isSubtype2('(int, String)', '(int, String)');
    check('(int, String)', '(num, String)');
    check('(int, String)', '(num, Object)');
    check('(int, String)', '(int, Object)');
  }

  test_record_top() {
    isSubtype2('({int f1})', 'dynamic');
    isSubtype2('({int f1})', 'Object');
    isSubtype2('({int f1})', 'Record');
  }

  /// The class `Record` is a subtype of `Object` and `dynamic`, and a
  /// supertype of `Never`.
  test_recordClass() {
    isSubtype(
      recordNone,
      objectNone,
      strT0: 'Record',
      strT1: 'Object',
    );

    isSubtype(
      recordNone,
      dynamicType,
      strT0: 'Record',
      strT1: 'dynamic',
    );

    isSubtype(
      neverNone,
      recordNone,
      strT0: 'Never',
      strT1: 'Record',
    );
  }

  test_special_01() {
    isNotSubtype(
      dynamicType,
      intNone,
      strT0: 'dynamic',
      strT1: 'int',
    );
  }

  test_special_02() {
    isNotSubtype(
      voidNone,
      intNone,
      strT0: 'void',
      strT1: 'int',
    );
  }

  test_special_03() {
    isNotSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      intNone,
      strT0: 'int Function()',
      strT1: 'int',
    );
  }

  test_special_04() {
    isNotSubtype(
      intNone,
      functionTypeNone(
        returnType: intNone,
      ),
      strT0: 'int',
      strT1: 'int Function()',
    );
  }

  test_special_06() {
    isSubtype(
      functionTypeNone(
        returnType: intNone,
      ),
      objectNone,
      strT0: 'int Function()',
      strT1: 'Object',
    );
  }

  test_special_07() {
    isSubtype(
      objectNone,
      objectNone,
      strT0: 'Object',
      strT1: 'Object',
    );
  }

  test_special_08() {
    isSubtype(
      objectNone,
      dynamicType,
      strT0: 'Object',
      strT1: 'dynamic',
    );
  }

  test_special_09() {
    isSubtype(
      objectNone,
      voidNone,
      strT0: 'Object',
      strT1: 'void',
    );
  }

  test_special_10() {
    isNotSubtype(
      dynamicType,
      objectNone,
      strT0: 'dynamic',
      strT1: 'Object',
    );
  }

  test_special_11() {
    isSubtype(
      dynamicType,
      dynamicType,
      strT0: 'dynamic',
      strT1: 'dynamic',
    );
  }

  test_special_12() {
    isSubtype(
      dynamicType,
      voidNone,
      strT0: 'dynamic',
      strT1: 'void',
    );
  }

  test_special_13() {
    isNotSubtype(
      voidNone,
      objectNone,
      strT0: 'void',
      strT1: 'Object',
    );
  }

  test_special_14() {
    isSubtype(
      voidNone,
      dynamicType,
      strT0: 'void',
      strT1: 'dynamic',
    );
  }

  test_special_15() {
    isSubtype(
      voidNone,
      voidNone,
      strT0: 'void',
      strT1: 'void',
    );
  }

  test_top_03() {
    var T0 = typeParameter('T0', bound: dynamicType);
    var T1 = typeParameter('T2', bound: voidNone);

    var f0 = functionTypeNone(
      typeFormals: [T0],
      returnType: typeParameterTypeNone(T0),
    );

    var f1 = functionTypeNone(
      typeFormals: [T1],
      returnType: typeParameterTypeNone(T1),
    );

    isSubtype(f0, f1);
    isSubtype(f1, f0);
  }

  test_top_04() {
    isNotSubtype(
      dynamicType,
      functionTypeNone(
        returnType: dynamicType,
      ),
      strT0: 'dynamic',
      strT1: 'dynamic Function()',
    );
  }

  test_top_05() {
    isNotSubtype(
      futureOrNone(
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'FutureOr<void Function()>',
      strT1: 'void Function()',
    );
  }

  test_top_06() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'T & void Function()',
      strT1: 'void Function()',
    );
  }

  test_top_07() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        returnType: dynamicType,
      ),
      strT0: 'T & void Function()',
      strT1: 'dynamic Function()',
    );
  }

  test_top_08() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        returnType: objectNone,
      ),
      strT0: 'T & void Function()',
      strT1: 'Object Function()',
    );
  }

  test_top_09() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: voidNone),
        ],
        returnType: voidNone,
      ),
      strT0: 'T & void Function(void)',
      strT1: 'void Function(void)',
    );
  }

  test_top_10() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: dynamicType),
        ],
        returnType: dynamicType,
      ),
      strT0: 'T & void Function(void)',
      strT1: 'dynamic Function(dynamic)',
    );
  }

  test_top_11() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: objectNone),
        ],
        returnType: objectNone,
      ),
      strT0: 'T & void Function(void)',
      strT1: 'Object Function(Object)',
    );
  }

  test_top_12() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: iterableNone(intNone)),
        ],
        returnType: dynamicType,
      ),
      strT0: 'T & void Function(void)',
      strT1: 'dynamic Function(Iterable<int>)',
    );
  }

  test_top_13() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: objectNone,
      ),
      strT0: 'T & void Function(void)',
      strT1: 'Object Function(int)',
    );
  }

  test_top_14() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          parameters: [
            requiredParameter(type: voidNone),
          ],
          returnType: voidNone,
        ),
      ),
      functionTypeNone(
        parameters: [
          requiredParameter(type: intNone),
        ],
        returnType: intNone,
      ),
      strT0: 'T & void Function(void)',
      strT1: 'int Function(int)',
    );
  }

  test_top_15() {
    var T = typeParameter(
      'T',
      bound: functionTypeNone(
        returnType: voidNone,
      ),
    );

    isSubtype(
      typeParameterTypeNone(T),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'T, T extends void Function()',
      strT1: 'void Function()',
    );
  }

  test_top_16() {
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(T),
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'T',
      strT1: 'void Function()',
    );
  }

  test_top_17() {
    isNotSubtype(
      voidNone,
      functionTypeNone(
        returnType: voidNone,
      ),
      strT0: 'void',
      strT1: 'void Function()',
    );
  }

  test_top_18() {
    var T = typeParameter('T');

    isNotSubtype(
      dynamicType,
      typeParameterTypeNone(T),
      strT0: 'dynamic',
      strT1: 'T',
    );
  }

  test_top_19() {
    var T = typeParameter('T');

    isNotSubtype(
      iterableNone(
        typeParameterTypeNone(T),
      ),
      typeParameterTypeNone(T),
      strT0: 'Iterable<T>',
      strT1: 'T',
    );
  }

  test_top_21() {
    var T = typeParameter('T');

    isNotSubtype(
      functionTypeNone(
        returnType: voidNone,
      ),
      typeParameterTypeNone(T),
      strT0: 'void Function()',
      strT1: 'T',
    );
  }

  test_top_22() {
    var T = typeParameter('T');

    isNotSubtype(
      futureOrNone(
        typeParameterTypeNone(T),
      ),
      typeParameterTypeNone(T),
      strT0: 'FutureOr<T>',
      strT1: 'T',
    );
  }

  test_top_23() {
    var T = typeParameter('T');

    isNotSubtype(
      voidNone,
      typeParameterTypeNone(T),
      strT0: 'void',
      strT1: 'T',
    );
  }

  test_top_24() {
    var T = typeParameter('T');

    isNotSubtype(
      voidNone,
      promotedTypeParameterTypeNone(T, voidNone),
      strT0: 'void',
      strT1: 'T & void',
    );
  }

  test_top_25() {
    var T = typeParameter('T', bound: voidNone);

    isNotSubtype(
      voidNone,
      promotedTypeParameterTypeNone(T, voidNone),
      strT0: 'void',
      strT1: 'T & void, T extends void',
    );
  }

  test_typeParameter_01() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T & int',
      strT1: 'T & int',
    );
  }

  test_typeParameter_02() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'T & int',
      strT1: 'T & num',
    );
  }

  test_typeParameter_03() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, numNone),
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'T & num',
      strT1: 'T & num',
    );
  }

  test_typeParameter_04() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, numNone),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T & num',
      strT1: 'T & int',
    );
  }

  test_typeParameter_05() {
    var T = typeParameter('T');

    isNotSubtype(
      nullQuestion,
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'Null?',
      strT1: 'T & num',
    );
  }

  test_typeParameter_06() {
    var T = typeParameter('T', bound: intNone);

    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      typeParameterTypeNone(T),
      strT0: 'T & int, T extends int',
      strT1: 'T, T extends int',
    );
  }

  test_typeParameter_07() {
    var T = typeParameter('T', bound: numNone);

    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      typeParameterTypeNone(T),
      strT0: 'T & int, T extends num',
      strT1: 'T, T extends num',
    );
  }

  test_typeParameter_08() {
    var T = typeParameter('T', bound: numNone);

    isSubtype(
      promotedTypeParameterTypeNone(T, numNone),
      typeParameterTypeNone(T),
      strT0: 'T & num, T extends num',
      strT1: 'T, T extends num',
    );
  }

  test_typeParameter_09() {
    var T = typeParameter('T', bound: intNone);

    isSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T, T extends int',
      strT1: 'T & int, T extends int',
    );
  }

  test_typeParameter_10() {
    var T = typeParameter('T', bound: intNone);

    isSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'T, T extends int',
      strT1: 'T & num, T extends int',
    );
  }

  test_typeParameter_11() {
    var T = typeParameter('T', bound: numNone);

    isNotSubtype(
      typeParameterTypeNone(T),
      promotedTypeParameterTypeNone(T, intNone),
      strT0: 'T, T extends num',
      strT1: 'T & int, T extends num',
    );
  }

  test_typeParameter_12() {
    var T = typeParameter('T', bound: numNone);

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T, T extends num',
      strT1: 'T, T extends num',
    );
  }

  test_typeParameter_13() {
    var T = typeParameter('T');

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T',
      strT1: 'T',
    );
  }

  test_typeParameter_14() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S',
      strT1: 'T',
    );
  }

  test_typeParameter_15() {
    var T = typeParameter('T', bound: objectNone);

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T, T extends Object',
      strT1: 'T, T extends Object',
    );
  }

  test_typeParameter_16() {
    var S = typeParameter('S', bound: objectNone);
    var T = typeParameter('T', bound: objectNone);

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S, S extends Object',
      strT1: 'T, T extends Object',
    );
  }

  test_typeParameter_17() {
    var T = typeParameter('T', bound: dynamicType);

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(T),
      strT0: 'T, T extends dynamic',
      strT1: 'T, T extends dynamic',
    );
  }

  test_typeParameter_18() {
    var S = typeParameter('S', bound: dynamicType);
    var T = typeParameter('T', bound: dynamicType);

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S, S extends dynamic',
      strT1: 'T, T extends dynamic',
    );
  }

  test_typeParameter_19() {
    var S = typeParameter('S');
    var T = typeParameter('T', bound: typeParameterTypeNone(S));

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S',
      strT1: 'T, T extends S',
    );

    isSubtype(
      typeParameterTypeNone(T),
      typeParameterTypeNone(S),
      strT0: 'T, T extends S',
      strT1: 'S',
    );
  }

  test_typeParameter_20() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      intNone,
      strT0: 'T & int',
      strT1: 'int',
    );
  }

  test_typeParameter_21() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, intNone),
      numNone,
      strT0: 'T & int',
      strT1: 'num',
    );
  }

  test_typeParameter_22() {
    var T = typeParameter('T');

    isSubtype(
      promotedTypeParameterTypeNone(T, numNone),
      numNone,
      strT0: 'T & num',
      strT1: 'num',
    );
  }

  test_typeParameter_23() {
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(T, numNone),
      intNone,
      strT0: 'T & num',
      strT1: 'int',
    );
  }

  test_typeParameter_24() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(S, numNone),
      typeParameterTypeNone(T),
      strT0: 'S & num',
      strT1: 'T',
    );
  }

  test_typeParameter_25() {
    var S = typeParameter('S');
    var T = typeParameter('T');

    isNotSubtype(
      promotedTypeParameterTypeNone(S, numNone),
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'S & num',
      strT1: 'T & num',
    );
  }

  test_typeParameter_26() {
    var S = typeParameter('S', bound: intNone);

    isSubtype(
      typeParameterTypeNone(S),
      intNone,
      strT0: 'S, S extends int',
      strT1: 'int',
    );
  }

  test_typeParameter_27() {
    var S = typeParameter('S', bound: intNone);

    isSubtype(
      typeParameterTypeNone(S),
      numNone,
      strT0: 'S, S extends int',
      strT1: 'num',
    );
  }

  test_typeParameter_28() {
    var S = typeParameter('S', bound: numNone);

    isSubtype(
      typeParameterTypeNone(S),
      numNone,
      strT0: 'S, S extends num',
      strT1: 'num',
    );
  }

  test_typeParameter_29() {
    var S = typeParameter('S', bound: numNone);

    isNotSubtype(
      typeParameterTypeNone(S),
      intNone,
      strT0: 'S, S extends num',
      strT1: 'int',
    );
  }

  test_typeParameter_30() {
    var S = typeParameter('S', bound: numNone);
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(S),
      typeParameterTypeNone(T),
      strT0: 'S, S extends num',
      strT1: 'T',
    );
  }

  test_typeParameter_31() {
    var S = typeParameter('S', bound: numNone);
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(S),
      promotedTypeParameterTypeNone(T, numNone),
      strT0: 'S, S extends num',
      strT1: 'T & num',
    );
  }

  test_typeParameter_32() {
    var T = typeParameter('T', bound: dynamicType);

    isNotSubtype(
      dynamicType,
      promotedTypeParameterTypeNone(T, dynamicType),
      strT0: 'dynamic',
      strT1: 'T & dynamic, T extends dynamic',
    );
  }

  test_typeParameter_33() {
    var T = typeParameter('T');

    isNotSubtype(
      functionTypeNone(
        returnType: typeParameterTypeNone(T),
      ),
      promotedTypeParameterTypeNone(
        T,
        functionTypeNone(
          returnType: typeParameterTypeNone(T),
        ),
      ),
      strT0: 'T Function()',
      strT1: 'T & T Function()',
    );
  }

  test_typeParameter_34() {
    var T = typeParameter('T');

    isNotSubtype(
      futureOrNone(
        promotedTypeParameterTypeNone(T, stringNone),
      ),
      promotedTypeParameterTypeNone(T, stringNone),
      strT0: 'FutureOr<T & String>',
      strT1: 'T & String',
    );
  }

  test_typeParameter_35() {
    var T = typeParameter('T');

    isNotSubtype(
      nullQuestion,
      typeParameterTypeNone(T),
      strT0: 'Null?',
      strT1: 'T',
    );
  }

  test_typeParameter_36() {
    var T = typeParameter('T', bound: numNone);

    isSubtype(
      typeParameterTypeNone(T),
      numNone,
      strT0: 'T, T extends num',
      strT1: 'num',
    );
  }

  test_typeParameter_37() {
    var T = typeParameter('T', bound: objectQuestion);

    var type = promotedTypeParameterTypeNone(T, numQuestion);

    isNotSubtype(
      type,
      numNone,
      strT0: 'T & num?, T extends Object?',
      strT1: 'num',
    );
    isSubtype(
      type,
      numQuestion,
      strT0: 'T & num?, T extends Object?',
      strT1: 'num?',
    );
  }

  test_typeParameter_38() {
    var T = typeParameter('T', bound: numNone);

    isSubtype(
      typeParameterTypeNone(T),
      objectNone,
      strT0: 'T, T extends num',
      strT1: 'Object',
    );
  }

  test_typeParameter_39() {
    var T = typeParameter('T', bound: numNone);

    isSubtype(
      typeParameterTypeNone(T),
      objectNone,
      strT0: 'T, T extends num',
      strT1: 'Object',
    );
  }

  test_typeParameter_40() {
    var T = typeParameter('T', bound: numNone);

    isNotSubtype(
      typeParameterTypeQuestion(T),
      objectNone,
      strT0: 'T?, T extends num',
      strT1: 'Object',
    );
  }

  test_typeParameter_41() {
    var T = typeParameter('T', bound: numQuestion);

    isNotSubtype(
      typeParameterTypeNone(T),
      objectNone,
      strT0: 'T, T extends num?',
      strT1: 'Object',
    );
  }

  test_typeParameter_42() {
    var T = typeParameter('T', bound: numQuestion);

    isNotSubtype(
      typeParameterTypeQuestion(T),
      objectNone,
      strT0: 'T?, T extends num?',
      strT1: 'Object',
    );
  }

  test_typeParameter_43() {
    var T = typeParameter('T');

    isNotSubtype(
      typeParameterTypeNone(T),
      objectNone,
      strT0: 'T',
      strT1: 'Object',
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/language/issues/433')
  test_typeParameter_44() {
    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);
    var FutureOr_T_none = futureOrNone(T_none);
    T.bound = FutureOr_T_none;

    isSubtype(
      T_none,
      FutureOr_T_none,
      strT0: 'T, T extends FutureOr<T>',
      strT1: 'FutureOr<T>, T extends FutureOr<T>',
    );
  }
}

@reflectiveTest
class SubtypingCompoundTest extends _SubtypingTestBase {
  test_double() {
    var equivalents = <DartType>[doubleNone];
    var supertypes = <DartType>[numNone];
    var unrelated = <DartType>[intNone];
    _checkGroups(
      doubleNone,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
    );
  }

  test_dynamic() {
    var equivalents = <DartType>[
      voidNone,
      objectQuestion,
    ];

    var subtypes = <DartType>[
      neverNone,
      nullNone,
      objectNone,
    ];

    _checkGroups(
      dynamicType,
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  test_dynamic_isTop() {
    var equivalents = <DartType>[
      dynamicType,
      objectQuestion,
      voidNone,
    ];

    var subtypes = <DartType>[
      intNone,
      doubleNone,
      numNone,
      stringNone,
      functionNone,
    ];

    _checkGroups(
      dynamicType,
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  test_futureOr_topTypes() {
    var futureOrObject = futureOrNone(objectNone);
    var futureOrObjectQuestion = futureOrNone(objectQuestion);

    var futureOrQuestionObject = futureOrQuestion(objectNone);
    var futureOrQuestionObjectQuestion = futureOrQuestion(objectQuestion);

    //FutureOr<Object> <: FutureOr*<Object?>
    _checkGroups(
      futureOrObject,
      equivalents: [
        objectNone,
      ],
      subtypes: [],
      supertypes: [
        objectQuestion,
        futureOrQuestionObject,
        futureOrObjectQuestion,
        futureOrQuestionObject,
        futureOrQuestionObjectQuestion,
      ],
    );
  }

  test_intNone() {
    var equivalents = <DartType>[
      intNone,
    ];

    var subtypes = <DartType>[
      neverNone,
    ];

    var supertypes = <DartType>[
      intQuestion,
      objectNone,
      objectQuestion,
    ];

    var unrelated = <DartType>[
      doubleNone,
      nullNone,
      nullQuestion,
      neverQuestion,
    ];

    _checkGroups(
      intNone,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_intQuestion() {
    var equivalents = <DartType>[
      intQuestion,
    ];

    var subtypes = <DartType>[
      intNone,
      nullNone,
      nullQuestion,
      neverNone,
      neverQuestion,
    ];

    var supertypes = <DartType>[
      numQuestion,
      objectQuestion,
    ];

    var unrelated = <DartType>[
      doubleNone,
      numNone,
      objectNone,
    ];

    _checkGroups(
      intQuestion,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_null() {
    var equivalents = <DartType>[
      nullNone,
      nullQuestion,
      neverQuestion,
    ];

    var supertypes = <DartType>[
      intQuestion,
      objectQuestion,
      dynamicType,
      voidNone,
    ];

    var subtypes = <DartType>[
      neverNone,
    ];

    var unrelated = <DartType>[
      doubleNone,
      intNone,
      numNone,
      objectNone,
    ];

    for (var formOfNull in equivalents) {
      _checkGroups(
        formOfNull,
        equivalents: equivalents,
        supertypes: supertypes,
        unrelated: unrelated,
        subtypes: subtypes,
      );
    }
  }

  test_numNone() {
    var equivalents = <DartType>[numNone];
    var supertypes = <DartType>[objectNone];
    var unrelated = <DartType>[stringNone];
    var subtypes = <DartType>[intNone, doubleNone];
    _checkGroups(
      numNone,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_object() {
    var equivalents = <DartType>[];

    var supertypes = <DartType>[
      objectQuestion,
      dynamicType,
      voidNone,
    ];

    var subtypes = <DartType>[
      neverNone,
    ];

    var unrelated = <DartType>[
      doubleQuestion,
      numQuestion,
      intQuestion,
      nullNone,
    ];

    _checkGroups(
      objectNone,
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  void _checkEquivalent(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsSubtypeOf(type2, type1);
  }

  void _checkGroups(DartType t1,
      {List<DartType>? equivalents,
      List<DartType>? unrelated,
      List<DartType>? subtypes,
      List<DartType>? supertypes}) {
    if (equivalents != null) {
      for (DartType t2 in equivalents) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (DartType t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
    if (subtypes != null) {
      for (DartType t2 in subtypes) {
        _checkIsStrictSubtypeOf(t2, t1);
      }
    }
    if (supertypes != null) {
      for (DartType t2 in supertypes) {
        _checkIsStrictSubtypeOf(t1, t2);
      }
    }
  }

  void _checkIsNotSubtypeOf(DartType type1, DartType type2) {
    var strType1 = _typeStr(type1);
    var strType2 = _typeStr(type2);
    expect(typeSystem.isSubtypeOf(type1, type2), false,
        reason: '$strType1 was not supposed to be a subtype of $strType2');
  }

  void _checkIsStrictSubtypeOf(DartType type1, DartType type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkIsSubtypeOf(DartType type1, DartType type2) {
    var strType1 = _typeStr(type1);
    var strType2 = _typeStr(type2);
    expect(typeSystem.isSubtypeOf(type1, type2), true,
        reason: '$strType1 is not a subtype of $strType2');
  }

  void _checkUnrelated(DartType type1, DartType type2) {
    _checkIsNotSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  static String _typeStr(DartType type) {
    return type.getDisplayString();
  }
}

class _SubtypingTestBase extends AbstractTypeSystemTest {}
