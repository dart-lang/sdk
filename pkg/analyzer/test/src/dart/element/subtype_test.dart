// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeTest);
    defineReflectiveTests(SubtypingCompoundTest);
  });
}

@reflectiveTest
class SubtypeTest extends AbstractTypeSystemTest with StringTypes {
  void isNotSubtype(TypeImpl T0, TypeImpl T1, {String? strT0, String? strT1}) {
    assertExpectedString(T0, strT0);
    assertExpectedString(T1, strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isFalse);
  }

  void isNotSubtype2(String strT0, String strT1) {
    isNotSubtype(
      _parseTestType(strT0),
      _parseTestType(strT1),
      strT0: strT0,
      strT1: strT1,
    );
  }

  void isNotSubtype3({required String strT0, required String strT1}) {
    isNotSubtype2(strT0, strT1);
  }

  void isSubtype(TypeImpl T0, TypeImpl T1, {String? strT0, String? strT1}) {
    assertExpectedString(T0, strT0);
    assertExpectedString(T1, strT1);
    expect(typeSystem.isSubtypeOf(T0, T1), isTrue);
  }

  void isSubtype2(String strT0, String strT1) {
    isSubtype(
      _parseTestType(strT0),
      _parseTestType(strT1),
      strT0: strT0,
      strT1: strT1,
    );
  }

  @override
  void setUp() {
    super.setUp();
    defineStringTypes();
  }

