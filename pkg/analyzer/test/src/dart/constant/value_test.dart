// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.dart.constant.value_test;

import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartObjectImplTest);
  });
}

const int LONG_MAX_VALUE = 0x7fffffffffffffff;

final Matcher throwsEvaluationException =
    throwsA(new isInstanceOf<EvaluationException>());

@reflectiveTest
class DartObjectImplTest extends EngineTestCase {
  TypeProvider _typeProvider = new TestTypeProvider();

  void test_add_knownDouble_knownDouble() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_add_knownDouble_knownInt() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _intValue(2));
  }

  void test_add_knownDouble_unknownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_add_knownDouble_unknownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_add_knownInt_knownInt() {
    _assertAdd(_intValue(3), _intValue(1), _intValue(2));
  }

  void test_add_knownInt_knownString() {
    _assertAdd(null, _intValue(1), _stringValue("2"));
  }

  void test_add_knownInt_unknownDouble() {
    _assertAdd(_doubleValue(null), _intValue(1), _doubleValue(null));
  }

  void test_add_knownInt_unknownInt() {
    _assertAdd(_intValue(null), _intValue(1), _intValue(null));
  }

  void test_add_knownString_knownInt() {
    _assertAdd(null, _stringValue("1"), _intValue(2));
  }

  void test_add_knownString_knownString() {
    _assertAdd(_stringValue("ab"), _stringValue("a"), _stringValue("b"));
  }

  void test_add_knownString_unknownString() {
    _assertAdd(_stringValue(null), _stringValue("a"), _stringValue(null));
  }

  void test_add_unknownDouble_knownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_add_unknownDouble_knownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_add_unknownInt_knownDouble() {
    _assertAdd(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_add_unknownInt_knownInt() {
    _assertAdd(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_add_unknownString_knownString() {
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue("b"));
  }

  void test_add_unknownString_unknownString() {
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue(null));
  }

  void test_bitAnd_knownInt_knownInt() {
    _assertBitAnd(_intValue(2), _intValue(6), _intValue(3));
  }

  void test_bitAnd_knownInt_knownString() {
    _assertBitAnd(null, _intValue(6), _stringValue("3"));
  }

  void test_bitAnd_knownInt_unknownInt() {
    _assertBitAnd(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitAnd_knownString_knownInt() {
    _assertBitAnd(null, _stringValue("6"), _intValue(3));
  }

  void test_bitAnd_unknownInt_knownInt() {
    _assertBitAnd(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitAnd_unknownInt_unknownInt() {
    _assertBitAnd(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitNot_knownInt() {
    _assertBitNot(_intValue(-4), _intValue(3));
  }

  void test_bitNot_knownString() {
    _assertBitNot(null, _stringValue("6"));
  }

  void test_bitNot_unknownInt() {
    _assertBitNot(_intValue(null), _intValue(null));
  }

  void test_bitOr_knownInt_knownInt() {
    _assertBitOr(_intValue(7), _intValue(6), _intValue(3));
  }

  void test_bitOr_knownInt_knownString() {
    _assertBitOr(null, _intValue(6), _stringValue("3"));
  }

  void test_bitOr_knownInt_unknownInt() {
    _assertBitOr(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitOr_knownString_knownInt() {
    _assertBitOr(null, _stringValue("6"), _intValue(3));
  }

  void test_bitOr_unknownInt_knownInt() {
    _assertBitOr(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitOr_unknownInt_unknownInt() {
    _assertBitOr(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitXor_knownInt_knownInt() {
    _assertBitXor(_intValue(5), _intValue(6), _intValue(3));
  }

  void test_bitXor_knownInt_knownString() {
    _assertBitXor(null, _intValue(6), _stringValue("3"));
  }

  void test_bitXor_knownInt_unknownInt() {
    _assertBitXor(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitXor_knownString_knownInt() {
    _assertBitXor(null, _stringValue("6"), _intValue(3));
  }

  void test_bitXor_unknownInt_knownInt() {
    _assertBitXor(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitXor_unknownInt_unknownInt() {
    _assertBitXor(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_concatenate_knownInt_knownString() {
    _assertConcatenate(null, _intValue(2), _stringValue("def"));
  }

  void test_concatenate_knownString_knownInt() {
    _assertConcatenate(null, _stringValue("abc"), _intValue(3));
  }

  void test_concatenate_knownString_knownString() {
    _assertConcatenate(
        _stringValue("abcdef"), _stringValue("abc"), _stringValue("def"));
  }

  void test_concatenate_knownString_unknownString() {
    _assertConcatenate(
        _stringValue(null), _stringValue("abc"), _stringValue(null));
  }

  void test_concatenate_unknownString_knownString() {
    _assertConcatenate(
        _stringValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_divide_knownDouble_knownDouble() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_divide_knownDouble_knownInt() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _intValue(2));
  }

  void test_divide_knownDouble_unknownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_divide_knownDouble_unknownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_divide_knownInt_knownInt() {
    _assertDivide(_doubleValue(3.0), _intValue(6), _intValue(2));
  }

  void test_divide_knownInt_knownString() {
    _assertDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_divide_knownInt_unknownDouble() {
    _assertDivide(_doubleValue(null), _intValue(6), _doubleValue(null));
  }

  void test_divide_knownInt_unknownInt() {
    _assertDivide(_doubleValue(null), _intValue(6), _intValue(null));
  }

  void test_divide_knownString_knownInt() {
    _assertDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_divide_unknownDouble_knownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownDouble_knownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_divide_unknownInt_knownDouble() {
    _assertDivide(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownInt_knownInt() {
    _assertDivide(_doubleValue(null), _intValue(null), _intValue(2));
  }

  void test_equalEqual_bool_false() {
    _assertEqualEqual(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_equalEqual_bool_true() {
    _assertEqualEqual(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_equalEqual_bool_unknown() {
    _assertEqualEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_equalEqual_double_false() {
    _assertEqualEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_equalEqual_double_true() {
    _assertEqualEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_equalEqual_double_unknown() {
    _assertEqualEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_equalEqual_int_false() {
    _assertEqualEqual(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_equalEqual_int_true() {
    _assertEqualEqual(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_equalEqual_int_unknown() {
    _assertEqualEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_equalEqual_list_empty() {
    _assertEqualEqual(null, _listValue(), _listValue());
  }

  void test_equalEqual_list_false() {
    _assertEqualEqual(null, _listValue(), _listValue());
  }

  void test_equalEqual_map_empty() {
    _assertEqualEqual(null, _mapValue(), _mapValue());
  }

  void test_equalEqual_map_false() {
    _assertEqualEqual(null, _mapValue(), _mapValue());
  }

  void test_equalEqual_null() {
    _assertEqualEqual(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_equalEqual_string_false() {
    _assertEqualEqual(
        _boolValue(false), _stringValue("abc"), _stringValue("def"));
  }

  void test_equalEqual_string_true() {
    _assertEqualEqual(
        _boolValue(true), _stringValue("abc"), _stringValue("abc"));
  }

  void test_equalEqual_string_unknown() {
    _assertEqualEqual(
        _boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_equals_list_false_differentSizes() {
    expect(
        _listValue([_boolValue(true)]) ==
            _listValue([_boolValue(true), _boolValue(false)]),
        isFalse);
  }

  void test_equals_list_false_sameSize() {
    expect(_listValue([_boolValue(true)]) == _listValue([_boolValue(false)]),
        isFalse);
  }

  void test_equals_list_true_empty() {
    expect(_listValue(), _listValue());
  }

  void test_equals_list_true_nonEmpty() {
    expect(_listValue([_boolValue(true)]), _listValue([_boolValue(true)]));
  }

  void test_equals_map_true_empty() {
    expect(_mapValue(), _mapValue());
  }

  void test_equals_symbol_false() {
    expect(_symbolValue("a") == _symbolValue("b"), isFalse);
  }

  void test_equals_symbol_true() {
    expect(_symbolValue("a"), _symbolValue("a"));
  }

  void test_getValue_bool_false() {
    expect(_boolValue(false).toBoolValue(), false);
  }

  void test_getValue_bool_true() {
    expect(_boolValue(true).toBoolValue(), true);
  }

  void test_getValue_bool_unknown() {
    expect(_boolValue(null).toBoolValue(), isNull);
  }

  void test_getValue_double_known() {
    double value = 2.3;
    expect(_doubleValue(value).toDoubleValue(), value);
  }

  void test_getValue_double_unknown() {
    expect(_doubleValue(null).toDoubleValue(), isNull);
  }

  void test_getValue_int_known() {
    int value = 23;
    expect(_intValue(value).toIntValue(), value);
  }

  void test_getValue_int_unknown() {
    expect(_intValue(null).toIntValue(), isNull);
  }

  void test_getValue_list_empty() {
    Object result = _listValue().toListValue();
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(0));
  }

  void test_getValue_list_valid() {
    Object result = _listValue([_intValue(23)]).toListValue();
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(1));
  }

  void test_getValue_map_empty() {
    Object result = _mapValue().toMapValue();
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
    Map map = result as Map;
    expect(map, hasLength(0));
  }

  void test_getValue_map_valid() {
    Object result =
        _mapValue([_stringValue("key"), _stringValue("value")]).toMapValue();
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, result);
    Map map = result as Map;
    expect(map, hasLength(1));
  }

  void test_getValue_null() {
    expect(_nullValue().isNull, isTrue);
  }

  void test_getValue_string_known() {
    String value = "twenty-three";
    expect(_stringValue(value).toStringValue(), value);
  }

  void test_getValue_string_unknown() {
    expect(_stringValue(null).toStringValue(), isNull);
  }

  void test_greaterThan_knownDouble_knownDouble_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThan_knownDouble_knownDouble_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThan_knownDouble_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThan_knownDouble_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThan_knownDouble_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThan_knownDouble_unknownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThan_knownInt_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThan_knownInt_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _intValue(2), _intValue(1));
  }

  void test_greaterThan_knownInt_knownString() {
    _assertGreaterThan(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThan_knownInt_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThan_knownInt_unknownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThan_knownString_knownInt() {
    _assertGreaterThan(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThan_unknownDouble_knownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownDouble_knownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThan_unknownInt_knownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownInt_knownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThanOrEqual_knownDouble_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownDouble_unknownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_false() {
    _assertGreaterThanOrEqual(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_true() {
    _assertGreaterThanOrEqual(_boolValue(true), _intValue(2), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownString() {
    _assertGreaterThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThanOrEqual_knownInt_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownInt_unknownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThanOrEqual_knownString_knownInt() {
    _assertGreaterThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownDouble_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownDouble_knownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownInt_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownInt_knownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_hasKnownValue_bool_false() {
    expect(_boolValue(false).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_bool_true() {
    expect(_boolValue(true).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_bool_unknown() {
    expect(_boolValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_double_known() {
    expect(_doubleValue(2.3).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_double_unknown() {
    expect(_doubleValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_dynamic() {
    expect(_dynamicValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_int_known() {
    expect(_intValue(23).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_int_unknown() {
    expect(_intValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_list_empty() {
    expect(_listValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_list_invalidElement() {
    expect(_listValue([_dynamicValue()]).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_list_valid() {
    expect(_listValue([_intValue(23)]).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_map_empty() {
    expect(_mapValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_map_invalidKey() {
    expect(_mapValue([_dynamicValue(), _stringValue("value")]).hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_map_invalidValue() {
    expect(_mapValue([_stringValue("key"), _dynamicValue()]).hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_map_valid() {
    expect(
        _mapValue([_stringValue("key"), _stringValue("value")]).hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_null() {
    expect(_nullValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_num() {
    expect(_numValue().hasKnownValue, isFalse);
  }

  void test_hasKnownValue_string_known() {
    expect(_stringValue("twenty-three").hasKnownValue, isTrue);
  }

  void test_hasKnownValue_string_unknown() {
    expect(_stringValue(null).hasKnownValue, isFalse);
  }

  void test_identical_bool_false() {
    _assertIdentical(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_identical_bool_true() {
    _assertIdentical(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_identical_bool_unknown() {
    _assertIdentical(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_identical_double_false() {
    _assertIdentical(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_identical_double_true() {
    _assertIdentical(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_identical_double_unknown() {
    _assertIdentical(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_identical_int_false() {
    _assertIdentical(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_identical_int_true() {
    _assertIdentical(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_identical_int_unknown() {
    _assertIdentical(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_identical_list_empty() {
    _assertIdentical(_boolValue(true), _listValue(), _listValue());
  }

  void test_identical_list_false() {
    _assertIdentical(
        _boolValue(false), _listValue(), _listValue([_intValue(3)]));
  }

  void test_identical_map_empty() {
    _assertIdentical(_boolValue(true), _mapValue(), _mapValue());
  }

  void test_identical_map_false() {
    _assertIdentical(_boolValue(false), _mapValue(),
        _mapValue([_intValue(1), _intValue(2)]));
  }

  void test_identical_null() {
    _assertIdentical(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_identical_string_false() {
    _assertIdentical(
        _boolValue(false), _stringValue("abc"), _stringValue("def"));
  }

  void test_identical_string_true() {
    _assertIdentical(
        _boolValue(true), _stringValue("abc"), _stringValue("abc"));
  }

  void test_identical_string_unknown() {
    _assertIdentical(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_integerDivide_knownDouble_knownDouble() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_integerDivide_knownDouble_knownInt() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _intValue(2));
  }

  void test_integerDivide_knownDouble_unknownDouble() {
    _assertIntegerDivide(
        _intValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_integerDivide_knownDouble_unknownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_integerDivide_knownInt_knownInt() {
    _assertIntegerDivide(_intValue(3), _intValue(6), _intValue(2));
  }

  void test_integerDivide_knownInt_knownString() {
    _assertIntegerDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_integerDivide_knownInt_unknownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _doubleValue(null));
  }

  void test_integerDivide_knownInt_unknownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_integerDivide_knownString_knownInt() {
    _assertIntegerDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_integerDivide_unknownDouble_knownDouble() {
    _assertIntegerDivide(
        _intValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownDouble_knownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(null), _intValue(2));
  }

  void test_integerDivide_unknownInt_knownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownInt_knownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_isBoolNumStringOrNull_bool_false() {
    expect(_boolValue(false).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_true() {
    expect(_boolValue(true).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_unknown() {
    expect(_boolValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_known() {
    expect(_doubleValue(2.3).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_unknown() {
    expect(_doubleValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_dynamic() {
    expect(_dynamicValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_known() {
    expect(_intValue(23).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_unknown() {
    expect(_intValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_list() {
    expect(_listValue().isBoolNumStringOrNull, isFalse);
  }

  void test_isBoolNumStringOrNull_null() {
    expect(_nullValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_num() {
    expect(_numValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_known() {
    expect(_stringValue("twenty-three").isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_unknown() {
    expect(_stringValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_lessThan_knownDouble_knownDouble_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThan_knownDouble_knownDouble_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThan_knownDouble_knownInt_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThan_knownDouble_knownInt_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThan_knownDouble_unknownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThan_knownDouble_unknownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThan_knownInt_knownInt_false() {
    _assertLessThan(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThan_knownInt_knownInt_true() {
    _assertLessThan(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThan_knownInt_knownString() {
    _assertLessThan(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThan_knownInt_unknownDouble() {
    _assertLessThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThan_knownInt_unknownInt() {
    _assertLessThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThan_knownString_knownInt() {
    _assertLessThan(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThan_unknownDouble_knownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownDouble_knownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThan_unknownInt_knownDouble() {
    _assertLessThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownInt_knownInt() {
    _assertLessThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_false() {
    _assertLessThanOrEqual(
        _boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_true() {
    _assertLessThanOrEqual(
        _boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_unknownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownDouble_unknownInt() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThanOrEqual_knownInt_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThanOrEqual_knownInt_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThanOrEqual_knownInt_knownString() {
    _assertLessThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThanOrEqual_knownInt_unknownDouble() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownInt_unknownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThanOrEqual_knownString_knownInt() {
    _assertLessThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThanOrEqual_unknownDouble_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownDouble_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_unknownInt_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownInt_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_logicalAnd_false_false() {
    _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalAnd_false_null() {
    expect(() {
      _assertLogicalAnd(_boolValue(false), _boolValue(false), _nullValue());
    }, throwsEvaluationException);
  }

  void test_logicalAnd_false_string() {
    expect(() {
      _assertLogicalAnd(
          _boolValue(false), _boolValue(false), _stringValue("false"));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_false_true() {
    _assertLogicalAnd(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_logicalAnd_null_false() {
    expect(() {
      _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(false));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_null_true() {
    expect(() {
      _assertLogicalAnd(_boolValue(false), _nullValue(), _boolValue(true));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_string_false() {
    expect(() {
      _assertLogicalAnd(
          _boolValue(false), _stringValue("true"), _boolValue(false));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_string_true() {
    expect(() {
      _assertLogicalAnd(
          _boolValue(false), _stringValue("false"), _boolValue(true));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_true_false() {
    _assertLogicalAnd(_boolValue(false), _boolValue(true), _boolValue(false));
  }

  void test_logicalAnd_true_null() {
    _assertLogicalAnd(null, _boolValue(true), _nullValue());
  }

  void test_logicalAnd_true_string() {
    expect(() {
      _assertLogicalAnd(
          _boolValue(false), _boolValue(true), _stringValue("true"));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_true_true() {
    _assertLogicalAnd(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_logicalNot_false() {
    _assertLogicalNot(_boolValue(true), _boolValue(false));
  }

  void test_logicalNot_null() {
    _assertLogicalNot(null, _nullValue());
  }

  void test_logicalNot_string() {
    expect(() {
      _assertLogicalNot(_boolValue(true), _stringValue(null));
    }, throwsEvaluationException);
  }

  void test_logicalNot_true() {
    _assertLogicalNot(_boolValue(false), _boolValue(true));
  }

  void test_logicalNot_unknown() {
    _assertLogicalNot(_boolValue(null), _boolValue(null));
  }

  void test_logicalOr_false_false() {
    _assertLogicalOr(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalOr_false_null() {
    _assertLogicalOr(null, _boolValue(false), _nullValue());
  }

  void test_logicalOr_false_string() {
    expect(() {
      _assertLogicalOr(
          _boolValue(false), _boolValue(false), _stringValue("false"));
    }, throwsEvaluationException);
  }

  void test_logicalOr_false_true() {
    _assertLogicalOr(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_logicalOr_null_false() {
    expect(() {
      _assertLogicalOr(_boolValue(false), _nullValue(), _boolValue(false));
    }, throwsEvaluationException);
  }

  void test_logicalOr_null_true() {
    expect(() {
      _assertLogicalOr(_boolValue(true), _nullValue(), _boolValue(true));
    }, throwsEvaluationException);
  }

  void test_logicalOr_string_false() {
    expect(() {
      _assertLogicalOr(
          _boolValue(false), _stringValue("true"), _boolValue(false));
    }, throwsEvaluationException);
  }

  void test_logicalOr_string_true() {
    expect(() {
      _assertLogicalOr(
          _boolValue(true), _stringValue("false"), _boolValue(true));
    }, throwsEvaluationException);
  }

  void test_logicalOr_true_false() {
    _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(false));
  }

  void test_logicalOr_true_null() {
    expect(() {
      _assertLogicalOr(_boolValue(true), _boolValue(true), _nullValue());
    }, throwsEvaluationException);
  }

  void test_logicalOr_true_string() {
    expect(() {
      _assertLogicalOr(
          _boolValue(true), _boolValue(true), _stringValue("true"));
    }, throwsEvaluationException);
  }

  void test_logicalOr_true_true() {
    _assertLogicalOr(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_minus_knownDouble_knownDouble() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _doubleValue(3.0));
  }

  void test_minus_knownDouble_knownInt() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _intValue(3));
  }

  void test_minus_knownDouble_unknownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _doubleValue(null));
  }

  void test_minus_knownDouble_unknownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _intValue(null));
  }

  void test_minus_knownInt_knownInt() {
    _assertMinus(_intValue(1), _intValue(4), _intValue(3));
  }

  void test_minus_knownInt_knownString() {
    _assertMinus(null, _intValue(4), _stringValue("3"));
  }

  void test_minus_knownInt_unknownDouble() {
    _assertMinus(_doubleValue(null), _intValue(4), _doubleValue(null));
  }

  void test_minus_knownInt_unknownInt() {
    _assertMinus(_intValue(null), _intValue(4), _intValue(null));
  }

  void test_minus_knownString_knownInt() {
    _assertMinus(null, _stringValue("4"), _intValue(3));
  }

  void test_minus_unknownDouble_knownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownDouble_knownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_minus_unknownInt_knownDouble() {
    _assertMinus(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownInt_knownInt() {
    _assertMinus(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_negated_double_known() {
    _assertNegated(_doubleValue(2.0), _doubleValue(-2.0));
  }

  void test_negated_double_unknown() {
    _assertNegated(_doubleValue(null), _doubleValue(null));
  }

  void test_negated_int_known() {
    _assertNegated(_intValue(-3), _intValue(3));
  }

  void test_negated_int_unknown() {
    _assertNegated(_intValue(null), _intValue(null));
  }

  void test_negated_string() {
    _assertNegated(null, _stringValue(null));
  }

  void test_notEqual_bool_false() {
    _assertNotEqual(_boolValue(false), _boolValue(true), _boolValue(true));
  }

  void test_notEqual_bool_true() {
    _assertNotEqual(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_notEqual_bool_unknown() {
    _assertNotEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_notEqual_double_false() {
    _assertNotEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_notEqual_double_true() {
    _assertNotEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_notEqual_double_unknown() {
    _assertNotEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_notEqual_int_false() {
    _assertNotEqual(_boolValue(false), _intValue(5), _intValue(5));
  }

  void test_notEqual_int_true() {
    _assertNotEqual(_boolValue(true), _intValue(-5), _intValue(5));
  }

  void test_notEqual_int_unknown() {
    _assertNotEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_notEqual_null() {
    _assertNotEqual(_boolValue(false), _nullValue(), _nullValue());
  }

  void test_notEqual_string_false() {
    _assertNotEqual(
        _boolValue(false), _stringValue("abc"), _stringValue("abc"));
  }

  void test_notEqual_string_true() {
    _assertNotEqual(_boolValue(true), _stringValue("abc"), _stringValue("def"));
  }

  void test_notEqual_string_unknown() {
    _assertNotEqual(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_performToString_bool_false() {
    _assertPerformToString(_stringValue("false"), _boolValue(false));
  }

  void test_performToString_bool_true() {
    _assertPerformToString(_stringValue("true"), _boolValue(true));
  }

  void test_performToString_bool_unknown() {
    _assertPerformToString(_stringValue(null), _boolValue(null));
  }

  void test_performToString_double_known() {
    _assertPerformToString(_stringValue("2.0"), _doubleValue(2.0));
  }

  void test_performToString_double_unknown() {
    _assertPerformToString(_stringValue(null), _doubleValue(null));
  }

  void test_performToString_int_known() {
    _assertPerformToString(_stringValue("5"), _intValue(5));
  }

  void test_performToString_int_unknown() {
    _assertPerformToString(_stringValue(null), _intValue(null));
  }

  void test_performToString_null() {
    _assertPerformToString(_stringValue("null"), _nullValue());
  }

  void test_performToString_string_known() {
    _assertPerformToString(_stringValue("abc"), _stringValue("abc"));
  }

  void test_performToString_string_unknown() {
    _assertPerformToString(_stringValue(null), _stringValue(null));
  }

  void test_remainder_knownDouble_knownDouble() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _doubleValue(2.0));
  }

  void test_remainder_knownDouble_knownInt() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _intValue(2));
  }

  void test_remainder_knownDouble_unknownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(7.0), _doubleValue(null));
  }

  void test_remainder_knownDouble_unknownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_remainder_knownInt_knownInt() {
    _assertRemainder(_intValue(1), _intValue(7), _intValue(2));
  }

  void test_remainder_knownInt_knownString() {
    _assertRemainder(null, _intValue(7), _stringValue("2"));
  }

  void test_remainder_knownInt_unknownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(7), _doubleValue(null));
  }

  void test_remainder_knownInt_unknownInt() {
    _assertRemainder(_intValue(null), _intValue(7), _intValue(null));
  }

  void test_remainder_knownString_knownInt() {
    _assertRemainder(null, _stringValue("7"), _intValue(2));
  }

  void test_remainder_unknownDouble_knownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownDouble_knownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_remainder_unknownInt_knownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownInt_knownInt() {
    _assertRemainder(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_shiftLeft_knownInt_knownInt() {
    _assertShiftLeft(_intValue(48), _intValue(6), _intValue(3));
  }

  void test_shiftLeft_knownInt_knownString() {
    _assertShiftLeft(null, _intValue(6), _stringValue(null));
  }

  void test_shiftLeft_knownInt_tooLarge() {
    _assertShiftLeft(
        _intValue(null),
        _intValue(6),
        new DartObjectImpl(
            _typeProvider.intType, new IntState(LONG_MAX_VALUE)));
  }

  void test_shiftLeft_knownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_shiftLeft_knownString_knownInt() {
    _assertShiftLeft(null, _stringValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_knownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_shiftRight_knownInt_knownInt() {
    _assertShiftRight(_intValue(6), _intValue(48), _intValue(3));
  }

  void test_shiftRight_knownInt_knownString() {
    _assertShiftRight(null, _intValue(48), _stringValue(null));
  }

  void test_shiftRight_knownInt_tooLarge() {
    _assertShiftRight(
        _intValue(null),
        _intValue(48),
        new DartObjectImpl(
            _typeProvider.intType, new IntState(LONG_MAX_VALUE)));
  }

  void test_shiftRight_knownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(48), _intValue(null));
  }

  void test_shiftRight_knownString_knownInt() {
    _assertShiftRight(null, _stringValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_knownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_stringLength_int() {
    expect(() {
      _assertStringLength(_intValue(null), _intValue(0));
    }, throwsEvaluationException);
  }

  void test_stringLength_knownString() {
    _assertStringLength(_intValue(3), _stringValue("abc"));
  }

  void test_stringLength_unknownString() {
    _assertStringLength(_intValue(null), _stringValue(null));
  }

  void test_times_knownDouble_knownDouble() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _doubleValue(3.0));
  }

  void test_times_knownDouble_knownInt() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _intValue(3));
  }

  void test_times_knownDouble_unknownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _doubleValue(null));
  }

  void test_times_knownDouble_unknownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _intValue(null));
  }

  void test_times_knownInt_knownInt() {
    _assertTimes(_intValue(6), _intValue(2), _intValue(3));
  }

  void test_times_knownInt_knownString() {
    _assertTimes(null, _intValue(2), _stringValue("3"));
  }

  void test_times_knownInt_unknownDouble() {
    _assertTimes(_doubleValue(null), _intValue(2), _doubleValue(null));
  }

  void test_times_knownInt_unknownInt() {
    _assertTimes(_intValue(null), _intValue(2), _intValue(null));
  }

  void test_times_knownString_knownInt() {
    _assertTimes(null, _stringValue("2"), _intValue(3));
  }

  void test_times_unknownDouble_knownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_times_unknownDouble_knownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_times_unknownInt_knownDouble() {
    _assertTimes(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_times_unknownInt_knownInt() {
    _assertTimes(_intValue(null), _intValue(null), _intValue(3));
  }

  /**
   * Assert that the result of adding the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertAdd(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.add(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.add(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-anding the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertBitAnd(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.bitAnd(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.bitAnd(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the bit-not of the [operand] is the [expected] value, or that
   * the operation throws an exception if the expected value is `null`.
   */
  void _assertBitNot(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.bitNot(_typeProvider);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.bitNot(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-oring the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertBitOr(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.bitOr(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.bitOr(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of bit-xoring the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertBitXor(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.bitXor(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.bitXor(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of concatenating the [left] and [right] operands is
   * the [expected] value, or that the operation throws an exception if the
   * expected value is `null`.
   */
  void _assertConcatenate(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.concatenate(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.concatenate(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of dividing the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertDivide(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.divide(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.divide(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the [left] and [right] operands for
   * equality is the [expected] value, or that the operation throws an exception
   * if the expected value is `null`.
   */
  void _assertEqualEqual(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.equalEqual(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.equalEqual(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertGreaterThan(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.greaterThan(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.greaterThan(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertGreaterThanOrEqual(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.greaterThanOrEqual(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.greaterThanOrEqual(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the [left] and [right] operands using
   * identical() is the expected value.
   */
  void _assertIdentical(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    DartObjectImpl result = left.isIdentical(_typeProvider, right);
    expect(result, isNotNull);
    expect(result, expected);
  }

  void _assertInstanceOfObjectArray(Object result) {
    // TODO(scheglov) implement
  }

  /**
   * Assert that the result of dividing the [left] and [right] operands as
   * integers is the [expected] value, or that the operation throws an exception
   * if the expected value is `null`.
   */
  void _assertIntegerDivide(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.integerDivide(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.integerDivide(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertLessThan(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.lessThan(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.lessThan(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the [left] and [right] operands is the
   * [expected] value, or that the operation throws an exception if the expected
   * value is `null`.
   */
  void _assertLessThanOrEqual(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.lessThanOrEqual(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.lessThanOrEqual(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of logical-anding the [left] and [right] operands is
   * the [expected] value, or that the operation throws an exception if the
   * expected value is `null`.
   */
  void _assertLogicalAnd(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.logicalAnd(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.logicalAnd(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the logical-not of the [operand] is the [expected] value, or
   * that the operation throws an exception if the expected value is `null`.
   */
  void _assertLogicalNot(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.logicalNot(_typeProvider);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.logicalNot(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of logical-oring the [left] and [right] operands is
   * the [expected] value, or that the operation throws an exception if the
   * expected value is `null`.
   */
  void _assertLogicalOr(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.logicalOr(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.logicalOr(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of subtracting the [left] and [right] operands is
   * the [expected] value, or that the operation throws an exception if the
   * expected value is `null`.
   */
  void _assertMinus(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.minus(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.minus(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the negation of the [operand] is the [expected] value, or that
   * the operation throws an exception if the expected value is `null`.
   */
  void _assertNegated(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.negated(_typeProvider);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.negated(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of comparing the [left] and [right] operands for
   * inequality is the [expected] value, or that the operation throws an
   * exception if the expected value is `null`.
   */
  void _assertNotEqual(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.notEqual(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.notEqual(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that converting the [operand] to a string is the [expected] value,
   * or that the operation throws an exception if the expected value is `null`.
   */
  void _assertPerformToString(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.performToString(_typeProvider);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.performToString(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of taking the remainder of the [left] and [right]
   * operands is the [expected] value, or that the operation throws an exception
   * if the expected value is `null`.
   */
  void _assertRemainder(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.remainder(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.remainder(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the [left] and [right] operands is
   * the [expected] value, or that the operation throws an exception if the
   * expected value is `null`.
   */
  void _assertShiftLeft(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.shiftLeft(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.shiftLeft(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the [left] and [right] operands is
   * the [expected] value, or that the operation throws an exception if the
   * expected value is `null`.
   */
  void _assertShiftRight(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.shiftRight(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.shiftRight(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the length of the [operand] is the [expected] value, or that
   * the operation throws an exception if the expected value is `null`.
   */
  void _assertStringLength(DartObjectImpl expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.stringLength(_typeProvider);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.stringLength(_typeProvider);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /**
   * Assert that the result of multiplying the [left] and [right] operands is
   * the [expected] value, or that the operation throws an exception if the
   * expected value is `null`.
   */
  void _assertTimes(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.times(_typeProvider, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.times(_typeProvider, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  DartObjectImpl _boolValue(bool value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.boolType, BoolState.UNKNOWN_VALUE);
    } else if (identical(value, false)) {
      return new DartObjectImpl(_typeProvider.boolType, BoolState.FALSE_STATE);
    } else if (identical(value, true)) {
      return new DartObjectImpl(_typeProvider.boolType, BoolState.TRUE_STATE);
    }
    fail("Invalid boolean value used in test");
    return null;
  }

  DartObjectImpl _doubleValue(double value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.doubleType, DoubleState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(
          _typeProvider.doubleType, new DoubleState(value));
    }
  }

  DartObjectImpl _dynamicValue() {
    return new DartObjectImpl(
        _typeProvider.nullType, DynamicState.DYNAMIC_STATE);
  }

  DartObjectImpl _intValue(int value) {
    if (value == null) {
      return new DartObjectImpl(_typeProvider.intType, IntState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(_typeProvider.intType, new IntState(value));
    }
  }

  DartObjectImpl _listValue(
      [List<DartObjectImpl> elements = DartObjectImpl.EMPTY_LIST]) {
    return new DartObjectImpl(_typeProvider.listType, new ListState(elements));
  }

  DartObjectImpl _mapValue(
      [List<DartObjectImpl> keyElementPairs = DartObjectImpl.EMPTY_LIST]) {
    Map<DartObjectImpl, DartObjectImpl> map =
        new Map<DartObjectImpl, DartObjectImpl>();
    int count = keyElementPairs.length;
    for (int i = 0; i < count;) {
      map[keyElementPairs[i++]] = keyElementPairs[i++];
    }
    return new DartObjectImpl(_typeProvider.mapType, new MapState(map));
  }

  DartObjectImpl _nullValue() {
    return new DartObjectImpl(_typeProvider.nullType, NullState.NULL_STATE);
  }

  DartObjectImpl _numValue() {
    return new DartObjectImpl(_typeProvider.nullType, NumState.UNKNOWN_VALUE);
  }

  DartObjectImpl _stringValue(String value) {
    if (value == null) {
      return new DartObjectImpl(
          _typeProvider.stringType, StringState.UNKNOWN_VALUE);
    } else {
      return new DartObjectImpl(
          _typeProvider.stringType, new StringState(value));
    }
  }

  DartObjectImpl _symbolValue(String value) {
    return new DartObjectImpl(_typeProvider.symbolType, new SymbolState(value));
  }
}