  test_extensionType_implementsNotNullable() {
    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(int it) implements int'),
      ],
    );
    var type = parseInterfaceType('A');

    isSubtype(type, parseType('Object?'));
    isSubtype(type, parseType('Object'));
    isSubtype(type, parseType('int'));
    isSubtype(type, parseType('num'));
    isSubtype(parseType('Never'), type);
  }

  test_extensionType_noImplementedInterfaces() {
    buildTestLibrary(
      extensionTypes: [ExtensionTypeSpec('extension type A(int it)')],
    );
    var type = parseInterfaceType('A');

    isSubtype(type, parseType('Object?'));
    isNotSubtype(type, parseType('Object'));
    isNotSubtype(type, parseType('int'));
  }

  test_extensionType_superinterfaces() {
    buildTestLibrary(
      classes: [ClassSpec('class A'), ClassSpec('class B')],
      extensionTypes: [
        ExtensionTypeSpec('extension type X(int it) implements A'),
      ],
    );
    var type = parseInterfaceType('X');

    isSubtype(type, parseInterfaceType('A'));
    isNotSubtype(type, parseInterfaceType('B'));
  }

  test_extensionType_typeArguments() {
    buildTestLibrary(
      extensionTypes: [ExtensionTypeSpec('extension type A<T>(int it)')],
    );
    var A_object = parseInterfaceType('A<Object>');
    var A_int = parseInterfaceType('A<int>');
    var A_num = parseInterfaceType('A<num>');

    isSubtype(A_int, A_num);
    isSubtype(A_int, A_object);
    isNotSubtype(A_num, A_int);
  }

  test_functionType_01() {
    isNotSubtype2(
      'E0 Function<E0>(E0, num)',
      'E1 Function<E1 extends num>(E1, E1)',
    );
  }

  test_functionType_02() {
    isNotSubtype2(
      'int Function<E0 extends num>(E0)',
      'int Function<E1 extends int>(E1)',
    );
  }

  test_functionType_03() {
    isNotSubtype2(
      'E0 Function<E0 extends num>(E0)',
      'E1 Function<E1 extends int>(E1)',
    );
  }

  test_functionType_04() {
    isNotSubtype2(
      'E0 Function<E0 extends num>(int)',
      'E1 Function<E1 extends int>(int)',
    );
  }

  test_functionType_05() {
    isSubtype2(
      'E0 Function<E0 extends num>(E0)',
      'num Function<E1 extends num>(E1)',
    );
  }

  test_functionType_06() {
    isSubtype2(
      'E0 Function<E0 extends int>(E0)',
      'num Function<E1 extends int>(E1)',
    );
  }

  test_functionType_07() {
    isSubtype2(
      'E0 Function<E0 extends int>(E0)',
      'int Function<E1 extends int>(E1)',
    );
  }

  test_functionType_08() {
    isNotSubtype2('int Function<E0>(int)', 'int Function(int)');
  }

  test_functionType_09() {
    isNotSubtype2('int Function<E0, F0>(int)', 'int Function<E1>(int)');
  }

  test_functionType_10() {
    isSubtype2(
      'E0 Function<E0 extends List<E0>>(E0)',
      'E1 Function<E1 extends List<E1>>(E1)',
    );
  }

  test_functionType_11() {
    isNotSubtype2(
      'E0 Function<E0 extends Iterable<E0>>(E0)',
      'E1 Function<E1 extends List<E1>>(E1)',
    );
  }

  test_functionType_12() {
    isNotSubtype2(
      'E0 Function<E0>(E0, List<Object>)',
      'E1 Function<E1 extends List<E1>>(E1, E1)',
    );
  }

  test_functionType_13() {
    isNotSubtype2(
      'List<E0> Function<E0>(E0, List<Object>)',
      'E1 Function<E1 extends List<E1>>(E1, E1)',
    );
  }

  test_functionType_14() {
    isNotSubtype2(
      'int Function<E0>(E0, List<Object>)',
      'E1 Function<E1 extends List<E1>>(E1, E1)',
    );
  }

  test_functionType_15() {
    isNotSubtype2(
      'E0 Function<E0>(E0, List<Object>)',
      'void Function<E1 extends List<E1>>(E1, E1)',
    );
  }

  test_functionType_16() {
    isSubtype2('int Function()', 'Function');
  }

  test_functionType_17() {
    isNotSubtype2('Function', 'int Function()');
  }

  test_functionType_18() {
    isSubtype2('dynamic Function()', 'dynamic Function()');
  }

  test_functionType_19() {
    isSubtype2('dynamic Function()', 'void Function()');
  }

  test_functionType_20() {
    isSubtype2('void Function()', 'dynamic Function()');
  }

  test_functionType_21() {
    isSubtype2('int Function()', 'void Function()');
  }

  test_functionType_22() {
    isNotSubtype2('void Function()', 'int Function()');
  }

  test_functionType_23() {
    isSubtype2('void Function()', 'void Function()');
  }

  test_functionType_24() {
    isSubtype2('int Function()', 'int Function()');
  }

  test_functionType_25() {
    isSubtype2('int Function()', 'Object Function()');
  }

  test_functionType_26() {
    isNotSubtype2('int Function()', 'double Function()');
  }

  test_functionType_27() {
    isNotSubtype2('int Function()', 'void Function(int)');
  }

  test_functionType_28() {
    isNotSubtype2('void Function()', 'int Function(int)');
  }

  test_functionType_29() {
    isNotSubtype2('void Function()', 'void Function(int)');
  }

  test_functionType_30() {
    isSubtype2('int Function(int)', 'int Function(int)');
  }

  test_functionType_31() {
    isSubtype2('int Function(Object)', 'Object Function(int)');
  }

  test_functionType_32() {
    isNotSubtype2('int Function(int)', 'int Function(double)');
  }

  test_functionType_33() {
    isNotSubtype2('int Function()', 'int Function(int)');
  }

  test_functionType_34() {
    isNotSubtype2('int Function(int)', 'int Function(int, int)');
  }

  test_functionType_35() {
    isNotSubtype2('int Function(int, int)', 'int Function(int)');
  }

  test_functionType_36() {
    isNotSubtype2(
      'void Function(void Function())',
      'void Function(void Function(int))',
    );

    isNotSubtype2(
      'void Function(void Function(int))',
      'void Function(void Function())',
    );
  }

  test_functionType_37() {
    isSubtype2('void Function([int])', 'void Function()');
  }

  test_functionType_38() {
    isSubtype2('void Function([int])', 'void Function(int)');
  }

  test_functionType_39() {
    isNotSubtype2('void Function(int)', 'void Function([int])');
  }

  test_functionType_40() {
    isSubtype2('void Function([int])', 'void Function([int])');
  }

  test_functionType_41() {
    isSubtype2('void Function([Object])', 'void Function([int])');
  }

  test_functionType_42() {
    isNotSubtype2('void Function([int])', 'void Function([Object])');
  }

  test_functionType_43() {
    isSubtype2('void Function(int, [int])', 'void Function(int)');
  }

  test_functionType_44() {
    isSubtype2('void Function(int, [int])', 'void Function(int, [int])');
  }

  test_functionType_45() {
    isSubtype2('void Function([int, int])', 'void Function(int)');
  }

  test_functionType_46() {
    isSubtype2('void Function([int, int])', 'void Function(int, [int])');
  }

  test_functionType_47() {
    isNotSubtype2(
      'void Function([int, int])',
      'void Function(int, [int, int])',
    );
  }

  test_functionType_48() {
    isSubtype2(
      'void Function([int, int, int])',
      'void Function(int, [int, int])',
    );
  }

  test_functionType_49() {
    isNotSubtype2('void Function([int])', 'void Function(double)');
  }

  test_functionType_50() {
    isNotSubtype2('void Function([int])', 'void Function([int, int])');
  }

  test_functionType_51() {
    isSubtype2('void Function([int, int])', 'void Function([int])');
  }

  test_functionType_52() {
    isSubtype2('void Function([Object, int])', 'void Function([int])');
  }

  test_functionType_53() {
    isSubtype2('void Function({int a})', 'void Function()');
  }

  test_functionType_54() {
    isNotSubtype2('void Function({int a})', 'void Function(int)');
  }

  test_functionType_55() {
    isNotSubtype2('void Function(int)', 'void Function({int a})');
  }

  test_functionType_56() {
    isSubtype2('void Function({int a})', 'void Function({int a})');
  }

  test_functionType_57() {
    isNotSubtype2('void Function({int a})', 'void Function({int b})');
  }

  test_functionType_58() {
    isSubtype2('void Function({Object a})', 'void Function({int a})');
  }

  test_functionType_59() {
    isNotSubtype2('void Function({int a})', 'void Function({Object a})');
  }

  test_functionType_60() {
    isSubtype2('void Function(int, {int a})', 'void Function(int, {int a})');
  }

  test_functionType_61() {
    isNotSubtype2('void Function({int a})', 'void Function({double a})');
  }

  test_functionType_62() {
    isNotSubtype2('void Function({int a})', 'void Function({int a, int b})');
  }

  test_functionType_63() {
    isSubtype2('void Function({int a, int b})', 'void Function({int a})');
  }

  test_functionType_64() {
    isSubtype2(
      'void Function({int a, int b, int c})',
      'void Function({int a, int c})',
    );
  }

  test_functionType_66() {
    isSubtype2(
      'void Function({int a, int b, int c})',
      'void Function({int b, int c})',
    );
  }

  test_functionType_68() {
    isSubtype2(
      'void Function({int a, int b, int c})',
      'void Function({int c})',
    );
  }

  test_functionType_70() {
    isSubtype2('num Function(int)', 'Object');
  }

  test_functionType_71() {
    isSubtype2('num Function(int)', 'Object');
  }

  test_functionType_72() {
    isNotSubtype2('num Function(int)?', 'Object');
  }

  test_functionType_73() {
    isSubtype2(
      'void Function<E0 extends Object>()',
      'void Function<E1 extends FutureOr<Object>>()',
    );
  }

  test_functionType_74() {
    // Note, the order `R extends T`, then `T` is important.
    // We test that all type parameters replaced at once, not as we go.
    isSubtype2(
      'void Function<R extends T, T>()',
      'void Function<R extends T, T>()',
    );
  }

  test_functionType_generic_nested() {
    isSubtype2(
      'E0 Function(E0) Function<E0>(E0)',
      'F1 Function(F1) Function<F1>(F1)',
    );

    isSubtype2(
      'E0 Function<E0>(E0, E0 Function(int, E0))',
      'E1 Function<E1>(E1, E1 Function(num, E1))',
    );

    isNotSubtype2(
      'E0 Function(F0) Function<E0, F0>(E0)',
      'E1 Function<F1>(F1) Function<E1>(E1)',
    );

    isNotSubtype2(
      'E0 Function(F0) Function<E0, F0>(E0)',
      'E1 Function(F1) Function<F1, E1>(E1)',
    );
  }

  test_functionType_generic_required() {
    isSubtype2('int Function<E>(E)', 'num Function<E>(E)');

    isSubtype2('E Function<E>(num)', 'E Function<E>(int)');

    isSubtype2('E Function<E>(E, num)', 'E Function<E>(E, int)');

    isNotSubtype2('E Function<E>(E, num)', 'E Function<E>(E, E)');
  }

  test_functionType_notGeneric_functionReturnType() {
    isSubtype2(
      'num Function(num) Function(num)',
      'num Function(int) Function(num)',
    );

    isNotSubtype2(
      'int Function(int) Function(int)',
      'num Function(num) Function(num)',
    );
  }

  test_functionType_notGeneric_named() {
    isSubtype2('num Function({num x})', 'num Function({int x})');

    isSubtype2('num Function(num, {num x})', 'num Function(int, {int x})');

    isSubtype2('int Function({num x})', 'num Function({num x})');

    isNotSubtype2('int Function({int x})', 'num Function({num x})');
  }

  test_functionType_notGeneric_required() {
    isSubtype2('num Function(num)', 'num Function(int)');

    isSubtype2('int Function(num)', 'num Function(num)');

    isSubtype2('int Function(num)', 'num Function(int)');

    isNotSubtype2('int Function(int)', 'num Function(num)');

    isSubtype2('Null', 'num Function(int)?');
  }

  test_functionType_requiredNamedParameter_01() {
    isSubtype2('void Function({int a})', 'void Function({required int a})');

    isNotSubtype2('void Function({required int a})', 'void Function({int a})');
  }

  test_functionType_requiredNamedParameter_02() {
    isNotSubtype2('void Function({required int a})', 'void Function()');

    isNotSubtype2(
      'void Function({required int a, int b})',
      'void Function({int b})',
    );
  }

  test_functionType_requiredNamedParameter_03() {
    isSubtype2('void Function({int? a})', 'void Function({required int a})');

    isNotSubtype2('void Function({required int a})', 'void Function({int? a})');
  }

  test_futureOr_01() {
    isSubtype2('int', 'FutureOr<int>');
  }

  test_futureOr_02() {
    isSubtype2('int', 'FutureOr<num>');
  }

  test_futureOr_03() {
    isSubtype2('Future<int>', 'FutureOr<int>');
  }

  test_futureOr_04() {
    isSubtype2('Future<int>', 'FutureOr<num>');
  }

  test_futureOr_05() {
    isSubtype2('Future<int>', 'FutureOr<Object>');
  }

  test_futureOr_06() {
    isSubtype2('FutureOr<int>', 'FutureOr<int>');
  }

  test_futureOr_07() {
    isSubtype2('FutureOr<int>', 'FutureOr<num>');
  }

  test_futureOr_08() {
    isSubtype2('FutureOr<int>', 'Object');
  }

  test_futureOr_09() {
    isNotSubtype2('int', 'FutureOr<double>');
  }

  test_futureOr_10() {
    isNotSubtype2('FutureOr<double>', 'int');
  }

  test_futureOr_11() {
    isNotSubtype2('FutureOr<int>', 'Future<num>');
  }

  test_futureOr_12() {
    isNotSubtype2('FutureOr<int>', 'num');
  }

  test_futureOr_13() {
    isNotSubtype2('Null', 'FutureOr<int>');
  }

  test_futureOr_14() {
    isSubtype(
      parseType('Null'),
      parseType('Future<int>?'),
      strT0: 'Null',
      strT1: 'Future<int>?',
    );
  }

  test_futureOr_15() {
    isSubtype2('dynamic', 'FutureOr<dynamic>');
  }

  test_futureOr_16() {
    isNotSubtype2('dynamic', 'FutureOr<String>');
  }

  test_futureOr_17() {
    isSubtype2('void', 'FutureOr<void>');
  }

  test_futureOr_18() {
    isNotSubtype2('void', 'FutureOr<String>');
  }

  test_futureOr_19() {
    withTypeParameterScope('E', (scope) {
      isSubtype(
        scope.parseType('E'),
        scope.parseType('FutureOr<E>'),
        strT0: 'E',
        strT1: 'FutureOr<E>',
      );
    });
  }

  test_futureOr_20() {
    withTypeParameterScope('E', (scope) {
      isNotSubtype(
        scope.parseType('E'),
        _parseTestType('FutureOr<String>'),
        strT0: 'E',
        strT1: 'FutureOr<String>',
      );
    });
  }

  test_futureOr_21() {
    isSubtype2('String Function()', 'FutureOr<void Function()>');
  }

  test_futureOr_22() {
    isNotSubtype2('void Function()', 'FutureOr<String Function()>');
  }

  test_futureOr_23() {
    isNotSubtype2('FutureOr<num>', 'FutureOr<int>');
  }

  test_futureOr_24() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & int',
        strT1: 'FutureOr<num>',
      );
    });
  }

  test_futureOr_25() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & Future<num>'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & Future<num>',
        strT1: 'FutureOr<num>',
      );
    });
  }

  test_futureOr_26() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & Future<int>'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & Future<int>',
        strT1: 'FutureOr<num>',
      );
    });
  }

  test_futureOr_27() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & num'),
        _parseTestType('FutureOr<int>'),
        strT0: 'T & num',
        strT1: 'FutureOr<int>',
      );
    });
  }

  test_futureOr_28() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & Future<num>'),
        _parseTestType('FutureOr<int>'),
        strT0: 'T & Future<num>',
        strT1: 'FutureOr<int>',
      );
    });
  }

  test_futureOr_29() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & FutureOr<num>'),
        _parseTestType('FutureOr<int>'),
        strT0: 'T & FutureOr<num>',
        strT1: 'FutureOr<int>',
      );
    });
  }

  test_futureOr_30() {
    isSubtype2('FutureOr<Object>', 'FutureOr<FutureOr<Object>>');
  }

  test_interfaceType_01() {
    isSubtype(parseType('int'), parseType('int'), strT0: 'int', strT1: 'int');
  }

  test_interfaceType_02() {
    isSubtype(parseType('int'), parseType('num'), strT0: 'int', strT1: 'num');
  }

  test_interfaceType_03() {
    isSubtype(
      parseType('int'),
      parseType('Comparable<num>'),
      strT0: 'int',
      strT1: 'Comparable<num>',
    );
  }

  test_interfaceType_04() {
    isSubtype(
      parseType('int'),
      parseType('Object'),
      strT0: 'int',
      strT1: 'Object',
    );
  }

  test_interfaceType_05() {
    isSubtype(
      parseType('double'),
      parseType('num'),
      strT0: 'double',
      strT1: 'num',
    );
  }

  test_interfaceType_06() {
    isNotSubtype(
      parseType('int'),
      parseType('double'),
      strT0: 'int',
      strT1: 'double',
    );
  }

  test_interfaceType_07() {
    isNotSubtype(
      parseType('int'),
      parseType('Comparable<int>'),
      strT0: 'int',
      strT1: 'Comparable<int>',
    );
  }

  test_interfaceType_08() {
    isNotSubtype(
      parseType('int'),
      parseType('Iterable<int>'),
      strT0: 'int',
      strT1: 'Iterable<int>',
    );
  }

  test_interfaceType_09() {
    isNotSubtype(
      parseType('Comparable<int>'),
      parseType('Iterable<int>'),
      strT0: 'Comparable<int>',
      strT1: 'Iterable<int>',
    );
  }

  test_interfaceType_10() {
    isSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<int>'),
      strT0: 'List<int>',
      strT1: 'List<int>',
    );
  }

  test_interfaceType_11() {
    isSubtype(
      _parseTestType('List<int>'),
      parseType('Iterable<int>'),
      strT0: 'List<int>',
      strT1: 'Iterable<int>',
    );
  }

  test_interfaceType_12() {
    isSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<num>'),
      strT0: 'List<int>',
      strT1: 'List<num>',
    );
  }

  test_interfaceType_13() {
    isSubtype(
      _parseTestType('List<int>'),
      parseType('Iterable<num>'),
      strT0: 'List<int>',
      strT1: 'Iterable<num>',
    );
  }

  test_interfaceType_14() {
    isSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<Object>'),
      strT0: 'List<int>',
      strT1: 'List<Object>',
    );
  }

  test_interfaceType_15() {
    isSubtype(
      _parseTestType('List<int>'),
      parseType('Iterable<Object>'),
      strT0: 'List<int>',
      strT1: 'Iterable<Object>',
    );
  }

  test_interfaceType_16() {
    isSubtype(
      _parseTestType('List<int>'),
      parseType('Object'),
      strT0: 'List<int>',
      strT1: 'Object',
    );
  }

  test_interfaceType_17() {
    isSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<Comparable<Object>>'),
      strT0: 'List<int>',
      strT1: 'List<Comparable<Object>>',
    );
  }

  test_interfaceType_18() {
    isSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<Comparable<num>>'),
      strT0: 'List<int>',
      strT1: 'List<Comparable<num>>',
    );
  }

  test_interfaceType_19() {
    isSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<Comparable<Comparable<num>>>'),
      strT0: 'List<int>',
      strT1: 'List<Comparable<Comparable<num>>>',
    );
  }

  test_interfaceType_20() {
    isNotSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<double>'),
      strT0: 'List<int>',
      strT1: 'List<double>',
    );
  }

  test_interfaceType_21() {
    isNotSubtype(
      _parseTestType('List<int>'),
      parseType('Iterable<double>'),
      strT0: 'List<int>',
      strT1: 'Iterable<double>',
    );
  }

  test_interfaceType_22() {
    isNotSubtype(
      _parseTestType('List<int>'),
      _parseTestType('Comparable<int>'),
      strT0: 'List<int>',
      strT1: 'Comparable<int>',
    );
  }

  test_interfaceType_23() {
    isNotSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<Comparable<int>>'),
      strT0: 'List<int>',
      strT1: 'List<Comparable<int>>',
    );
  }

  test_interfaceType_24() {
    isNotSubtype(
      _parseTestType('List<int>'),
      _parseTestType('List<Comparable<Comparable<int>>>'),
      strT0: 'List<int>',
      strT1: 'List<Comparable<Comparable<int>>>',
    );
  }

  test_interfaceType_25_interfaces() {
    buildTestLibrary(
      classes: [ClassSpec('class I'), ClassSpec('class A implements I')],
    );
    var I = classElement('I');
    var A = classElement('A');

    var A_none = A.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var I_none = I.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_none, I_none, strT0: 'A', strT1: 'I');
    isNotSubtype(I_none, A_none, strT0: 'I', strT1: 'A');
  }

  test_interfaceType_26_mixins() {
    buildTestLibrary(
      classes: [ClassSpec('class M'), ClassSpec('class A with M')],
    );
    var M = classElement('M');
    var A = classElement('A');

    var A_none = A.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var M_none = M.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_none, M_none, strT0: 'A', strT1: 'M');
    isNotSubtype(M_none, A_none, strT0: 'M', strT1: 'A');
  }

  test_interfaceType_27() {
    isSubtype(
      parseType('num'),
      parseType('Object'),
      strT0: 'num',
      strT1: 'Object',
    );
  }

  test_interfaceType_28() {
    isSubtype(
      parseType('num'),
      parseType('Object'),
      strT0: 'num',
      strT1: 'Object',
    );
  }

  test_interfaceType_39() {
    withTypeParameterScope('T extends Object?', (scope) {
      isSubtype(
        scope.parseType('List<T & int>'),
        scope.parseType('List<T>'),
        strT0: 'List<T & int>, T extends Object?',
        strT1: 'List<T>, T extends Object?',
      );
    });
  }

  test_interfaceType_40() {
    withTypeParameterScope('T extends Object?', (scope) {
      isSubtype(
        scope.parseType('List<T & int?>'),
        scope.parseType('List<T>'),
        strT0: 'List<T & int?>, T extends Object?',
        strT1: 'List<T>, T extends Object?',
      );
    });
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_interfaceType_class_augmented_interfaces() {
    // var A = class_2(name: 'A');
    // var I = class_2(name: 'I');
    //
    // var A1 = class_(
    //   name: 'A',
    //   isAugmentation: true,
    //   interfaces: [parseInterfaceType('I')],
    // );
    // A.addAugmentations([A1]);
    //
    // var A_none = parseInterfaceType('A');
    // var I_none = parseInterfaceType('I');
    //
    // isSubtype(A_none, I_none, strT0: 'A', strT1: 'I');
    // isNotSubtype(I_none, A_none, strT0: 'I', strT1: 'A');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_interfaceType_class_augmented_mixins() {
    // var A = class_2(name: 'A');
    // var M = mixin_2(name: 'M');
    //
    // var A1 = class_(
    //   name: 'A',
    //   isAugmentation: true,
    //   mixins: [parseInterfaceType('M')],
    // );
    // A.addAugmentations([A1]);
    //
    // var A_none = parseInterfaceType('A');
    // var M_none = parseInterfaceType('M');
    //
    // isSubtype(A_none, M_none, strT0: 'A', strT1: 'M');
    // isNotSubtype(M_none, A_none, strT0: 'M', strT1: 'A');
  }

  test_interfaceType_contravariant() {
    buildTestLibrary(classes: [ClassSpec('class A<in T>')]);
    var A = classElement('A');

    var A_num = A.instantiateImpl(
      typeArguments: [parseType('num')],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiateImpl(
      typeArguments: [parseType('int')],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
  }

  test_interfaceType_covariant() {
    buildTestLibrary(classes: [ClassSpec('class A<out T>')]);
    var A = classElement('A');

    var A_num = A.instantiateImpl(
      typeArguments: [parseType('num')],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiateImpl(
      typeArguments: [parseType('int')],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
  }

  test_interfaceType_invariant() {
    buildTestLibrary(classes: [ClassSpec('class A<inout T>')]);
    var A = classElement('A');

    var A_num = A.instantiateImpl(
      typeArguments: [parseType('num')],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var A_int = A.instantiateImpl(
      typeArguments: [parseType('int')],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    isSubtype(A_num, A_num, strT0: "A<num>", strT1: "A<num>");
    isNotSubtype(A_int, A_num, strT0: "A<int>", strT1: "A<num>");
    isNotSubtype(A_num, A_int, strT0: "A<num>", strT1: "A<int>");
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_interfaceType_mixin_augmented_interfaces() {
    // var M = mixin_2(name: 'M');
    // var I = class_2(name: 'I');
    //
    // var M1 = mixin_(
    //   name: 'M1',
    //   isAugmentation: true,
    //   interfaces: [parseInterfaceType('I')],
    // );
    // M.addAugmentations([M1]);
    //
    // var M_none = parseInterfaceType('M');
    // var I_none = parseInterfaceType('I');
    //
    // isSubtype(M_none, I_none, strT0: 'M', strT1: 'I');
    // isNotSubtype(I_none, M_none, strT0: 'I', strT1: 'M');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_interfaceType_mixin_augmented_superclassConstraints() {
    // var M = mixin_2(name: 'M');
    // var C = class_2(name: 'C');
    //
    // var M1 = mixin_(
    //   name: 'M1',
    //   isAugmentation: true,
    //   constraints: [parseInterfaceType('C')],
    // );
    // M.addAugmentations([M1]);
    //
    // var M_none = parseInterfaceType('M');
    // var C_none = parseInterfaceType('C');
    //
    // isSubtype(M_none, C_none, strT0: 'M', strT1: 'C');
    // isNotSubtype(C_none, M_none, strT0: 'C', strT1: 'M');
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

    isNotSubtype2('Null', 'num Function(int)');
    isSubtype2('Null', 'num Function(int)?');

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
    isSubtype2('Null', 'FutureOr<num?>');
    isSubtype2('Null', 'FutureOr<num>?');
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
    isSubtype2('String Function()', 'FutureOr<void Function()>');

    isSubtype2('String Function()', 'FutureOr<void Function()>');

    isSubtype2('String Function()', 'FutureOr<void Function()?>');

    isSubtype2('String Function()', 'FutureOr<void Function()>?');

    isSubtype2('String Function()?', 'FutureOr<void Function()?>');

    isSubtype2('String Function()?', 'FutureOr<void Function()>?');

    isNotSubtype2('String Function()?', 'FutureOr<void Function()>');

    isNotSubtype2('void Function()', 'FutureOr<String Function()>');
  }

  test_multi_futureOr_typeParameter() {
    withTypeParameterScope('E extends Object', (scope) {
      isSubtype(
        scope.parseType('E'),
        scope.parseType('FutureOr<E>'),
        strT0: 'E, E extends Object',
        strT1: 'FutureOr<E>, E extends Object',
      );
    });

    withTypeParameterScope('E extends Object', (scope) {
      isSubtype(
        scope.parseType('E?'),
        scope.parseType('FutureOr<E>?'),
        strT0: 'E?, E extends Object',
        strT1: 'FutureOr<E>?, E extends Object',
      );
      isSubtype(
        scope.parseType('E?'),
        scope.parseType('FutureOr<E?>'),
        strT0: 'E?, E extends Object',
        strT1: 'FutureOr<E?>, E extends Object',
      );
      isNotSubtype(
        scope.parseType('E?'),
        scope.parseType('FutureOr<E>'),
        strT0: 'E?, E extends Object',
        strT1: 'FutureOr<E>, E extends Object',
      );
    });

    withTypeParameterScope('E extends Object?', (scope) {
      isSubtype(
        scope.parseType('E'),
        scope.parseType('FutureOr<E>?'),
        strT0: 'E, E extends Object?',
        strT1: 'FutureOr<E>?, E extends Object?',
      );
      isSubtype(
        scope.parseType('E'),
        scope.parseType('FutureOr<E?>'),
        strT0: 'E, E extends Object?',
        strT1: 'FutureOr<E?>, E extends Object?',
      );
      isSubtype(
        scope.parseType('E'),
        scope.parseType('FutureOr<E>'),
        strT0: 'E, E extends Object?',
        strT1: 'FutureOr<E>, E extends Object?',
      );
    });

    withTypeParameterScope('E extends Object', (scope) {
      isNotSubtype(
        scope.parseType('E'),
        _parseTestType('FutureOr<String>'),
        strT0: 'E, E extends Object',
        strT1: 'FutureOr<String>',
      );
    });

    withTypeParameterScope('E extends String', (scope) {
      isSubtype(
        scope.parseType('E?'),
        _parseTestType('FutureOr<String>?'),
        strT0: 'E?, E extends String',
        strT1: 'FutureOr<String>?',
      );
      isSubtype(
        scope.parseType('E?'),
        _parseTestType('FutureOr<String?>'),
        strT0: 'E?, E extends String',
        strT1: 'FutureOr<String?>',
      );
      isNotSubtype(
        scope.parseType('E?'),
        _parseTestType('FutureOr<String>'),
        strT0: 'E?, E extends String',
        strT1: 'FutureOr<String>',
      );
    });

    withTypeParameterScope('E extends String?', (scope) {
      isSubtype(
        scope.parseType('E'),
        _parseTestType('FutureOr<String>?'),
        strT0: 'E, E extends String?',
        strT1: 'FutureOr<String>?',
      );
      isSubtype(
        scope.parseType('E'),
        _parseTestType('FutureOr<String?>'),
        strT0: 'E, E extends String?',
        strT1: 'FutureOr<String?>',
      );
      isNotSubtype(
        scope.parseType('E'),
        _parseTestType('FutureOr<String>'),
        strT0: 'E, E extends String?',
        strT1: 'FutureOr<String>',
      );
    });
  }

  test_multi_futureOr_typeParameter_promotion() {
    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & int, T extends Object',
        strT1: 'FutureOr<num>',
      );
      isSubtype(
        scope.parseType('T & int'),
        _parseTestType('FutureOr<num?>'),
        strT0: 'T & int, T extends Object',
        strT1: 'FutureOr<num?>',
      );
      isSubtype(
        scope.parseType('T & int'),
        _parseTestType('FutureOr<num>?'),
        strT0: 'T & int, T extends Object',
        strT1: 'FutureOr<num>?',
      );
    });

    withTypeParameterScope('T extends Object?', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & int, T extends Object?',
        strT1: 'FutureOr<num>',
      );
      isSubtype(
        scope.parseType('T & int'),
        _parseTestType('FutureOr<num?>'),
        strT0: 'T & int, T extends Object?',
        strT1: 'FutureOr<num?>',
      );
      isSubtype(
        scope.parseType('T & int'),
        _parseTestType('FutureOr<num>?'),
        strT0: 'T & int, T extends Object?',
        strT1: 'FutureOr<num>?',
      );
    });

    withTypeParameterScope('T extends Object?', (scope) {
      isNotSubtype(
        scope.parseType('T & int?'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & int?, T extends Object?',
        strT1: 'FutureOr<num>',
      );
      isSubtype(
        scope.parseType('T & int?'),
        _parseTestType('FutureOr<num?>'),
        strT0: 'T & int?, T extends Object?',
        strT1: 'FutureOr<num?>',
      );
      isSubtype(
        scope.parseType('T & int?'),
        _parseTestType('FutureOr<num>?'),
        strT0: 'T & int?, T extends Object?',
        strT1: 'FutureOr<num>?',
      );
    });

    withTypeParameterScope('T extends Object?, S extends T', (scope) {
      isNotSubtype(
        scope.parseType('T & S'),
        _parseTestType('FutureOr<Object>'),
        strT0: 'T & S, T extends Object?',
        strT1: 'FutureOr<Object>',
      );
      isSubtype(
        scope.parseType('T & S'),
        _parseTestType('FutureOr<Object?>'),
        strT0: 'T & S, T extends Object?',
        strT1: 'FutureOr<Object?>',
      );
      isSubtype(
        scope.parseType('T & S'),
        _parseTestType('FutureOr<Object>?'),
        strT0: 'T & S, T extends Object?',
        strT1: 'FutureOr<Object>?',
      );
    });

    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        scope.parseType('T & Future<num>'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & Future<num>, T extends Object',
        strT1: 'FutureOr<num>',
      );
      isSubtype(
        scope.parseType('T & Future<int>'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & Future<int>, T extends Object',
        strT1: 'FutureOr<num>',
      );
    });

    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        scope.parseType('T & Future<int>'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & Future<int>, T extends Object',
        strT1: 'FutureOr<num>',
      );
      isSubtype(
        scope.parseType('T & Future<int>'),
        _parseTestType('FutureOr<num?>'),
        strT0: 'T & Future<int>, T extends Object',
        strT1: 'FutureOr<num?>',
      );
      isSubtype(
        scope.parseType('T & Future<int>'),
        _parseTestType('FutureOr<num>?'),
        strT0: 'T & Future<int>, T extends Object',
        strT1: 'FutureOr<num>?',
      );
    });

    withTypeParameterScope('T extends Object?', (scope) {
      isSubtype(
        scope.parseType('T & Future<int>'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & Future<int>, T extends Object?',
        strT1: 'FutureOr<num>',
      );
      isSubtype(
        scope.parseType('T & Future<int>'),
        _parseTestType('FutureOr<num?>'),
        strT0: 'T & Future<int>, T extends Object?',
        strT1: 'FutureOr<num?>',
      );
      isSubtype(
        scope.parseType('T & Future<int>'),
        _parseTestType('FutureOr<num>?'),
        strT0: 'T & Future<int>, T extends Object?',
        strT1: 'FutureOr<num>?',
      );

      isNotSubtype(
        scope.parseType('T & Future<int>?'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & Future<int>?, T extends Object?',
        strT1: 'FutureOr<num>',
      );
      isSubtype(
        scope.parseType('T & Future<int>?'),
        _parseTestType('FutureOr<num?>'),
        strT0: 'T & Future<int>?, T extends Object?',
        strT1: 'FutureOr<num?>',
      );
      isSubtype(
        scope.parseType('T & Future<int>?'),
        _parseTestType('FutureOr<num>?'),
        strT0: 'T & Future<int>?, T extends Object?',
        strT1: 'FutureOr<num>?',
      );
    });

    withTypeParameterScope('T extends Object', (scope) {
      isNotSubtype(
        scope.parseType('T & Future<int?>'),
        _parseTestType('FutureOr<num>'),
        strT0: 'T & Future<int?>, T extends Object',
        strT1: 'FutureOr<num>',
      );
      isSubtype(
        scope.parseType('T & Future<int?>'),
        _parseTestType('FutureOr<num?>'),
        strT0: 'T & Future<int?>, T extends Object',
        strT1: 'FutureOr<num?>',
      );
      isNotSubtype(
        scope.parseType('T & Future<int?>'),
        _parseTestType('FutureOr<num>?'),
        strT0: 'T & Future<int?>, T extends Object',
        strT1: 'FutureOr<num>?',
      );
    });
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
    isNotSubtype2('Null', 'List<int>');
    isSubtype2('Null', 'List<int>?');
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
    isSubtype2('Null', 'num?');
    isSubtype2('Never', 'num');
    isSubtype2('Never', 'num?');

    isNotSubtype2('int', 'double');
    isNotSubtype2('int', 'Comparable<int>');
    isNotSubtype2('int', 'Iterable<int>');
    isNotSubtype2('Comparable<int>', 'Iterable<int>');
    isNotSubtype2('num?', 'Object');
    isNotSubtype2('Null', 'num');
    isNotSubtype2('num', 'Never');
  }

  test_multi_object_topAndBottom() {
    isSubtype2('Never', 'Object');
    isSubtype2('Object', 'dynamic');
    isSubtype2('Object', 'void');
    isSubtype2('Object', 'Object?');

    isNotSubtype2('Object', 'Never');
    isNotSubtype2('Object', 'Null');
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
    isSubtype2('Null', 'Null');
    isSubtype2('Never', 'Null');
    isSubtype2('Never', 'Never');
    isNotSubtype2('Null', 'Never');

    isSubtype2('Null', 'Never?');
    isSubtype2('Never?', 'Null');
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
    isSubtype2('Null', 'Object?');
    isSubtype2('Null', 'dynamic');
    isSubtype2('Null', 'void');

    isNotSubtype2('Object?', 'Never');
    isNotSubtype2('Object?', 'Null');
    isNotSubtype2('dynamic', 'Never');
    isNotSubtype2('dynamic', 'Null');
    isNotSubtype2('void', 'Never');
    isNotSubtype2('void', 'Null');
  }

  test_multi_typeParameter_promotion() {
    withTypeParameterScope('T extends int', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T & int'),
        strT0: 'T, T extends int',
        strT1: 'T & int, T extends int',
      );
      isNotSubtype(
        scope.parseType('T?'),
        scope.parseType('T & int'),
        strT0: 'T?, T extends int',
        strT1: 'T & int, T extends int',
      );
    });

    withTypeParameterScope('T extends int?', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        scope.parseType('T & int'),
        strT0: 'T, T extends int?',
        strT1: 'T & int, T extends int?',
      );
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T & int?'),
        strT0: 'T, T extends int?',
        strT1: 'T & int?, T extends int?',
      );
      isNotSubtype(
        scope.parseType('T?'),
        scope.parseType('T & int?'),
        strT0: 'T?, T extends int?',
        strT1: 'T & int?, T extends int?',
      );
    });

    withTypeParameterScope('T extends num', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T'),
        strT0: 'T, T extends num',
        strT1: 'T, T extends num',
      );
      isSubtype(
        scope.parseType('T?'),
        scope.parseType('T?'),
        strT0: 'T?, T extends num',
        strT1: 'T?, T extends num',
      );
    });

    withTypeParameterScope('T extends num?', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T'),
        strT0: 'T, T extends num?',
        strT1: 'T, T extends num?',
      );
      isSubtype(
        scope.parseType('T?'),
        scope.parseType('T?'),
        strT0: 'T?, T extends num?',
        strT1: 'T?, T extends num?',
      );
    });
  }

  test_never_01() {
    isSubtype(
      parseType('Never'),
      parseType('Never'),
      strT0: 'Never',
      strT1: 'Never',
    );
  }

  test_never_02() {
    isSubtype(
      parseType('Never'),
      parseType('num'),
      strT0: 'Never',
      strT1: 'num',
    );
  }

  test_never_04() {
    isSubtype(
      parseType('Never'),
      parseType('num?'),
      strT0: 'Never',
      strT1: 'num?',
    );
  }

  test_never_05() {
    isNotSubtype(
      parseType('num'),
      parseType('Never'),
      strT0: 'num',
      strT1: 'Never',
    );
  }

  test_never_06() {
    isSubtype(
      parseType('Never'),
      _parseTestType('List<int>'),
      strT0: 'Never',
      strT1: 'List<int>',
    );
  }

  test_never_09() {
    isNotSubtype(
      parseType('num'),
      parseType('Never'),
      strT0: 'num',
      strT1: 'Never',
    );
  }

  test_never_15() {
    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        parseType('Never'),
        scope.parseType('T & num'),
        strT0: 'Never',
        strT1: 'T & num, T extends Object',
      );
    });
  }

  test_never_16() {
    withTypeParameterScope('T extends Object', (scope) {
      isNotSubtype(
        scope.parseType('T & num'),
        parseType('Never'),
        strT0: 'T & num, T extends Object',
        strT1: 'Never',
      );
    });
  }

  test_never_17() {
    withTypeParameterScope('T extends Never', (scope) {
      isSubtype(
        scope.parseType('T'),
        parseType('Never'),
        strT0: 'T, T extends Never',
        strT1: 'Never',
      );
    });
  }

  test_never_18() {
    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        scope.parseType('T & Never'),
        parseType('Never'),
        strT0: 'T & Never, T extends Object',
        strT1: 'Never',
      );
    });
  }

  test_never_19() {
    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        parseType('Never'),
        scope.parseType('T?'),
        strT0: 'Never',
        strT1: 'T?, T extends Object',
      );
    });
  }

  test_never_20() {
    withTypeParameterScope('T extends Object?', (scope) {
      isSubtype(
        parseType('Never'),
        scope.parseType('T?'),
        strT0: 'Never',
        strT1: 'T?, T extends Object?',
      );
    });
  }

  test_never_21() {
    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        parseType('Never'),
        scope.parseType('T'),
        strT0: 'Never',
        strT1: 'T, T extends Object',
      );
    });
  }

  test_never_22() {
    withTypeParameterScope('T extends Object?', (scope) {
      isSubtype(
        parseType('Never'),
        scope.parseType('T'),
        strT0: 'Never',
        strT1: 'T, T extends Object?',
      );
    });
  }

  test_never_23() {
    withTypeParameterScope('T extends Never', (scope) {
      isSubtype(
        scope.parseType('T'),
        parseType('Never'),
        strT0: 'T, T extends Never',
        strT1: 'Never',
      );
    });
  }

  test_never_24() {
    withTypeParameterScope('T extends Never?', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        parseType('Never'),
        strT0: 'T, T extends Never?',
        strT1: 'Never',
      );
    });
  }

  test_never_25() {
    withTypeParameterScope('T extends Never', (scope) {
      isNotSubtype(
        scope.parseType('T?'),
        parseType('Never'),
        strT0: 'T?, T extends Never',
        strT1: 'Never',
      );
    });
  }

  test_never_26() {
    withTypeParameterScope('T extends Never?', (scope) {
      isNotSubtype(
        scope.parseType('T?'),
        parseType('Never'),
        strT0: 'T?, T extends Never?',
        strT1: 'Never',
      );
    });
  }

  test_never_27() {
    withTypeParameterScope('T extends Object', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        parseType('Never'),
        strT0: 'T, T extends Object',
        strT1: 'Never',
      );
    });
  }

  test_never_28() {
    withTypeParameterScope('T extends Object?', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        parseType('Never'),
        strT0: 'T, T extends Object?',
        strT1: 'Never',
      );
    });
  }

  test_never_29() {
    isSubtype(
      parseType('Never'),
      parseType('Null'),
      strT0: 'Never',
      strT1: 'Null',
    );
  }

  test_null_01() {
    isNotSubtype(
      parseType('Null'),
      parseType('Never'),
      strT0: 'Null',
      strT1: 'Never',
    );
  }

  test_null_02() {
    isNotSubtype(
      parseType('Null'),
      parseType('Object'),
      strT0: 'Null',
      strT1: 'Object',
    );
  }

  test_null_03() {
    isSubtype(
      parseType('Null'),
      parseType('void'),
      strT0: 'Null',
      strT1: 'void',
    );
  }

  test_null_04() {
    isSubtype(
      parseType('Null'),
      parseType('dynamic'),
      strT0: 'Null',
      strT1: 'dynamic',
    );
  }

  test_null_05() {
    isNotSubtype(
      parseType('Null'),
      parseType('double'),
      strT0: 'Null',
      strT1: 'double',
    );
  }

  test_null_06() {
    isSubtype(
      parseType('Null'),
      parseType('double?'),
      strT0: 'Null',
      strT1: 'double?',
    );
  }

  test_null_07() {
    isNotSubtype(
      parseType('Null'),
      _parseTestType('Comparable<Object>'),
      strT0: 'Null',
      strT1: 'Comparable<Object>',
    );
  }

  test_null_08() {
    withTypeParameterScope('T extends Object', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T'),
        strT0: 'Null',
        strT1: 'T, T extends Object',
      );
    });
  }

  test_null_09() {
    isSubtype(
      parseType('Null'),
      parseType('Null'),
      strT0: 'Null',
      strT1: 'Null',
    );
  }

  test_null_10() {
    isNotSubtype(
      parseType('Null'),
      _parseTestType('List<int>'),
      strT0: 'Null',
      strT1: 'List<int>',
    );
  }

  test_null_13() {
    isNotSubtype2('Null', 'num Function(int)');
  }

  test_null_14() {
    isNotSubtype2('Null', 'num Function(int)');
  }

  test_null_15() {
    isSubtype2('Null', 'num Function(int)?');
  }

  test_null_16() {
    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        parseType('Null'),
        scope.parseType('(T & num)?'),
        strT0: 'Null',
        strT1: '(T & num)?, T extends Object',
      );
    });
  }

  test_null_17() {
    withTypeParameterScope('T extends Object?', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T & num'),
        strT0: 'Null',
        strT1: 'T & num, T extends Object?',
      );
    });
  }

  test_null_18() {
    withTypeParameterScope('T extends Object?', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T & num?'),
        strT0: 'Null',
        strT1: 'T & num?, T extends Object?',
      );
    });
  }

  test_null_19() {
    withTypeParameterScope('T extends Object', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T & num'),
        strT0: 'Null',
        strT1: 'T & num, T extends Object',
      );
    });
  }

  test_null_20() {
    withTypeParameterScope('T extends Object?, S extends T', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T & S'),
        strT0: 'Null',
        strT1: 'T & S, T extends Object?',
      );
    });
  }

  test_null_21() {
    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        parseType('Null'),
        scope.parseType('T?'),
        strT0: 'Null',
        strT1: 'T?, T extends Object',
      );
    });
  }

  test_null_22() {
    withTypeParameterScope('T extends Object?', (scope) {
      isSubtype(
        parseType('Null'),
        scope.parseType('T?'),
        strT0: 'Null',
        strT1: 'T?, T extends Object?',
      );
    });
  }

  test_null_23() {
    withTypeParameterScope('T extends Object', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T'),
        strT0: 'Null',
        strT1: 'T, T extends Object',
      );
    });
  }

  test_null_24() {
    withTypeParameterScope('T extends Object?', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T'),
        strT0: 'Null',
        strT1: 'T, T extends Object?',
      );
    });
  }

  test_null_25() {
    withTypeParameterScope('T extends Null', (scope) {
      isSubtype(
        scope.parseType('T'),
        parseType('Null'),
        strT0: 'T, T extends Null',
        strT1: 'Null',
      );
    });
  }

  test_null_26() {
    withTypeParameterScope('T extends Null', (scope) {
      isSubtype(
        scope.parseType('T?'),
        parseType('Null'),
        strT0: 'T?, T extends Null',
        strT1: 'Null',
      );
    });
  }

  test_null_27() {
    withTypeParameterScope('T extends Object', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        parseType('Null'),
        strT0: 'T, T extends Object',
        strT1: 'Null',
      );
    });
  }

  test_null_28() {
    withTypeParameterScope('T extends Object?', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        parseType('Null'),
        strT0: 'T, T extends Object?',
        strT1: 'Null',
      );
    });
  }

  test_null_29() {
    isSubtype(
      parseType('Null'),
      _parseTestType('Comparable<Object>?'),
      strT0: 'Null',
      strT1: 'Comparable<Object>?',
    );
  }

  test_null_30() {
    isNotSubtype(
      parseType('Null'),
      parseType('Object'),
      strT0: 'Null',
      strT1: 'Object',
    );
  }

  test_nullabilitySuffix_01() {
    isSubtype(parseType('int'), parseType('int'), strT0: 'int', strT1: 'int');
    isSubtype(parseType('int'), parseType('int?'), strT0: 'int', strT1: 'int?');

    isNotSubtype(
      parseType('int?'),
      parseType('int'),
      strT0: 'int?',
      strT1: 'int',
    );
    isSubtype(
      parseType('int?'),
      parseType('int?'),
      strT0: 'int?',
      strT1: 'int?',
    );

    isSubtype(parseType('int'), parseType('int'), strT0: 'int', strT1: 'int');
    isSubtype(parseType('int'), parseType('int?'), strT0: 'int', strT1: 'int?');
  }

  test_nullabilitySuffix_05() {
    isSubtype2('void Function(int)', 'Object');
  }

  test_nullabilitySuffix_11() {
    isSubtype(
      parseType('int?'),
      parseType('int?'),
      strT0: 'int?',
      strT1: 'int?',
    );
  }

  test_nullabilitySuffix_12() {
    isSubtype(parseType('int'), parseType('int'), strT0: 'int', strT1: 'int');
  }

  test_nullabilitySuffix_13() {
    isSubtype2('int Function(int)?', 'int Function(int)?');
  }

  test_nullabilitySuffix_14() {
    isSubtype2('int Function(int)', 'int Function(int)');
  }

  test_nullabilitySuffix_15() {
    isSubtype2(
      'int? Function(int, int, int?)',
      'int? Function(int, int, int?)',
    );
  }

  test_nullabilitySuffix_16() {
    var type = _parseTestType('List<int>?');
    isSubtype(type, type, strT0: 'List<int>?', strT1: 'List<int>?');
  }

  test_nullabilitySuffix_17() {
    var type = _parseTestType('List<int?>?');
    isSubtype(type, type, strT0: 'List<int?>?', strT1: 'List<int?>?');
  }

  test_nullabilitySuffix_18() {
    withTypeParameterScope('T extends Object', (scope) {
      var type = scope.parseType('T & int?');
      isSubtype(
        type,
        type,
        strT0: 'T & int?, T extends Object',
        strT1: 'T & int?, T extends Object',
      );
    });
  }

  test_nullabilitySuffix_19() {
    withTypeParameterScope('T extends Object', (scope) {
      var type = scope.parseType('(T & int?)?');
      isSubtype(
        type,
        type,
        strT0: '(T & int?)?, T extends Object',
        strT1: '(T & int?)?, T extends Object',
      );
    });
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
    void check(RecordTypeImpl subType, RecordTypeImpl superType) {
      isSubtype(subType, superType);
      isSubtype(superType, subType);
    }

    check(
      parseRecordType('({int f1, int f2, int f3, int f4})'),
      parseRecordType('({int f4, int f3, int f2, int f1})'),
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
      parseType('Record'),
      parseType('Object'),
      strT0: 'Record',
      strT1: 'Object',
    );

    isSubtype(
      parseType('Record'),
      parseType('dynamic'),
      strT0: 'Record',
      strT1: 'dynamic',
    );

    isSubtype(
      parseType('Never'),
      parseType('Record'),
      strT0: 'Never',
      strT1: 'Record',
    );
  }

  test_special_01() {
    isNotSubtype(
      parseType('dynamic'),
      parseType('int'),
      strT0: 'dynamic',
      strT1: 'int',
    );
  }

  test_special_02() {
    isNotSubtype(
      parseType('void'),
      parseType('int'),
      strT0: 'void',
      strT1: 'int',
    );
  }

  test_special_03() {
    isNotSubtype2('int Function()', 'int');
  }

  test_special_04() {
    isNotSubtype2('int', 'int Function()');
  }

  test_special_06() {
    isSubtype2('int Function()', 'Object');
  }

  test_special_07() {
    isSubtype(
      parseType('Object'),
      parseType('Object'),
      strT0: 'Object',
      strT1: 'Object',
    );
  }

  test_special_08() {
    isSubtype(
      parseType('Object'),
      parseType('dynamic'),
      strT0: 'Object',
      strT1: 'dynamic',
    );
  }

  test_special_09() {
    isSubtype(
      parseType('Object'),
      parseType('void'),
      strT0: 'Object',
      strT1: 'void',
    );
  }

  test_special_10() {
    isNotSubtype(
      parseType('dynamic'),
      parseType('Object'),
      strT0: 'dynamic',
      strT1: 'Object',
    );
  }

  test_special_11() {
    isSubtype(
      parseType('dynamic'),
      parseType('dynamic'),
      strT0: 'dynamic',
      strT1: 'dynamic',
    );
  }

  test_special_12() {
    isSubtype(
      parseType('dynamic'),
      parseType('void'),
      strT0: 'dynamic',
      strT1: 'void',
    );
  }

  test_special_13() {
    isNotSubtype(
      parseType('void'),
      parseType('Object'),
      strT0: 'void',
      strT1: 'Object',
    );
  }

  test_special_14() {
    isSubtype(
      parseType('void'),
      parseType('dynamic'),
      strT0: 'void',
      strT1: 'dynamic',
    );
  }

  test_special_15() {
    isSubtype(
      parseType('void'),
      parseType('void'),
      strT0: 'void',
      strT1: 'void',
    );
  }

  test_top_03() {
    var f0 = parseFunctionType('T0 Function<T0 extends dynamic>()');
    var f1 = parseFunctionType('T2 Function<T2 extends void>()');

    isSubtype(f0, f1);
    isSubtype(f1, f0);
  }

  test_top_04() {
    isNotSubtype2('dynamic', 'dynamic Function()');
  }

  test_top_05() {
    isNotSubtype2('FutureOr<void Function()>', 'void Function()');
  }

  test_top_06() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & void Function()'),
        parseFunctionType('void Function()'),
        strT0: 'T & void Function()',
        strT1: 'void Function()',
      );
    });
  }

  test_top_07() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & void Function()'),
        parseFunctionType('dynamic Function()'),
        strT0: 'T & void Function()',
        strT1: 'dynamic Function()',
      );
    });
  }

  test_top_08() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & void Function()'),
        parseFunctionType('Object Function()'),
        strT0: 'T & void Function()',
        strT1: 'Object Function()',
      );
    });
  }

  test_top_09() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & void Function(void)'),
        parseFunctionType('void Function(void)'),
        strT0: 'T & void Function(void)',
        strT1: 'void Function(void)',
      );
    });
  }

  test_top_10() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & void Function(void)'),
        parseFunctionType('dynamic Function(dynamic)'),
        strT0: 'T & void Function(void)',
        strT1: 'dynamic Function(dynamic)',
      );
    });
  }

  test_top_11() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & void Function(void)'),
        parseFunctionType('Object Function(Object)'),
        strT0: 'T & void Function(void)',
        strT1: 'Object Function(Object)',
      );
    });
  }

  test_top_12() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & void Function(void)'),
        parseFunctionType('dynamic Function(Iterable<int>)'),
        strT0: 'T & void Function(void)',
        strT1: 'dynamic Function(Iterable<int>)',
      );
    });
  }

  test_top_13() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & void Function(void)'),
        parseFunctionType('Object Function(int)'),
        strT0: 'T & void Function(void)',
        strT1: 'Object Function(int)',
      );
    });
  }

  test_top_14() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & void Function(void)'),
        parseFunctionType('int Function(int)'),
        strT0: 'T & void Function(void)',
        strT1: 'int Function(int)',
      );
    });
  }

  test_top_15() {
    withTypeParameterScope('T extends void Function()', (scope) {
      isSubtype(
        scope.parseType('T'),
        parseFunctionType('void Function()'),
        strT0: 'T, T extends void Function()',
        strT1: 'void Function()',
      );
    });
  }

  test_top_16() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        parseFunctionType('void Function()'),
        strT0: 'T',
        strT1: 'void Function()',
      );
    });
  }

  test_top_17() {
    isNotSubtype(
      parseType('void'),
      parseFunctionType('void Function()'),
      strT0: 'void',
      strT1: 'void Function()',
    );
  }

  test_top_18() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        parseType('dynamic'),
        scope.parseType('T'),
        strT0: 'dynamic',
        strT1: 'T',
      );
    });
  }

  test_top_19() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('Iterable<T>'),
        scope.parseType('T'),
        strT0: 'Iterable<T>',
        strT1: 'T',
      );
    });
  }

  test_top_21() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        parseFunctionType('void Function()'),
        scope.parseType('T'),
        strT0: 'void Function()',
        strT1: 'T',
      );
    });
  }

  test_top_22() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('FutureOr<T>'),
        scope.parseType('T'),
        strT0: 'FutureOr<T>',
        strT1: 'T',
      );
    });
  }

  test_top_23() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        parseType('void'),
        scope.parseType('T'),
        strT0: 'void',
        strT1: 'T',
      );
    });
  }

  test_top_24() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        parseType('void'),
        scope.parseType('T & void'),
        strT0: 'void',
        strT1: 'T & void',
      );
    });
  }

  test_top_25() {
    withTypeParameterScope('T extends void', (scope) {
      isNotSubtype(
        parseType('void'),
        scope.parseType('T & void'),
        strT0: 'void',
        strT1: 'T & void, T extends void',
      );
    });
  }

  test_typeParameter_01() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        scope.parseType('T & int'),
        strT0: 'T & int',
        strT1: 'T & int',
      );
    });
  }

  test_typeParameter_02() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        scope.parseType('T & num'),
        strT0: 'T & int',
        strT1: 'T & num',
      );
    });
  }

  test_typeParameter_03() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & num'),
        scope.parseType('T & num'),
        strT0: 'T & num',
        strT1: 'T & num',
      );
    });
  }

  test_typeParameter_04() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & num'),
        scope.parseType('T & int'),
        strT0: 'T & num',
        strT1: 'T & int',
      );
    });
  }

  test_typeParameter_05() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T & num'),
        strT0: 'Null',
        strT1: 'T & num',
      );
    });
  }

  test_typeParameter_06() {
    withTypeParameterScope('T extends int', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        scope.parseType('T'),
        strT0: 'T & int, T extends int',
        strT1: 'T, T extends int',
      );
    });
  }

  test_typeParameter_07() {
    withTypeParameterScope('T extends num', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        scope.parseType('T'),
        strT0: 'T & int, T extends num',
        strT1: 'T, T extends num',
      );
    });
  }

  test_typeParameter_08() {
    withTypeParameterScope('T extends num', (scope) {
      isSubtype(
        scope.parseType('T & num'),
        scope.parseType('T'),
        strT0: 'T & num, T extends num',
        strT1: 'T, T extends num',
      );
    });
  }

  test_typeParameter_09() {
    withTypeParameterScope('T extends int', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T & int'),
        strT0: 'T, T extends int',
        strT1: 'T & int, T extends int',
      );
    });
  }

  test_typeParameter_10() {
    withTypeParameterScope('T extends int', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T & num'),
        strT0: 'T, T extends int',
        strT1: 'T & num, T extends int',
      );
    });
  }

  test_typeParameter_11() {
    withTypeParameterScope('T extends num', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        scope.parseType('T & int'),
        strT0: 'T, T extends num',
        strT1: 'T & int, T extends num',
      );
    });
  }

  test_typeParameter_12() {
    withTypeParameterScope('T extends num', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T'),
        strT0: 'T, T extends num',
        strT1: 'T, T extends num',
      );
    });
  }

  test_typeParameter_13() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T'),
        strT0: 'T',
        strT1: 'T',
      );
    });
  }

  test_typeParameter_14() {
    withTypeParameterScope('S, T', (scope) {
      isNotSubtype(
        scope.parseType('S'),
        scope.parseType('T'),
        strT0: 'S',
        strT1: 'T',
      );
    });
  }

  test_typeParameter_15() {
    withTypeParameterScope('T extends Object', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T'),
        strT0: 'T, T extends Object',
        strT1: 'T, T extends Object',
      );
    });
  }

  test_typeParameter_16() {
    withTypeParameterScope('S extends Object, T extends Object', (scope) {
      isNotSubtype(
        scope.parseType('S'),
        scope.parseType('T'),
        strT0: 'S, S extends Object',
        strT1: 'T, T extends Object',
      );
    });
  }

  test_typeParameter_17() {
    withTypeParameterScope('T extends dynamic', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('T'),
        strT0: 'T, T extends dynamic',
        strT1: 'T, T extends dynamic',
      );
    });
  }

  test_typeParameter_18() {
    withTypeParameterScope('S extends dynamic, T extends dynamic', (scope) {
      isNotSubtype(
        scope.parseType('S'),
        scope.parseType('T'),
        strT0: 'S, S extends dynamic',
        strT1: 'T, T extends dynamic',
      );
    });
  }

  test_typeParameter_19() {
    withTypeParameterScope('S, T extends S', (scope) {
      isNotSubtype(
        scope.parseType('S'),
        scope.parseType('T'),
        strT0: 'S',
        strT1: 'T, T extends S',
      );

      isSubtype(
        scope.parseType('T'),
        scope.parseType('S'),
        strT0: 'T, T extends S',
        strT1: 'S',
      );
    });
  }

  test_typeParameter_20() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        parseType('int'),
        strT0: 'T & int',
        strT1: 'int',
      );
    });
  }

  test_typeParameter_21() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & int'),
        parseType('num'),
        strT0: 'T & int',
        strT1: 'num',
      );
    });
  }

  test_typeParameter_22() {
    withTypeParameterScope('T', (scope) {
      isSubtype(
        scope.parseType('T & num'),
        parseType('num'),
        strT0: 'T & num',
        strT1: 'num',
      );
    });
  }

  test_typeParameter_23() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T & num'),
        parseType('int'),
        strT0: 'T & num',
        strT1: 'int',
      );
    });
  }

  test_typeParameter_24() {
    withTypeParameterScope('S, T', (scope) {
      isNotSubtype(
        scope.parseType('S & num'),
        scope.parseType('T'),
        strT0: 'S & num',
        strT1: 'T',
      );
    });
  }

  test_typeParameter_25() {
    withTypeParameterScope('S, T', (scope) {
      isNotSubtype(
        scope.parseType('S & num'),
        scope.parseType('T & num'),
        strT0: 'S & num',
        strT1: 'T & num',
      );
    });
  }

  test_typeParameter_26() {
    withTypeParameterScope('S extends int', (scope) {
      isSubtype(
        scope.parseType('S'),
        parseType('int'),
        strT0: 'S, S extends int',
        strT1: 'int',
      );
    });
  }

  test_typeParameter_27() {
    withTypeParameterScope('S extends int', (scope) {
      isSubtype(
        scope.parseType('S'),
        parseType('num'),
        strT0: 'S, S extends int',
        strT1: 'num',
      );
    });
  }

  test_typeParameter_28() {
    withTypeParameterScope('S extends num', (scope) {
      isSubtype(
        scope.parseType('S'),
        parseType('num'),
        strT0: 'S, S extends num',
        strT1: 'num',
      );
    });
  }

  test_typeParameter_29() {
    withTypeParameterScope('S extends num', (scope) {
      isNotSubtype(
        scope.parseType('S'),
        parseType('int'),
        strT0: 'S, S extends num',
        strT1: 'int',
      );
    });
  }

  test_typeParameter_30() {
    withTypeParameterScope('S extends num, T', (scope) {
      isNotSubtype(
        scope.parseType('S'),
        scope.parseType('T'),
        strT0: 'S, S extends num',
        strT1: 'T',
      );
    });
  }

  test_typeParameter_31() {
    withTypeParameterScope('S extends num, T', (scope) {
      isNotSubtype(
        scope.parseType('S'),
        scope.parseType('T & num'),
        strT0: 'S, S extends num',
        strT1: 'T & num',
      );
    });
  }

  test_typeParameter_32() {
    withTypeParameterScope('T extends dynamic', (scope) {
      isNotSubtype(
        parseType('dynamic'),
        scope.parseType('T & dynamic'),
        strT0: 'dynamic',
        strT1: 'T & dynamic, T extends dynamic',
      );
    });
  }

  test_typeParameter_33() {
    withTypeParameterScope('T', (scope) {
      var tFunction = scope.parseType('T Function()');
      isNotSubtype(
        tFunction,
        scope.parseType('T & T Function()'),
        strT0: 'T Function()',
        strT1: 'T & T Function()',
      );
    });
  }

  test_typeParameter_34() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('FutureOr<T & String>'),
        scope.parseType('T & String'),
        strT0: 'FutureOr<T & String>',
        strT1: 'T & String',
      );
    });
  }

  test_typeParameter_35() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        parseType('Null'),
        scope.parseType('T'),
        strT0: 'Null',
        strT1: 'T',
      );
    });
  }

  test_typeParameter_36() {
    withTypeParameterScope('T extends num', (scope) {
      isSubtype(
        scope.parseType('T'),
        parseType('num'),
        strT0: 'T, T extends num',
        strT1: 'num',
      );
    });
  }

  test_typeParameter_37() {
    withTypeParameterScope('T extends Object?', (scope) {
      var type = scope.parseType('T & num?');

      isNotSubtype(
        type,
        parseType('num'),
        strT0: 'T & num?, T extends Object?',
        strT1: 'num',
      );
      isSubtype(
        type,
        parseType('num?'),
        strT0: 'T & num?, T extends Object?',
        strT1: 'num?',
      );
    });
  }

  test_typeParameter_38() {
    withTypeParameterScope('T extends num', (scope) {
      isSubtype(
        scope.parseType('T'),
        parseType('Object'),
        strT0: 'T, T extends num',
        strT1: 'Object',
      );
    });
  }

  test_typeParameter_39() {
    withTypeParameterScope('T extends num', (scope) {
      isSubtype(
        scope.parseType('T'),
        parseType('Object'),
        strT0: 'T, T extends num',
        strT1: 'Object',
      );
    });
  }

  test_typeParameter_40() {
    withTypeParameterScope('T extends num', (scope) {
      isNotSubtype(
        scope.parseType('T?'),
        parseType('Object'),
        strT0: 'T?, T extends num',
        strT1: 'Object',
      );
    });
  }

  test_typeParameter_41() {
    withTypeParameterScope('T extends num?', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        parseType('Object'),
        strT0: 'T, T extends num?',
        strT1: 'Object',
      );
    });
  }

  test_typeParameter_42() {
    withTypeParameterScope('T extends num?', (scope) {
      isNotSubtype(
        scope.parseType('T?'),
        parseType('Object'),
        strT0: 'T?, T extends num?',
        strT1: 'Object',
      );
    });
  }

  test_typeParameter_43() {
    withTypeParameterScope('T', (scope) {
      isNotSubtype(
        scope.parseType('T'),
        parseType('Object'),
        strT0: 'T',
        strT1: 'Object',
      );
    });
  }

  @FailingTest(issue: 'https://github.com/dart-lang/language/issues/433')
  test_typeParameter_44() {
    withTypeParameterScope('T extends FutureOr<T>', (scope) {
      isSubtype(
        scope.parseType('T'),
        scope.parseType('FutureOr<T>'),
        strT0: 'T, T extends FutureOr<T>',
        strT1: 'FutureOr<T>, T extends FutureOr<T>',
      );
    });
  }

  TypeImpl _parseTestType(String str) {
    var type = parseType(str);
    assertExpectedString(type, str);
    return type;
  }
}

@reflectiveTest
class SubtypingCompoundTest extends AbstractTypeSystemTest {
  test_double() {
    var equivalents = <TypeImpl>[parseType('double')];
    var supertypes = <TypeImpl>[parseType('num')];
    var unrelated = <TypeImpl>[parseType('int')];
    _checkGroups(
      parseType('double'),
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
    );
  }

  test_dynamic() {
    var equivalents = <TypeImpl>[parseType('void'), parseType('Object?')];

    var subtypes = <TypeImpl>[
      parseType('Never'),
      parseType('Null'),
      parseType('Object'),
    ];

    _checkGroups(
      parseType('dynamic'),
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  test_dynamic_isTop() {
    var equivalents = <TypeImpl>[
      parseType('dynamic'),
      parseType('Object?'),
      parseType('void'),
    ];

    var subtypes = <TypeImpl>[
      parseType('int'),
      parseType('double'),
      parseType('num'),
      parseType('String'),
      parseType('Function'),
    ];

    _checkGroups(
      parseType('dynamic'),
      equivalents: equivalents,
      subtypes: subtypes,
    );
  }

  test_futureOr_topTypes() {
    var futureOrObject = parseType('FutureOr<Object>');
    var futureOrObjectQuestion = parseType('FutureOr<Object?>');

    var futureOrQuestionObject = parseType('FutureOr<Object>?');
    var futureOrQuestionObjectQuestion = parseType('FutureOr<Object?>?');

    //FutureOr<Object> <: FutureOr*<Object?>
    _checkGroups(
      futureOrObject,
      equivalents: [parseType('Object')],
      subtypes: [],
      supertypes: [
        parseType('Object?'),
        futureOrQuestionObject,
        futureOrObjectQuestion,
        futureOrQuestionObject,
        futureOrQuestionObjectQuestion,
      ],
    );
  }

  test_intNone() {
    var equivalents = <TypeImpl>[parseType('int')];

    var subtypes = <TypeImpl>[parseType('Never')];

    var supertypes = <TypeImpl>[
      parseType('int?'),
      parseType('Object'),
      parseType('Object?'),
    ];

    var unrelated = <TypeImpl>[
      parseType('double'),
      parseType('Null'),
      parseType('Never?'),
    ];

    _checkGroups(
      parseType('int'),
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_intQuestion() {
    var equivalents = <TypeImpl>[parseType('int?')];

    var subtypes = <TypeImpl>[
      parseType('int'),
      parseType('Null'),
      parseType('Never'),
      parseType('Never?'),
    ];

    var supertypes = <TypeImpl>[parseType('num?'), parseType('Object?')];

    var unrelated = <TypeImpl>[
      parseType('double'),
      parseType('num'),
      parseType('Object'),
    ];

    _checkGroups(
      parseType('int?'),
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_null() {
    var equivalents = <TypeImpl>[parseType('Null'), parseType('Never?')];

    var supertypes = <TypeImpl>[
      parseType('int?'),
      parseType('Object?'),
      parseType('dynamic'),
      parseType('void'),
    ];

    var subtypes = <TypeImpl>[parseType('Never')];

    var unrelated = <TypeImpl>[
      parseType('double'),
      parseType('int'),
      parseType('num'),
      parseType('Object'),
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
    var equivalents = <TypeImpl>[parseType('num')];
    var supertypes = <TypeImpl>[parseType('Object')];
    var unrelated = <TypeImpl>[parseType('String')];
    var subtypes = <TypeImpl>[parseType('int'), parseType('double')];
    _checkGroups(
      parseType('num'),
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  test_object() {
    var equivalents = <TypeImpl>[];

    var supertypes = <TypeImpl>[
      parseType('Object?'),
      parseType('dynamic'),
      parseType('void'),
    ];

    var subtypes = <TypeImpl>[parseType('Never')];

    var unrelated = <TypeImpl>[
      parseType('double?'),
      parseType('num?'),
      parseType('int?'),
      parseType('Null'),
    ];

    _checkGroups(
      parseType('Object'),
      equivalents: equivalents,
      supertypes: supertypes,
      unrelated: unrelated,
      subtypes: subtypes,
    );
  }

  void _checkEquivalent(TypeImpl type1, TypeImpl type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsSubtypeOf(type2, type1);
  }

  void _checkGroups(
    TypeImpl t1, {
    List<TypeImpl>? equivalents,
    List<TypeImpl>? unrelated,
    List<TypeImpl>? subtypes,
    List<TypeImpl>? supertypes,
  }) {
    if (equivalents != null) {
      for (TypeImpl t2 in equivalents) {
        _checkEquivalent(t1, t2);
      }
    }
    if (unrelated != null) {
      for (TypeImpl t2 in unrelated) {
        _checkUnrelated(t1, t2);
      }
    }
    if (subtypes != null) {
      for (TypeImpl t2 in subtypes) {
        _checkIsStrictSubtypeOf(t2, t1);
      }
    }
    if (supertypes != null) {
      for (TypeImpl t2 in supertypes) {
        _checkIsStrictSubtypeOf(t1, t2);
      }
    }
  }

  void _checkIsNotSubtypeOf(TypeImpl type1, TypeImpl type2) {
    var strType1 = _typeStr(type1);
    var strType2 = _typeStr(type2);
    expect(
      typeSystem.isSubtypeOf(type1, type2),
      false,
      reason: '$strType1 was not supposed to be a subtype of $strType2',
    );
  }

  void _checkIsStrictSubtypeOf(TypeImpl type1, TypeImpl type2) {
    _checkIsSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  void _checkIsSubtypeOf(TypeImpl type1, TypeImpl type2) {
    var strType1 = _typeStr(type1);
    var strType2 = _typeStr(type2);
    expect(
      typeSystem.isSubtypeOf(type1, type2),
      true,
      reason: '$strType1 is not a subtype of $strType2',
    );
  }

  void _checkUnrelated(TypeImpl type1, TypeImpl type2) {
    _checkIsNotSubtypeOf(type1, type2);
    _checkIsNotSubtypeOf(type2, type1);
  }

  static String _typeStr(TypeImpl type) {
    return type.getDisplayString();
  }
}
