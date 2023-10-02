// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_support.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantVisitorTest);
    defineReflectiveTests(ConstantVisitorWithoutNullSafetyTest);
    defineReflectiveTests(InstanceCreationEvaluatorTest);
    defineReflectiveTests(InstanceCreationEvaluatorWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ConstantVisitorTest extends ConstantVisitorTestSupport
    with ConstantVisitorTestCases {
  test_declaration_staticError_notAssignable() async {
    await assertErrorsInCode('''
const int x = 'foo';
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 14, 5),
    ]);
  }

  /// Enum constants can reference other constants.
  test_enum_enhanced_constants() async {
    await assertNoErrorsInCode('''
enum E {
  v1(42), v2(v1);
  final Object? a;
  const E([this.a]);
}
''');
    assertDartObjectText(_field('v2'), r'''
E
  _name: String v2
  a: E
    _name: String v1
    a: int 42
    index: int 0
    variable: self::@enum::E::@field::v1
  index: int 1
  variable: self::@enum::E::@field::v2
''');
  }

  test_enum_enhanced_named() async {
    await resolveTestCode('''
enum E<T> {
  v1<double>.named(10),
  v2.named(20);
  final T f;
  const E.named(this.f);
}

const x1 = E.v1;
const x2 = E.v2;
''');
    assertDartObjectText(_topLevelVar('x1'), r'''
E<double>
  _name: String v1
  f: double 10.0
  index: int 0
  variable: self::@variable::x1
''');
    assertDartObjectText(_topLevelVar('x2'), r'''
E<int>
  _name: String v2
  f: int 20
  index: int 1
  variable: self::@variable::x2
''');
  }

  test_enum_enhanced_unnamed() async {
    await resolveTestCode('''
enum E<T> {
  v1<int>(10),
  v2(20),
  v3('abc');
  final T f;
  const E(this.f);
}

const x1 = E.v1;
const x2 = E.v2;
const x3 = E.v3;
''');
    assertDartObjectText(_topLevelVar('x1'), r'''
E<int>
  _name: String v1
  f: int 10
  index: int 0
  variable: self::@variable::x1
''');
    assertDartObjectText(_topLevelVar('x2'), r'''
E<int>
  _name: String v2
  f: int 20
  index: int 1
  variable: self::@variable::x2
''');
    assertDartObjectText(_topLevelVar('x3'), r'''
E<String>
  _name: String v3
  f: String abc
  index: int 2
  variable: self::@variable::x3
''');
  }

  test_enum_simple() async {
    await resolveTestCode('''
enum E { v1, v2 }
const x1 = E.v1;
const x2 = E.v2;
''');
    assertDartObjectText(_topLevelVar('x1'), r'''
E
  _name: String v1
  index: int 0
  variable: self::@variable::x1
''');
    assertDartObjectText(_topLevelVar('x2'), r'''
E
  _name: String v2
  index: int 1
  variable: self::@variable::x2
''');
  }

  test_equalEqual_bool_bool_false() async {
    await assertNoErrorsInCode('''
const v = true == false;
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_bool_bool_true() async {
    await assertNoErrorsInCode('''
const v = true == true;
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: self::@variable::v
''');
  }

  test_equalEqual_double_object() async {
    await assertNoErrorsInCode('''
const v = 1.2 == Object();
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_int_int_false() async {
    await assertNoErrorsInCode('''
const v = 1 == 2;
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_int_int_true() async {
    await assertNoErrorsInCode('''
const v = 1 == 1;
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: self::@variable::v
''');
  }

  test_equalEqual_int_null() async {
    await assertNoErrorsInCode('''
const int? a = 1;
const v = a == null;
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_int_object() async {
    await assertNoErrorsInCode('''
const v = 1 == Object();
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_int_userClass() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}

const v = 1 == A();
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_invalidLeft() async {
    await assertErrorsInCode('''
const v = a == 1;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          1),
    ]);
  }

  test_equalEqual_invalidRight() async {
    await assertErrorsInCode('''
const v = 1 == a;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 15,
          1),
    ]);
  }

  test_equalEqual_null_object() async {
    await assertNoErrorsInCode('''
const Object? a = null;
const v = a == Object();
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_string_object() async {
    await assertNoErrorsInCode('''
const v = 'foo' == Object();
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_userClass_hasEqEq() async {
    await assertErrorsInCode('''
class A {
  const A();
  bool operator ==(other) => false;
}

const v = A() == 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 72, 8),
    ]);
    final result = _topLevelVar('v');
    _assertNull(result);
  }

  test_equalEqual_userClass_hasHashCode() async {
    await assertErrorsInCode('''
class A {
  const A();
  int get hashCode => 0;
}

const v = A() == 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 61, 8),
    ]);
    final result = _topLevelVar('v');
    _assertNull(result);
  }

  test_equalEqual_userClass_hasPrimitiveEquality_false() async {
    await assertNoErrorsInCode('''
class A {
  final int f;
  const A(this.f);
}

const v = A(0) == 0;
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: self::@variable::v
''');
  }

  test_equalEqual_userClass_hasPrimitiveEquality_language219() async {
    await assertErrorsInCode('''
// @dart = 2.19
class A {
  const A();
}

const v = A() == 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 52, 8),
    ]);
    final result = _topLevelVar('v');
    _assertNull(result);
  }

  test_equalEqual_userClass_hasPrimitiveEquality_true() async {
    await assertNoErrorsInCode('''
class A {
  final int f;
  const A(this.f);
}

const v = A(0) == A(0);
''');
    final result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: self::@variable::v
''');
  }

  test_hasPrimitiveEquality_bool() async {
    await assertNoErrorsInCode('''
const v = true;
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_class_hasEqEq() async {
    await assertNoErrorsInCode('''
const v = const A();

class A {
  const A();
  bool operator ==(other) => false;
}
''');
    _assertHasPrimitiveEqualityFalse('v');
  }

  test_hasPrimitiveEquality_class_hasEqEq_language219() async {
    await assertNoErrorsInCode('''
// @dart = 2.19
const v = const A();

class A {
  const A();
  bool operator ==(other) => false;
}
''');
    _assertHasPrimitiveEqualityFalse('v');
  }

  test_hasPrimitiveEquality_class_hasHashCode() async {
    await assertNoErrorsInCode('''
const v = const A();

class A {
  const A();
  int get hashCode => 0;
}
''');
    _assertHasPrimitiveEqualityFalse('v');
  }

  test_hasPrimitiveEquality_class_hasHashCode_language219() async {
    await assertNoErrorsInCode('''
// @dart = 2.19
const v = const A();

class A {
  const A();
  int get hashCode => 0;
}
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_class_hasNone() async {
    await assertNoErrorsInCode('''
const v = const A();

class A {
  const A();
}
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_double() async {
    await assertNoErrorsInCode('''
const v = 1.2;
''');
    _assertHasPrimitiveEqualityFalse('v');
  }

  test_hasPrimitiveEquality_functionReference_staticMethod() async {
    await assertNoErrorsInCode('''
const v = A.foo;

class A {
  static void foo() {}
}
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_functionReference_topLevelFunction() async {
    await assertNoErrorsInCode('''
const v = foo;

void foo() {}
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_int() async {
    await assertNoErrorsInCode('''
const v = 0;
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_list() async {
    await assertNoErrorsInCode('''
const v = const [0];
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_map() async {
    await assertNoErrorsInCode('''
const v = const <int, String>{0: ''};
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_null() async {
    await assertNoErrorsInCode('''
const v = null;
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_record_named_false() async {
    await assertNoErrorsInCode('''
const v = (f1: true, f2: 1.2);
''');
    _assertHasPrimitiveEqualityFalse('v');
  }

  test_hasPrimitiveEquality_record_named_true() async {
    await assertNoErrorsInCode('''
const v = (f1: true, f2: 0);
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_record_positional_false() async {
    await assertNoErrorsInCode('''
const v = (true, 1.2);
''');
    _assertHasPrimitiveEqualityFalse('v');
  }

  test_hasPrimitiveEquality_record_positional_true() async {
    await assertNoErrorsInCode('''
const v = (true, 0);
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_set() async {
    await assertNoErrorsInCode('''
const v = const {0};
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_symbol() async {
    await assertNoErrorsInCode('''
const v = #foo.bar;
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_hasPrimitiveEquality_type() async {
    await assertNoErrorsInCode('''
const v = int;
''');
    _assertHasPrimitiveEqualityTrue('v');
  }

  test_identical_typeLiteral_explicitTypeArgs_differentTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
const c = identical(C<int>, C<String>);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_differentTypes() async {
    await assertNoErrorsInCode('''
class C<T> {}
class D<T> {}
const c = identical(C<int>, D<int>);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_sameType() async {
    await assertNoErrorsInCode('''
class C<T> {}
const c = identical(C<int>, C<int>);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_simpleTypeAlias() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef TC = C<int>;
const c = identical(C<int>, TC);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<int>, TC<int>);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_differentTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<int>, TC<String>);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_implicitTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<dynamic>, TC);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_implicitTypeArgs_bound() async {
    await assertNoErrorsInCode('''
class C<T extends num> {}
typedef TC<T extends num> = C<T>;
const c = identical(C<num>, TC);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_simple_differentTypes() async {
    await assertNoErrorsInCode('''
const c = identical(int, String);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_identical_typeLiteral_simple_sameType() async {
    await assertNoErrorsInCode('''
const c = identical(int, int);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_instanceCreation_generic_noTypeArguments_inferred_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T t;
  const A(this.t);
}
const Object a = const A(0);
''');

    await assertNoErrorsInCode('''
import 'a.dart';

const b = a;
''');

    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
A<int>
  t: int 0
  variable: self::@variable::b
''');
  }

  /// https://github.com/dart-lang/sdk/issues/53029
  /// Dependencies of map patterns should be considered.
  test_mapPattern_dependencies() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

void f(Object? x) {
  if (x case {a: _}) {}
}
''');
  }

  test_typeParameter() async {
    await assertErrorsInCode('''
class A<X> {
  const A();
  void m() {
    const x = X;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 49, 1),
      error(CompileTimeErrorCode.CONST_TYPE_PARAMETER, 53, 1),
    ]);
    final result = _localVar('x');
    _assertNull(result);
  }

  test_visitBinaryExpression_extensionMethod() async {
    await assertErrorsInCode('''
extension on Object {
  int operator +(Object other) => 0;
}

const Object v1 = 0;
const v2 = v1 + v1;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_EXTENSION_METHOD, 94, 7),
    ]);
    final result = _topLevelVar('v2');
    _assertNull(result);
  }

  test_visitBinaryExpression_gt_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 > 3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gte_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 >= 3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_fewerBits() async {
    await assertNoErrorsInCode('''
const c = 0xFFFFFFFF >>> 8;
''');
    final result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xffffff
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_moreBits() async {
    await assertNoErrorsInCode('''
const c = 0xFFFFFFFF >>> 33;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_moreThan64Bits() async {
    await assertNoErrorsInCode('''
const c = 0xFFFFFFFF >>> 65;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_negativeBits() async {
    await assertErrorsInCode('''
const c = 0xFFFFFFFF >>> -2;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 10, 17),
    ]);
    final result = _topLevelVar('c');
    _assertNull(result);
  }

  test_visitBinaryExpression_gtGtGt_negative_zeroBits() async {
    await assertNoErrorsInCode('''
const c = 0xFFFFFFFF >>> 0;
''');
    final result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xffffffff
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_fewerBits() async {
    await assertNoErrorsInCode('''
const c = 0xFF >>> 3;
''');
    final result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0x1f
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_moreBits() async {
    await assertNoErrorsInCode('''
const c = 0xFF >>> 9;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_moreThan64Bits() async {
    await assertNoErrorsInCode('''
const c = 0xFF >>> 65;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_negativeBits() async {
    await assertErrorsInCode('''
const c = 0xFF >>> -2;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 10, 11),
    ]);
    final result = _topLevelVar('c');
    _assertNull(result);
  }

  test_visitBinaryExpression_gtGtGt_positive_zeroBits() async {
    await assertNoErrorsInCode('''
const c = 0xFF >>> 0;
''');
    final result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xff
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_lt_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 < 3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_lte_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 <= 3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_questionQuestion_invalid_notNull() async {
    await assertErrorsInCode('''
final x = 0;
const c = x ?? 1;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 23,
          1),
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 28, 1),
    ]);
  }

  test_visitBinaryExpression_questionQuestion_notNull_invalid() async {
    await assertErrorsInCode('''
final x = 1;
const c = 0 ?? x;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 28,
          1),
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 28, 1),
    ]);
  }

  test_visitConditionalExpression_eager_invalid_int_int() async {
    await assertErrorsInCode('''
const c = null ? 1 : 0;
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 10, 4),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 4),
    ]);
  }

  test_visitConditionalExpression_instantiatedFunctionType_variable() async {
    await assertNoErrorsInCode('''
void f<T>(T p, {T? q}) {}

const void Function<T>(T p) g = f;

const bool b = false;
const void Function(int p) h = b ? g : g;
''');
    final result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int, {int? q})
  element: self::@function::f
  typeArguments
    int
  variable: self::@variable::h
''');
  }

  test_visitConditionalExpression_unknownCondition() async {
    await assertNoErrorsInCode('''
const bool kIsWeb = identical(0, 0.0);
const x = kIsWeb ? 0 : 1;
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
<unknown> int
  variable: self::@variable::x
''');
  }

  test_visitConditionalExpression_unknownCondition_errorInConstructor() async {
    await assertErrorsInCode(r'''
const bool kIsWeb = identical(0, 0.0);

var a = 2;
const x = A(kIsWeb ? 0 : a);

class A {
  const A(int _);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 76, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 76,
          1),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitConditionalExpression_unknownCondition_undefinedIdentifier() async {
    await assertErrorsInCode(r'''
const bool kIsWeb = identical(0, 0.0);
const x = kIsWeb ? a : b;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 58, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 58,
          1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 62, 1),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitConstructorDeclaration_cycle() async {
    await assertErrorsInCode('''
class A {
  final A a;
  const A() : a = const A();
}

''', [
      error(CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR, 31, 1),
    ]);
  }

  test_visitConstructorDeclaration_cycle_subclass_issue46735() async {
    await assertErrorsInCode('''
void main() {
  const EmptyInjector();
}

abstract class BaseInjector {
  final BaseInjector parent;

  const BaseInjector([BaseInjector? parent])
      : parent = parent ?? const EmptyInjector();
}

abstract class Injector implements BaseInjector {
  const Injector();
}

class EmptyInjector extends BaseInjector implements Injector {
  const EmptyInjector();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR, 110, 12),
      error(CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR, 344, 13),
    ]);
  }

  test_visitConstructorDeclaration_field_asExpression_nonConst() async {
    await assertErrorsInCode(r'''
dynamic y = 2;
class A {
  const A();
  final x = y as num;
}
''', [
      error(
          CompileTimeErrorCode
              .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
          27,
          5),
    ]);
  }

  test_visitConstructorReference_generic_named() async {
    await assertNoErrorsInCode('''
class C<T> {
  C.foo();
}
const c = C<int>.foo;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: self::@class::C::@constructor::foo
  typeArguments
    int
  variable: self::@variable::c
''');
  }

  test_visitConstructorReference_generic_unnamed() async {
    await assertNoErrorsInCode('''
class C<T> {
  C();
}
const c = C<int>.new;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: self::@class::C::@constructor::new
  typeArguments
    int
  variable: self::@variable::c
''');
  }

  test_visitConstructorReference_identical_aliasIsNotGeneric() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC = C<int>;
const a = identical(MyC.new, C<int>.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentBound() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC.new, C.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentCount() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef MyC<T> = C<T, int>;
const a = identical(MyC.new, C.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentCount2() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef MyC<T> = C;
const a = identical(MyC.new, C.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentOrder() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef MyC<T, U> = C<U, T>;
const a = identical(MyC.new, C.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_instantiated() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, C<int>.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_mixedInstantiations() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, (MyC.new)<int>);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_instantiated() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mixedInstantiations() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC<int>.new, (MyC.new)<int>);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mutualSubtypes_dynamic() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T extends Object?> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mutualSubtypes_futureOr() async {
    await assertNoErrorsInCode('''
import 'dart:async';
class C<T extends FutureOr<num>> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_uninstantiated() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC.new, MyC.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_differentClasses() async {
    await assertNoErrorsInCode('''
class C<T> {}
class D<T> {}
const a = identical(C<int>.new, D<int>.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_differentConstructors() async {
    await assertNoErrorsInCode('''
class C<T> {
  C();
  C.named();
}
const a = identical(C<int>.new, C<int>.named);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_differentTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
const a = identical(C<int>.new, C<String>.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_sameElement() async {
    await assertNoErrorsInCode('''
class C<T> {}
const a = identical(C<int>.new, C<int>.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_inferredTypeArgs_sameElement() async {
    await assertNoErrorsInCode('''
class C<T> {}
const C<int> Function() c1 = C.new;
const c2 = C<int>.new;
const a = identical(c1, c2);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_notInstantiated_differentClasses() async {
    await assertNoErrorsInCode('''
class C<T> {}
class D<T> {}
const a = identical(C.new, D.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_notInstantiated_differentConstructors() async {
    await assertNoErrorsInCode('''
class C<T> {
  C();
  C.named();
}
const a = identical(C.new, C.named);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_notInstantiated_sameElement() async {
    await assertNoErrorsInCode('''
class C<T> {}
const a = identical(C.new, C.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_identical_onlyOneHasTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
const a = identical(C<int>.new, C.new);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::a
''');
  }

  test_visitConstructorReference_nonGeneric_named() async {
    await assertNoErrorsInCode('''
class C<T> {
  const C.foo();
}
const c = C<int>.foo;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: self::@class::C::@constructor::foo
  typeArguments
    int
  variable: self::@variable::c
''');
  }

  test_visitConstructorReference_nonGeneric_unnamed() async {
    await assertNoErrorsInCode('''
class C<T> {
  const C();
}
const c = C<int>.new;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: self::@class::C::@constructor::new
  typeArguments
    int
  variable: self::@variable::c
''');
  }

  test_visitFunctionReference_defaultConstructorValue() async {
    await assertErrorsInCode(r'''
void f<T>(T t) => t;

class C<T> {
  final void Function(T) p;
  const C({this.p = f});
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF,
          83, 1),
    ]);
  }

  test_visitFunctionReference_explicitTypeArgs_complexExpression() async {
    await assertNoErrorsInCode(r'''
const b = true;
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = (b ? foo : bar)<int>;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function(int)
  element: self::@function::foo
  typeArguments
    int
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_complexExpression_differentTypes() async {
    await assertNoErrorsInCode(r'''
const b = true;
void foo<T>(String a, T b) {}
void bar<T>(T a, String b) {}
const g = (b ? foo : bar)<int>;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function(String, int)
  element: self::@function::foo
  typeArguments
    int
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_constantType() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {}
const g = f<int>;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function(int)
  element: self::@function::f
  typeArguments
    int
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_notMatchingBound() async {
    await assertErrorsInCode(r'''
void f<T extends num>(T a) {}
const g = f<String>;
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 42, 6),
    ]);
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function(String)
  element: self::@function::f
  typeArguments
    String
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_notType() async {
    await assertErrorsInCode(r'''
void foo<T>(T a) {}
const g = foo<true>;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_NUM, 30, 8),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 33, 1),
      error(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 38, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 39, 1),
    ]);
    final result = _topLevelVar('g');
    _assertNull(result);
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_tooFew() async {
    await assertErrorsInCode(r'''
void foo<T, U>(T a, U b) {}
const g = foo<int>;
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 41, 5),
    ]);
    final result = _topLevelVar('g');
    _assertNull(result);
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_tooMany() async {
    await assertErrorsInCode(r'''
void foo<T>(T a) {}
const g = foo<int, String>;
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 33, 13),
    ]);
    final result = _topLevelVar('g');
    _assertNull(result);
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_typeParameter() async {
    await assertErrorsInCode(r'''
void f<T>(T a) {}

class C<U> {
  void m() {
    const g = f<U>;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 55, 1),
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF,
          61, 1),
    ]);
  }

  test_visitFunctionReference_explicitTypeArgs_identical_differentElements() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = identical(foo<int>, bar<int>);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_differentTypeArgs() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<String>);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_onlyOneHasTypeArgs() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_sameElement() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<int>);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_sameElement_runtimeTypeEquality() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
void foo<T>(T a) {}
const g = identical(foo<Object>, foo<FutureOr<Object>>);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_differentElements() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = identical(foo<int>, bar<int>);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_differentTypeArgs() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<String>);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_onlyOneHasTypeArgs() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_sameElement() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<int>);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_sameElement_runtimeTypeEquality() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
void foo<T>(T a) {}
const g = identical(foo<Object>, foo<FutureOr<Object>>);
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_identical_implicitTypeArgs_differentTypes() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(String) g = foo;
const c = identical(f, g);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitFunctionReference_identical_implicitTypeArgs_sameTypes() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(int) g = foo;
const c = identical(f, g);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitFunctionReference_identical_uninstantiated_sameElement() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const c = identical(foo, foo);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitFunctionReference_implicitTypeArgs_identical_differentTypes() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(String) g = foo;
const c = identical(f, g);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitFunctionReference_implicitTypeArgs_identical_sameTypes() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(int) g = foo;
const c = identical(f, g);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitFunctionReference_uninstantiated_complexExpression() async {
    await assertNoErrorsInCode(r'''
const b = true;
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = b ? foo : bar;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function<T>(T)
  element: self::@function::foo
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_uninstantiated_functionName() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {}
const g = f;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function<T>(T)
  element: self::@function::f
  variable: self::@variable::g
''');
  }

  test_visitFunctionReference_uninstantiated_identical_sameElement() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const c = identical(foo, foo);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitInstanceCreationExpression_noArgs() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}
const a = A();
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
A
  variable: self::@variable::a
''');
  }

  test_visitInstanceCreationExpression_noConstConstructor() async {
    await assertErrorsInCode('''
class A {}
const a = A();
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 21, 3),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 21,
          3),
    ]);
  }

  test_visitInstanceCreationExpression_simpleArgs() async {
    await assertNoErrorsInCode('''
class A {
  const A(int x);
}
const a = A(1);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
A
  variable: self::@variable::a
''');
  }

  test_visitInstanceCreationExpression_unknown() async {
    await assertErrorsInCode('''
class C<T> {
  const C.named();
}

const x = C<int>.();
''', [
      // TODO(https://github.com/dart-lang/sdk/issues/50441): This should not be
      // reported.
      error(CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER,
          45, 8),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 45,
          8),
      error(ParserErrorCode.MISSING_IDENTIFIER, 52, 1),
    ]);
  }

  test_visitInterpolationExpression_list() async {
    await assertErrorsInCode(r'''
const x = '${const [2]}';
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 11, 12),
    ]);
  }

  test_visitIsExpression_is_functionType_correctTypes() async {
    await assertErrorsInCode('''
void foo(int a) {}
const c = foo is void Function(int);
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 29, 25),
    ]);
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitIsExpression_is_instanceOfSameClass() async {
    await assertErrorsInCode('''
const a = const A();
const b = a is A;
class A {
  const A();
}
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 31, 6),
    ]);
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_instanceOfSubclass() async {
    await assertErrorsInCode('''
const a = const B();
const b = a is A;
class A {
  const A();
}
class B extends A {
  const B();
}
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 31, 6),
    ]);
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_null() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is A;
class A {}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_null_nullable() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is A?;
class A {}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_null_object() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is Object;
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSameClass() async {
    await assertErrorsInCode('''
const a = const A();
const b = a is! A;
class A {
  const A();
}
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_FALSE, 31, 7),
    ]);
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSubclass() async {
    await assertErrorsInCode('''
const a = const B();
const b = a is! A;
class A {
  const A();
}
class B extends A {
  const B();
}
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_FALSE, 31, 7),
    ]);
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_isNot_null() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is! A;
class A {}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitListLiteral_forElement() async {
    await assertErrorsInCode(r'''
const x = [for (int i = 0; i < 3; i++) i];
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          31),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 11, 29),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitListLiteral_ifElement_nonBoolCondition() async {
    await assertErrorsInCode(r'''
const dynamic c = 2;
const x = [1, if (c) 2 else 3, 4];
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 39, 1),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitListLiteral_ifElement_nonBoolCondition_static() async {
    await assertErrorsInCode(r'''
const x = [1, if (1) 2 else 3, 4];
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 18, 1),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitListLiteral_listElement_explicitType() async {
    await assertNoErrorsInCode(r'''
const x = <String>['a', 'b', 'c'];
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
List
  elementType: String
  elements
    String a
    String b
    String c
  variable: self::@variable::x
''');
  }

  test_visitListLiteral_listElement_explicitType_functionType() async {
    await assertNoErrorsInCode(r'''
const x = <void Function()>[];
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
List
  elementType: void Function()
  variable: self::@variable::x
''');
  }

  test_visitListLiteral_listElement_simple() async {
    await assertNoErrorsInCode(r'''
const x = ['a', 'b', 'c'];
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
List
  elementType: String
  elements
    String a
    String b
    String c
  variable: self::@variable::x
''');
  }

  test_visitListLiteral_listElement_variableElements() async {
    await assertNoErrorsInCode(r'''
const a = 0;
const b = 2;
const c = [a, 1, b];
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
List
  elementType: int
  elements
    int 0
      variable: self::@variable::a
    int 1
    int 2
      variable: self::@variable::b
  variable: self::@variable::c
''');
  }

  test_visitListLiteral_spreadElement() async {
    await assertErrorsInCode(r'''
const dynamic a = 5;
const x = <int>[...a];
''', [
      error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET, 40, 1),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitListLiteral_spreadElement_null() async {
    await assertNoErrorsInCode('''
const a = null;
const List<String> x = [
  'anotherString',
  ...?a,
];
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, '''
List
  elementType: String
  elements
    String anotherString
  variable: self::@variable::x
''');
  }

  test_visitListLiteral_spreadElement_set() async {
    await assertNoErrorsInCode('''
const a = {'string'};
const List<String> x = [
  'anotherString',
  ...a,
];
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, '''
List
  elementType: String
  elements
    String anotherString
    String string
  variable: self::@variable::x
''');
  }

  test_visitMethodInvocation_notIdentical() async {
    await assertErrorsInCode(r'''
int f() {
  return 3;
}
const a = f();
''', [
      error(CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION, 34, 3),
    ]);
  }

  test_visitNamedType_typeLiteral_typeParameter_nested() async {
    await assertErrorsInCode(r'''
void f<T>(Object? x) {
  if (x case const (T)) {}
}
''', [
      error(CompileTimeErrorCode.CONST_TYPE_PARAMETER, 43, 1),
    ]);
  }

  test_visitNamedType_typeLiteral_typeParameter_nested2() async {
    await assertErrorsInCode(r'''
void f<T>(Object? x) {
  if (x case const (List<T>)) {}
}
''', [
      error(CompileTimeErrorCode.CONST_TYPE_PARAMETER, 43, 7),
    ]);
  }

  test_visitPrefixedIdentifier_function() async {
    await assertNoErrorsInCode('''
import '' as self;
void f(int a) {}
const g = self.f;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@function::f
  variable: self::@variable::g
''');
  }

  test_visitPrefixedIdentifier_genericFunction_instantiated() async {
    await assertNoErrorsInCode('''
import '' as self;
void f<T>(T a) {}
const void Function(int) g = self.f;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@function::f
  typeArguments
    int
  variable: self::@variable::g
''');
  }

  test_visitPrefixedIdentifier_genericFunction_instantiatedNonIdentifier() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
const b = false;
const g1 = f;
const g2 = f;
const void Function(int) h = b ? g1 : g2;
''');
    final result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@function::f
  typeArguments
    int
  variable: self::@variable::h
''');
  }

  test_visitPrefixedIdentifier_genericFunction_instantiatedPrefixed() async {
    await assertNoErrorsInCode('''
import '' as self;
void f<T>(T a) {}
const g = f;
const void Function(int) h = self.g;
''');
    final result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@function::f
  typeArguments
    int
  variable: self::@variable::h
''');
  }

  test_visitPrefixedIdentifier_genericVariable_uninstantiated() async {
    await assertNoErrorsInCode('''
import '' as self;
void f<T>(T a) {}
const g = f;
const h = self.g;
''');
    final result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function<T>(T)
  element: self::@function::f
  variable: self::@variable::h
''');
  }

  test_visitPrefixedIdentifier_length_invalidTarget() async {
    await assertErrorsInCode('''
void main() {
  const RequiresNonEmptyList([1]);
}

class RequiresNonEmptyList {
  const RequiresNonEmptyList(List<int> numbers) : assert(numbers.length > 0);
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_PROPERTY_ACCESS,
        16,
        31,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 138, 14,
              text:
                  "The error is in the assert initializer of 'RequiresNonEmptyList', and occurs here."),
        ],
      ),
    ]);
  }

  test_visitPrefixExpression_bitNot() async {
    await assertNoErrorsInCode('''
const c = ~42;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, '''
int -43
  variable: self::@variable::c
''');
  }

  test_visitPrefixExpression_extensionMethod() async {
    await assertErrorsInCode('''
extension on Object {
  int operator -() => 0;
}

const Object v1 = 1;
const v2 = -v1;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_EXTENSION_METHOD, 82, 3),
    ]);
    final result = _topLevelVar('v2');
    _assertNull(result);
  }

  test_visitPrefixExpression_logicalNot() async {
    await assertNoErrorsInCode('''
const c = !true;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitPrefixExpression_negated_bool() async {
    await assertErrorsInCode('''
const c = -true;
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 10, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_NUM, 10, 5),
    ]);
  }

  test_visitPrefixExpression_negated_double() async {
    await assertNoErrorsInCode('''
const c = -42.3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double -42.3
  variable: self::@variable::c
''');
  }

  test_visitPrefixExpression_negated_int() async {
    await assertNoErrorsInCode('''
const c = -42;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int -42
  variable: self::@variable::c
''');
  }

  test_visitPropertyAccess_genericFunction_instantiated() async {
    await assertNoErrorsInCode('''
import '' as self;
class C {
  static void f<T>(T a) {}
}
const void Function(int) g = self.C.f;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@class::C::@method::f
  typeArguments
    int
  variable: self::@variable::g
''');
  }

  test_visitPropertyAccess_length_complex() async {
    await assertNoErrorsInCode('''
const x = ('qwe' + 'rty').length;
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
int 6
  variable: self::@variable::x
''');
  }

  test_visitPropertyAccess_length_simple() async {
    await assertNoErrorsInCode('''
const x = 'Dvorak'.length;
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
int 6
  variable: self::@variable::x
''');
  }

  test_visitRecordLiteral_mixedTypes() async {
    await assertNoErrorsInCode(r'''
const x = (0, f1: 10, f2: 2.3);
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
Record(int, {int f1, double f2})
  positionalFields
    $1: int 0
  namedFields
    f1: int 10
    f2: double 2.3
  variable: self::@variable::x
''');
  }

  test_visitRecordLiteral_named() async {
    await assertNoErrorsInCode(r'''
const x = (f1: 10, f2: -3);
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
Record({int f1, int f2})
  namedFields
    f1: int 10
    f2: int -3
  variable: self::@variable::x
''');
  }

  test_visitRecordLiteral_objectField_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final (T, T) record;
  const A(T a) : record = (a, a);
}

const a = A(42);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
A<int>
  record: Record(int, int)
    positionalFields
      $1: int 42
      $2: int 42
  variable: self::@variable::a
''');
  }

  test_visitRecordLiteral_positional() async {
    await assertNoErrorsInCode(r'''
const x = (20, 0, 7);
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
Record(int, int, int)
  positionalFields
    $1: int 20
    $2: int 0
    $3: int 7
  variable: self::@variable::x
''');
  }

  test_visitRecordLiteral_withoutEnvironment() async {
    await assertNoErrorsInCode(r'''
const a = (1, 'b', c: false);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
Record(int, String, {bool c})
  positionalFields
    $1: int 1
    $2: String b
  namedFields
    c: bool false
  variable: self::@variable::a
''');
  }

  test_visitSetOrMapLiteral_ambiguous() async {
    await assertErrorsInCode(r'''
const l = [];
const ambiguous = {...l, 1: 2};
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, 32, 12),
    ]);
  }

  test_visitSetOrMapLiteral_ambiguous_either() async {
    await assertErrorsInCode(r'''
const int? i = 1;
const res  = {...?i};
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 31, 7),
    ]);
  }

  test_visitSetOrMapLiteral_ambiguous_expression() async {
    await assertErrorsInCode(r'''
const m = {1: 1};
const res = {...m, 2};
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, 30, 9),
    ]);
  }

  test_visitSetOrMapLiteral_ambiguous_inList() async {
    await assertErrorsInCode(r'''
const l = [];
const ambiguous = {...l, 1: 2};
const anotherList = [...ambiguous];
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, 32, 12),
    ]);
  }

  test_visitSetOrMapLiteral_map_complexKey() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  const A(this.x);
}
void fn() => 2;
const x = {A(0): 1, fn: 2};
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, r'''
Map
  entries
    entry
      key: A
        x: int 0
      value: int 1
    entry
      key: void Function()
        element: self::@function::fn
      value: int 2
  variable: self::@variable::x
''');
  }

  test_visitSetOrMapLiteral_map_forElement() async {
    await assertErrorsInCode(r'''
const x = {1: null, for (final i in const []) i: null};
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          44),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 20, 33),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_map_forElement_nested() async {
    await assertErrorsInCode(r'''
const x = {1: null, if (true) for (final i in const []) i: null};
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          54),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 30, 33),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_map_ifElement_nonBoolCondition() async {
    await assertErrorsInCode(r'''
const dynamic nonBool = null;
const c = const {if (nonBool) 'a' : 1};
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 51, 7),
    ]);
    final result = _topLevelVar('c');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_map_mapElement() async {
    await assertNoErrorsInCode(r'''
const x = {'a' : 'm', 'b' : 'n', 'c' : 'o'};
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, '''
Map
  entries
    entry
      key: String a
      value: String m
    entry
      key: String b
      value: String n
    entry
      key: String c
      value: String o
  variable: self::@variable::x
''');
  }

  test_visitSetOrMapLiteral_map_spread() async {
    await assertNoErrorsInCode('''
const x = {'string': 1};
const Map<String, int> alwaysInclude = {
  'anotherString': 0,
  ...x,
};
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, '''
Map
  entries
    entry
      key: String string
      value: int 1
  variable: self::@variable::x
''');
  }

  test_visitSetOrMapLiteral_map_spread_notMap() async {
    await assertErrorsInCode('''
const x = ['string'];
const Map<String, int> alwaysInclude = {
  'anotherString': 0,
  ...x,
};
''', [
      error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP, 90, 1),
      error(CompileTimeErrorCode.NOT_MAP_SPREAD, 90, 1),
    ]);
  }

  test_visitSetOrMapLiteral_map_spread_null() async {
    await assertNoErrorsInCode('''
const a = null;
const Map<String, int> x = {
  'anotherString': 0,
  ...?a,
};
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, '''
Map
  entries
    entry
      key: String anotherString
      value: int 0
  variable: self::@variable::x
''');
  }

  test_visitSetOrMapLiteral_set_double_zeros() async {
    await assertNoErrorsInCode(r'''
class C {
  final double x;
  const C(this.x);
}

const cp0 = C(0.0);
const cm0 = C(-0.0);

const a = {cp0, cm0};
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
Set
  elements
    C
      x: double 0.0
      variable: self::@variable::cp0
    C
      x: double -0.0
      variable: self::@variable::cm0
  variable: self::@variable::a
''');
  }

  test_visitSetOrMapLiteral_set_forElement() async {
    await assertErrorsInCode(r'''
const Set set = {};
const x = {for (final i in set) i};
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 30,
          24),
      error(CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT, 31, 22),
    ]);
    final result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_set_ifElement_nonBoolCondition() async {
    await assertErrorsInCode(r'''
const dynamic nonBool = 'a';
const c = const {if (nonBool) 3};
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 50, 7),
    ]);
    final result = _topLevelVar('c');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_set_spread_list() async {
    await assertNoErrorsInCode('''
const a = ['string'];
const Set<String> x = {
  'anotherString',
  ...a,
};
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, '''
Set
  elements
    String anotherString
    String string
  variable: self::@variable::x
''');
  }

  test_visitSetOrMapLiteral_set_spread_null() async {
    await assertNoErrorsInCode('''
const a = null;
const Set<String> x = {
  'anotherString',
  ...?a,
};
''');
    final result = _topLevelVar('x');
    assertDartObjectText(result, '''
Set
  elements
    String anotherString
  variable: self::@variable::x
''');
  }

  test_visitSimpleIdentifier_className() async {
    await assertNoErrorsInCode('''
const a = C;
class C {}
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
Type C*
  variable: self::@variable::a
''');
  }

  test_visitSimpleIdentifier_function() async {
    await assertNoErrorsInCode('''
void f(int a) {}
const g = f;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@function::f
  variable: self::@variable::g
''');
  }

  test_visitSimpleIdentifier_genericFunction_instantiated() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
const void Function(int) g = f;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@function::f
  typeArguments
    int
  variable: self::@variable::g
''');
  }

  test_visitSimpleIdentifier_genericFunction_nonGeneric() async {
    await assertNoErrorsInCode('''
void f(int a) {}
const void Function(int) g = f;
''');
    final result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@function::f
  variable: self::@variable::g
''');
  }

  test_visitSimpleIdentifier_genericVariable_instantiated() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
const g = f;
const void Function(int) h = g;
''');
    final result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int)
  element: self::@function::f
  typeArguments
    int
  variable: self::@variable::h
''');
  }

  test_visitSimpleIdentifier_genericVariable_uninstantiated() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
const g = f;
const h = g;
''');
    final result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function<T>(T)
  element: self::@function::f
  variable: self::@variable::h
''');
  }

  test_visitSimpleIdentifier_instantiatedFunctionType_field() async {
    await assertNoErrorsInCode('''
void f<T>(T a, {T? b}) {}

class C {
  static const void Function<T>(T a) g = f;
  static const void Function(int a) h = g;
}
''');
    final result = _field('h');
    assertDartObjectText(result, '''
void Function(int, {int? b})
  element: self::@function::f
  typeArguments
    int
  variable: self::@class::C::@field::h
''');
  }

  test_visitSimpleIdentifier_instantiatedFunctionType_parameter() async {
    await assertNoErrorsInCode('''
void f<T>(T a, {T? b}) {}

class C {
  const C(void Function<T>(T a) g) : h = g;
  final void Function(int a) h;
}

const c = C(f);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, '''
C
  h: void Function(int, {int? b})
    element: self::@function::f
    typeArguments
      int
  variable: self::@variable::c
''');
  }

  test_visitSimpleIdentifier_instantiatedFunctionType_variable() async {
    await assertNoErrorsInCode('''
void f<T>(T a, {T? b}) {}

const void Function<T>(T a) g = f;

const void Function(int a) h = g;
''');
    final result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int, {int? b})
  element: self::@function::f
  typeArguments
    int
  variable: self::@variable::h
''');
  }

  void _assertHasPrimitiveEqualityFalse(String name) {
    final value = _evaluateConstant(name);
    final featureSet = result.libraryElement.featureSet;
    final has = value.hasPrimitiveEquality(featureSet);
    expect(has, isFalse);
  }

  void _assertHasPrimitiveEqualityTrue(String name) {
    final value = _evaluateConstant(name);
    final featureSet = result.libraryElement.featureSet;
    final has = value.hasPrimitiveEquality(featureSet);
    expect(has, isTrue);
  }
}

@reflectiveTest
mixin ConstantVisitorTestCases on ConstantVisitorTestSupport {
  test_listLiteral_ifElement_false_withElse() async {
    await resolveTestCode('''
const c = [1, if (1 < 0) 2 else 3, 4];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType(typeProvider.intType));
    expect(result.toListValue()!.map((e) => e.toIntValue()), [1, 3, 4]);
  }

  test_listLiteral_ifElement_false_withoutElse() async {
    await resolveTestCode('''
const c = [1, if (1 < 0) 2, 3];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType(typeProvider.intType));
    expect(result.toListValue()!.map((e) => e.toIntValue()), [1, 3]);
  }

  test_listLiteral_ifElement_true_withElse() async {
    await resolveTestCode('''
const c = [1, if (1 > 0) 2 else 3, 4];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType(typeProvider.intType));
    expect(result.toListValue()!.map((e) => e.toIntValue()), [1, 2, 4]);
  }

  test_listLiteral_ifElement_true_withoutElse() async {
    await resolveTestCode('''
const c = [1, if (1 > 0) 2, 3];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType(typeProvider.intType));
    expect(result.toListValue()!.map((e) => e.toIntValue()), [1, 2, 3]);
  }

  test_listLiteral_nested() async {
    await resolveTestCode('''
const c = [1, if (1 > 0) if (2 > 1) 2, 3];
''');
    DartObjectImpl result = _evaluateConstant('c');
    // The expected type ought to be `List<int>`, but type inference isn't yet
    // implemented.
    expect(result.type, typeProvider.listType(typeProvider.intType));
    expect(result.toListValue()!.map((e) => e.toIntValue()), [1, 2, 3]);
  }

  test_listLiteral_spreadElement() async {
    await resolveTestCode('''
const c = [1, ...[2, 3], 4];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType(typeProvider.intType));
    expect(result.toListValue()!.map((e) => e.toIntValue()), [1, 2, 3, 4]);
  }

  test_mapLiteral_ifElement_false_withElse() async {
    await resolveTestCode('''
const c = {'a' : 1, if (1 < 0) 'b' : 2 else 'c' : 3, 'd' : 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type,
        typeProvider.mapType(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(value.keys.map((e) => e.toStringValue()),
        unorderedEquals(['a', 'c', 'd']));
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 3, 4]));
  }

  test_mapLiteral_ifElement_false_withoutElse() async {
    await resolveTestCode('''
const c = {'a' : 1, if (1 < 0) 'b' : 2, 'c' : 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type,
        typeProvider.mapType(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(
        value.keys.map((e) => e.toStringValue()), unorderedEquals(['a', 'c']));
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 3]));
  }

  test_mapLiteral_ifElement_true_withElse() async {
    await resolveTestCode('''
const c = {'a' : 1, if (1 > 0) 'b' : 2 else 'c' : 3, 'd' : 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type,
        typeProvider.mapType(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(value.keys.map((e) => e.toStringValue()),
        unorderedEquals(['a', 'b', 'd']));
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 2, 4]));
  }

  test_mapLiteral_ifElement_true_withoutElse() async {
    await resolveTestCode('''
const c = {'a' : 1, if (1 > 0) 'b' : 2, 'c' : 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type,
        typeProvider.mapType(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(value.keys.map((e) => e.toStringValue()),
        unorderedEquals(['a', 'b', 'c']));
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 2, 3]));
  }

  @failingTest
  test_mapLiteral_nested() async {
    // Fails because we're not yet parsing nested elements.
    await resolveTestCode('''
const c = {'a' : 1, if (1 > 0) if (2 > 1) {'b' : 2}, 'c' : 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type,
        typeProvider.mapType(typeProvider.intType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(value.keys.map((e) => e.toStringValue()),
        unorderedEquals(['a', 'b', 'c']));
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 2, 3]));
  }

  test_mapLiteral_spreadElement() async {
    await resolveTestCode('''
const c = {'a' : 1, ...{'b' : 2, 'c' : 3}, 'd' : 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type,
        typeProvider.mapType(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(value.keys.map((e) => e.toStringValue()),
        unorderedEquals(['a', 'b', 'c', 'd']));
    expect(
        value.values.map((e) => e.toIntValue()), unorderedEquals([1, 2, 3, 4]));
  }

  test_setLiteral_ifElement_false_withElse() async {
    await resolveTestCode('''
const c = {1, if (1 < 0) 2 else 3, 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType(typeProvider.intType));
    expect(result.toSetValue()!.map((e) => e.toIntValue()), [1, 3, 4]);
  }

  test_setLiteral_ifElement_false_withoutElse() async {
    await resolveTestCode('''
const c = {1, if (1 < 0) 2, 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType(typeProvider.intType));
    expect(result.toSetValue()!.map((e) => e.toIntValue()), [1, 3]);
  }

  test_setLiteral_ifElement_true_withElse() async {
    await resolveTestCode('''
const c = {1, if (1 > 0) 2 else 3, 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType(typeProvider.intType));
    expect(result.toSetValue()!.map((e) => e.toIntValue()), [1, 2, 4]);
  }

  test_setLiteral_ifElement_true_withoutElse() async {
    await resolveTestCode('''
const c = {1, if (1 > 0) 2, 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType(typeProvider.intType));
    expect(result.toSetValue()!.map((e) => e.toIntValue()), [1, 2, 3]);
  }

  test_setLiteral_nested() async {
    await resolveTestCode('''
const c = {1, if (1 > 0) if (2 > 1) 2, 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType(typeProvider.intType));
    expect(result.toSetValue()!.map((e) => e.toIntValue()), [1, 2, 3]);
  }

  test_setLiteral_spreadElement() async {
    await resolveTestCode('''
const c = {1, ...{2, 3}, 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType(typeProvider.intType));
    expect(result.toSetValue()!.map((e) => e.toIntValue()), [1, 2, 3, 4]);
  }

  test_visitAdjacentInterpolation_simple() async {
    await assertNoErrorsInCode('''
const c = 'abc' 'def';
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, '''
String abcdef
  variable: self::@variable::c
''');
  }

  test_visitAsExpression_instanceOfSameClass() async {
    await resolveTestCode('''
const a = const A();
const b = a as A;
class A {
  const A();
}
''');
    DartObjectImpl resultA = _evaluateConstant('a');
    DartObjectImpl resultB = _evaluateConstant('b');
    expect(resultB, resultA);
  }

  test_visitAsExpression_instanceOfSubclass() async {
    await resolveTestCode('''
const a = const B();
const b = a as A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl resultA = _evaluateConstant('a');
    DartObjectImpl resultB = _evaluateConstant('b');
    expect(resultB, resultA);
  }

  test_visitAsExpression_instanceOfSuperclass() async {
    await assertErrorsInCode('''
const a = const A();
const b = a as B;
class A {
  const A();
}
class B extends A {
  const B();
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 31, 6),
    ]);
    var result = _topLevelVar('b');
    _assertNull(result);
  }

  test_visitAsExpression_instanceOfUnrelatedClass() async {
    await assertErrorsInCode('''
const a = const A();
const b = a as B;
class A {
  const A();
}
class B {
  const B();
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 31, 6),
    ]);
    var result = _topLevelVar('b');
    _assertNull(result);
  }

  test_visitAsExpression_potentialConst() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}

class MyClass {
  final A a;
  const MyClass(Object o) : a = o as A;
}
''');
  }

  test_visitBinaryExpression_add_double_double() async {
    await assertNoErrorsInCode('''
const c = 2.3 + 3.2;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 5.5
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_add_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 + 3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 5
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_add_string_string() async {
    await assertNoErrorsInCode('''
const c = 'a' + 'b';
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
String ab
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_and_bool_bool() async {
    await assertNoErrorsInCode('''
const c = true && false;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_and_bool_false_invalid() async {
    await assertErrorsInCode('''
final a = false;
const c = false && a;
''', [
      error(WarningCode.DEAD_CODE, 33, 4),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 36,
          1),
    ]);
  }

  test_visitBinaryExpression_and_bool_invalid_false() async {
    await assertErrorsInCode('''
final a = false;
const c = a && false;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 27,
          1),
    ]);
  }

  test_visitBinaryExpression_and_bool_invalid_true() async {
    await assertErrorsInCode('''
final a = false;
const c = a && true;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 27,
          1),
    ]);
  }

  test_visitBinaryExpression_and_bool_known_known() async {
    await resolveTestCode('''
const c = false & true;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_and_bool_known_unknown() async {
    await resolveTestCode('''
const b = bool.fromEnvironment('y');
const c = false & b;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_and_bool_true_invalid() async {
    await assertErrorsInCode('''
final a = false;
const c = true && a;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 27,
          9),
    ]);
  }

  test_visitBinaryExpression_and_bool_unknown_known() async {
    await resolveTestCode('''
const a = bool.fromEnvironment('x');
const c = a & true;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_and_bool_unknown_unknown() async {
    await resolveTestCode('''
const a = bool.fromEnvironment('x');
const b = bool.fromEnvironment('y');
const c = a & b;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_and_int() async {
    await assertNoErrorsInCode('''
const c = 74 & 42;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 10
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_and_mixed() async {
    await assertErrorsInCode('''
const c = 3 & false;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT, 10, 9),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 14, 5),
    ]);
  }

  test_visitBinaryExpression_divide_double_double() async {
    await assertNoErrorsInCode('''
const c = 3.2 / 2.3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 1.3913043478260871
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_divide_double_double_byZero() async {
    await assertNoErrorsInCode('''
const c = 3.2 / 0.0;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double Infinity
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_divide_int_int() async {
    await assertNoErrorsInCode('''
const c = 3 / 2;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 1.5
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_divide_int_int_byZero() async {
    await assertNoErrorsInCode('''
const c = 3 / 0;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double Infinity
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_minus_double_double() async {
    await assertNoErrorsInCode('''
const c = 3.2 - 2.3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 0.9000000000000004
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_minus_int_int() async {
    await assertNoErrorsInCode('''
const c = 3 - 2;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 1
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_notEqual_bool_bool() async {
    await assertNoErrorsInCode('''
const c = true != false;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_notEqual_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 != 3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_notEqual_invalidLeft() async {
    await assertErrorsInCode('''
const c = a != 3;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          1),
    ]);
  }

  test_visitBinaryExpression_notEqual_invalidRight() async {
    await assertErrorsInCode('''
const c = 2 != a;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 15,
          1),
    ]);
  }

  test_visitBinaryExpression_notEqual_string_string() async {
    await assertNoErrorsInCode('''
const c = 'a' != 'b';
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_or_bool_false_invalid() async {
    await assertErrorsInCode('''
final a = false;
const c = false || a;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 27,
          10),
    ]);
  }

  test_visitBinaryExpression_or_bool_invalid_false() async {
    await assertErrorsInCode('''
final a = false;
const c = a || false;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 27,
          1),
    ]);
  }

  test_visitBinaryExpression_or_bool_invalid_true() async {
    await assertErrorsInCode('''
final a = false;
const c = a || true;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 27,
          1),
    ]);
  }

  test_visitBinaryExpression_or_bool_known_known() async {
    await resolveTestCode('''
const c = false | true;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_or_bool_known_unknown() async {
    await resolveTestCode('''
const b = bool.fromEnvironment('y');
const c = false | b;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_or_bool_true_invalid() async {
    await assertErrorsInCode('''
final a = false;
const c = true || a;
''', [
      error(WarningCode.DEAD_CODE, 32, 4),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 35,
          1),
    ]);
  }

  test_visitBinaryExpression_or_bool_unknown_known() async {
    await resolveTestCode('''
const a = bool.fromEnvironment('x');
const c = a | true;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_or_bool_unknown_unknown() async {
    await resolveTestCode('''
const a = bool.fromEnvironment('x');
const b = bool.fromEnvironment('y');
const c = a | b;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_or_int() async {
    await resolveTestCode('''
const c = 3 | 5;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
  }

  test_visitBinaryExpression_or_known_known() async {
    await assertErrorsInCode('''
const c = true || false;
''', [
      error(WarningCode.DEAD_CODE, 15, 8),
    ]);
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitBinaryExpression_or_mixed() async {
    await assertErrorsInCode('''
const c = 3 | false;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT, 10, 9),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 14, 5),
    ]);
  }

  test_visitBinaryExpression_questionQuestion_notNull_notNull() async {
    await resolveTestCode('''
const c = 'a' ?? 'b';
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.stringType);
    expect(result.toStringValue(), 'a');
  }

  test_visitBinaryExpression_questionQuestion_null_invalid() async {
    await assertErrorsInCode('''
const c = null ?? new C();
class C {}
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 18,
          7),
    ]);
  }

  test_visitBinaryExpression_questionQuestion_null_notNull() async {
    await resolveTestCode('''
const c = null ?? 'b';
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.stringType);
    expect(result.toStringValue(), 'b');
  }

  test_visitBinaryExpression_questionQuestion_null_null() async {
    await resolveTestCode('''
const c = null ?? null;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.isNull, isTrue);
  }

  test_visitBinaryExpression_xor_bool_known_known() async {
    await resolveTestCode('''
const c = false ^ true;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_xor_bool_known_unknown() async {
    await resolveTestCode('''
const b = bool.fromEnvironment('y');
const c = false ^ b;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_xor_bool_unknown_known() async {
    await resolveTestCode('''
const a = bool.fromEnvironment('x');
const c = a ^ true;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_xor_bool_unknown_unknown() async {
    await resolveTestCode('''
const a = bool.fromEnvironment('x');
const b = bool.fromEnvironment('y');
const c = a ^ b;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.boolType);
  }

  test_visitBinaryExpression_xor_int() async {
    await resolveTestCode('''
const c = 3 ^ 5;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
  }

  test_visitBinaryExpression_xor_mixed() async {
    await assertErrorsInCode('''
const c = 3 ^ false;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT, 10, 9),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 14, 5),
    ]);
  }

  test_visitBoolLiteral_false() async {
    await assertNoErrorsInCode('''
const c = false;
''');
    final result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitBoolLiteral_true() async {
    await assertNoErrorsInCode('''
const c = true;
''');
    final result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitConditionalExpression_eager_false_int_int() async {
    await assertErrorsInCode('''
const c = false ? 1 : 0;
''', [
      error(WarningCode.DEAD_CODE, 18, 1),
    ]);
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: self::@variable::c
''');
  }

  test_visitConditionalExpression_eager_true_int_int() async {
    await assertErrorsInCode('''
const c = true ? 1 : 0;
''', [
      error(WarningCode.DEAD_CODE, 21, 1),
    ]);
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 1
  variable: self::@variable::c
''');
  }

  test_visitConditionalExpression_eager_true_int_invalid() async {
    await assertErrorsInCode('''
const c = true ? 1 : x;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 21, 1),
      error(WarningCode.DEAD_CODE, 21, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 21,
          1),
    ]);
  }

  test_visitConditionalExpression_eager_true_invalid_int() async {
    await assertErrorsInCode('''
const c = true ? x : 0;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 17, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 17,
          1),
      error(WarningCode.DEAD_CODE, 21, 1),
    ]);
  }

  test_visitConditionalExpression_lazy_false_int_int() async {
    await assertErrorsInCode('''
const c = false ? 1 : 0;
''', [
      error(WarningCode.DEAD_CODE, 18, 1),
    ]);
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: self::@variable::c
''');
  }

  test_visitConditionalExpression_lazy_false_int_invalid() async {
    await assertErrorsInCode('''
const c = false ? 1 : new C();
''', [
      error(WarningCode.DEAD_CODE, 18, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 22,
          7),
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 26, 1),
    ]);
  }

  test_visitConditionalExpression_lazy_false_invalid_int() async {
    await assertErrorsInCode('''
const c = false ? new C() : 0;
''', [
      error(WarningCode.DEAD_CODE, 18, 7),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 18,
          7),
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 22, 1),
    ]);
  }

  test_visitConditionalExpression_lazy_invalid_int_int() async {
    await assertErrorsInCode('''
const c = 3 ? 1 : 0;
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 10, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 1),
    ]);
  }

  test_visitConditionalExpression_lazy_true_int_int() async {
    await assertErrorsInCode('''
const c = true ? 1 : 0;
''', [
      error(WarningCode.DEAD_CODE, 21, 1),
    ]);
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 1
  variable: self::@variable::c
''');
  }

  test_visitConditionalExpression_lazy_true_int_invalid() async {
    await assertErrorsInCode('''
const c = true ? 1: new C();
''', [
      error(WarningCode.DEAD_CODE, 20, 7),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 20,
          7),
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 24, 1),
    ]);
  }

  test_visitConditionalExpression_lazy_true_invalid_int() async {
    await assertErrorsInCode('''
const c = true ? new C() : 0;
class C {}
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 17,
          7),
      error(WarningCode.DEAD_CODE, 27, 1),
    ]);
  }

  test_visitConditionalExpression_lazy_unknown_int_invalid() async {
    await assertErrorsInCode('''
const c = identical(0, 0.0) ? 1 : new Object();
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 34,
          12),
    ]);
  }

  test_visitConditionalExpression_lazy_unknown_invalid_int() async {
    await assertErrorsInCode('''
const c = identical(0, 0.0) ? 1 : new Object();
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 34,
          12),
    ]);
  }

  test_visitDoubleLiteral() async {
    await assertNoErrorsInCode('''
const c = 3.45;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 3.45
  variable: self::@variable::c
''');
  }

  test_visitIntegerLiteral_doubleType() async {
    await resolveTestCode('''
const double d = 3;
''');
    DartObjectImpl result = _evaluateConstant('d');
    expect(result.type, typeProvider.doubleType);
    expect(result.toDoubleValue(), 3.0);
  }

  test_visitIntegerLiteral_integer() async {
    await assertNoErrorsInCode('''
const c = 3;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 3
  variable: self::@variable::c
''');
  }

  test_visitIsExpression_is_functionType_badTypes() async {
    await assertNoErrorsInCode('''
void foo(int a) {}
const c = foo is void Function(String);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitIsExpression_is_functionType_nonFunction() async {
    await assertNoErrorsInCode('''
const c = false is void Function();
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::c
''');
  }

  test_visitIsExpression_is_instanceOfSuperclass() async {
    await assertNoErrorsInCode('''
const a = const A();
const b = a is B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_instanceOfUnrelatedClass() async {
    await assertNoErrorsInCode('''
const a = const A();
const b = a is B;
class A {
  const A();
}
class B {
  const B();
}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_null_dynamic() async {
    await assertErrorsInCode('''
const a = null;
const b = a is dynamic;
class A {}
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 26, 12),
    ]);
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_null_null() async {
    await assertErrorsInCode('''
const a = null;
const b = a is Null;
class A {}
''', [
      error(WarningCode.TYPE_CHECK_IS_NULL, 26, 9),
    ]);
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSuperclass() async {
    await assertNoErrorsInCode('''
const a = const A();
const b = a is! B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfUnrelatedClass() async {
    await assertNoErrorsInCode('''
const a = const A();
const b = a is! B;
class A {
  const A();
}
class B {
  const B();
}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitNullLiteral_null() async {
    await assertNoErrorsInCode('''
const c = null;
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, '''
Null null
  variable: self::@variable::c
''');
  }

  test_visitParenthesizedExpression_string() async {
    await assertNoErrorsInCode('''
const a = ('a');
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
String a
  variable: self::@variable::a
''');
  }

  test_visitPropertyAccess_length_extension() async {
    await assertErrorsInCode('''
extension ExtObject on Object {
  int get length => 4;
}

class B {
  final l;
  const B(Object o) : l = o.length;
}

const b = B('');
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_EXTENSION_METHOD,
        128,
        5,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 105, 8,
              text:
                  "The error is in the field initializer of 'B', and occurs here."),
        ],
      ),
    ]);
  }

  test_visitPropertyAccess_length_unresolvedType() async {
    await assertErrorsInCode('''
class B {
  final l;
  const B(String o) : l = o.length;
}

const y = B(x);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_TYPE_STRING,
        70,
        4,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 47, 8,
              text:
                  "The error is in the field initializer of 'B', and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 72, 1),
      error(CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT, 72, 1),
    ]);
  }

  test_visitSimpleIdentifier_dynamic() async {
    await resolveTestCode('''
const a = dynamic;
''');
    DartObjectImpl result = _evaluateConstant('a');
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue(), typeProvider.dynamicType);
  }

  test_visitSimpleIdentifier_inEnvironment() async {
    await assertNoErrorsInCode(r'''
const a = b;
const b = 3;''');
    var environment = <String, DartObjectImpl>{
      'b': DartObjectImpl(typeSystem, typeProvider.intType, IntState(6)),
    };
    var result = _evaluateConstant('a', lexicalEnvironment: environment);
    assertDartObjectText(result, r'''
int 6
''');
  }

  test_visitSimpleIdentifier_notInEnvironment() async {
    await assertNoErrorsInCode(r'''
const a = b;
const b = 3;''');
    var environment = <String, DartObjectImpl>{
      'c': DartObjectImpl(typeSystem, typeProvider.intType, IntState(6)),
    };
    var result = _evaluateConstant('a', lexicalEnvironment: environment);
    assertDartObjectText(result, r'''
int 3
  variable: self::@variable::b
''');
  }

  test_visitSimpleIdentifier_variable() async {
    await assertNoErrorsInCode('''
const a = 42;
const b = a;
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, '''
int 42
  variable: self::@variable::b
''');
  }

  test_visitSimpleIdentifier_withoutEnvironment() async {
    await assertNoErrorsInCode(r'''
const a = b;
const b = 3;''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, r'''
int 3
  variable: self::@variable::a
''');
  }

  test_visitSimpleStringLiteral_valid() async {
    await assertNoErrorsInCode(r'''
const c = 'abc';
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, '''
String abc
  variable: self::@variable::c
''');
  }

  test_visitStringInterpolation_invalid() async {
    await assertErrorsInCode(r'''
const c = 'a${f()}c';
''', [
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 14, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 14,
          3),
    ]);
  }

  test_visitStringInterpolation_valid() async {
    await assertNoErrorsInCode(r'''
const c = 'a${3}c';
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
String a3c
  variable: self::@variable::c
''');
  }
}

class ConstantVisitorTestSupport extends PubPackageResolutionTest {
  void _assertNull(DartObjectImpl? result) {
    expect(result, isNull);
  }

  DartObjectImpl _evaluateConstant(
    String name, {
    List<ErrorCode>? errorCodes,
    Map<String, String> declaredVariables = const {},
    Map<String, DartObjectImpl>? lexicalEnvironment,
  }) {
    var expression = findNode.topVariableDeclarationByName(name).initializer!;
    return _evaluateExpression(
      expression,
      errorCodes: errorCodes,
      declaredVariables: declaredVariables,
      lexicalEnvironment: lexicalEnvironment,
    )!;
  }

  DartObjectImpl? _evaluateExpression(
    Expression expression, {
    List<ErrorCode>? errorCodes,
    Map<String, String> declaredVariables = const {},
    Map<String, DartObjectImpl>? lexicalEnvironment,
  }) {
    var unit = this.result.unit;
    var source = unit.declaredElement!.source;
    var errorListener = GatheringErrorListener();
    var errorReporter = ErrorReporter(
      errorListener,
      source,
      isNonNullableByDefault: false,
    );
    var constantVisitor = ConstantVisitor(
      ConstantEvaluationEngine(
        declaredVariables: DeclaredVariables.fromMap(declaredVariables),
        isNonNullableByDefault: unit.featureSet.isEnabled(Feature.non_nullable),
        configuration: ConstantEvaluationConfiguration(),
      ),
      this.result.libraryElement as LibraryElementImpl,
      errorReporter,
      lexicalEnvironment: lexicalEnvironment,
    );

    var expressionConstant =
        constantVisitor.evaluateAndReportInvalidConstant(expression);
    var result =
        expressionConstant is DartObjectImpl ? expressionConstant : null;
    if (errorCodes == null) {
      errorListener.assertNoErrors();
    } else {
      errorListener.assertErrorsWithCodes(errorCodes);
    }
    return result;
  }

  DartObjectImpl? _evaluationResult(ConstVariableElement element) {
    final evaluationResult = element.evaluationResult;
    switch (evaluationResult) {
      case null:
        fail('Not evaluated: ${element.name}');
      case InvalidConstant():
        return null;
      case DartObjectImpl():
        return evaluationResult;
    }
  }

  DartObjectImpl? _field(String variableName) {
    final element = findElement.field(variableName) as ConstVariableElement;
    return _evaluationResult(element);
  }

  DartObjectImpl? _localVar(String variableName) {
    final element = findElement.localVar(variableName) as ConstVariableElement;
    return _evaluationResult(element);
  }

  DartObjectImpl? _topLevelVar(String variableName) {
    final element = findElement.topVar(variableName) as ConstVariableElement;
    return _evaluationResult(element);
  }
}

@reflectiveTest
class ConstantVisitorWithoutNullSafetyTest extends ConstantVisitorTestSupport
    with ConstantVisitorTestCases, WithoutNullSafetyMixin {
  test_visitAsExpression_null() async {
    await resolveTestCode('''
const a = null;
const b = a as A;
class A {}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.nullType);
  }

  test_visitBinaryExpression_questionQuestion_invalid_notNull() async {
    await assertErrorsInCode('''
final x = 0;
const c = x ?? 1;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 23,
          1),
    ]);
  }

  test_visitBinaryExpression_questionQuestion_notNull_invalid() async {
    await assertErrorsInCode('''
final x = 1;
const c = 0 ?? x;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 28,
          1),
    ]);
  }

  test_visitConditionalExpression_eager_invalid_int_int() async {
    await assertErrorsInCode('''
const c = null ? 1 : 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 4),
    ]);
  }

  test_visitIsExpression_is_functionType_correctTypes() async {
    await assertNoErrorsInCode('''
void foo(int a) {}
const c = foo is void Function(int);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::c
''');
  }

  test_visitIsExpression_is_instanceOfSameClass() async {
    await assertNoErrorsInCode(
      '''
const a = const A();
const b = a is A;
class A {
  const A();
}
''',
    );
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_instanceOfSubclass() async {
    await assertNoErrorsInCode('''
const a = const B();
const b = a is A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_null() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is A;
class A {}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_is_null_object() async {
    await assertErrorsInCode('''
const a = null;
const b = a is Object;
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 26, 11),
    ]);
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSameClass() async {
    await assertNoErrorsInCode('''
const a = const A();
const b = a is! A;
class A {
  const A();
}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSubclass() async {
    await assertNoErrorsInCode('''
const a = const B();
const b = a is! A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }

  test_visitIsExpression_isNot_null() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is! A;
class A {}
''');
    final result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: self::@variable::b
''');
  }
}

@reflectiveTest
class InstanceCreationEvaluatorTest extends ConstantVisitorTestSupport
    with InstanceCreationEvaluatorTestCases {
  test_assertInitializer_assertIsNot_false() async {
    await assertErrorsInCode('''
class A {
  const A() : assert(0 is! int);
}

const a = const A(null);
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_FALSE, 31, 9),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        56,
        13,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 24, 17,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 64, 4),
    ]);
  }

  test_assertInitializer_assertIsNot_null_nullableType() async {
    await assertErrorsInCode('''
class A<T> {
  const A() : assert(null is! T);
}

const a = const A<int?>();
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        60,
        15,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 27, 18,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
    ]);
  }

  test_assertInitializer_assertIsNot_true() async {
    await assertErrorsInCode('''
class A {
  const A() : assert(0 is! String);
}

const a = const A(null);
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 67, 4),
    ]);
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  variable: self::@variable::a
''');
  }

  test_assertInitializer_enum_false() async {
    await assertErrorsInCode('''
enum E { a, b }
class A {
  const A(E e) : assert(e != E.a);
}
const c = const A(E.a);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        73,
        12,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 43, 16,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
    ]);
  }

  test_assertInitializer_enum_true() async {
    await assertNoErrorsInCode('''
enum E { a, b }
class A {
  const A(E e) : assert(e != E.a);
}
const c = const A(E.b);
''');
    final result = _topLevelVar('c');
    assertDartObjectText(result, '''
A
  variable: self::@variable::c
''');
  }

  test_assertInitializer_intInDoubleContext_assertIsDouble_true() async {
    await assertErrorsInCode('''
class A {
  const A(double x): assert(x is double);
}
const a = const A(0);
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 38, 11),
    ]);
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  variable: self::@variable::a
''');
  }

  test_assertInitializer_intInDoubleContext_true() async {
    await assertNoErrorsInCode('''
class A {
  const A(double x): assert((x + 3) / 2 == 1.5);
}
const v = const A(0);
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
A
  variable: self::@variable::v
''');
  }

  test_assertInitializer_simple_true() async {
    await assertErrorsInCode('''
class A {
  const A(): assert(1 is int);
}
const a = const A();
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 30, 8),
    ]);
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  variable: self::@variable::a
''');
  }

  test_assertInitializer_simpleInSuperInitializer_true() async {
    await assertErrorsInCode('''
class A {
  const A(): assert(1 is int);
}
class B extends A {
  const B() : super();
}
const b = const B();
''', [
      error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 30, 8),
    ]);
    var result = _topLevelVar('b');
    assertDartObjectText(result, '''
B
  (super): A
  variable: self::@variable::b
''');
  }

  test_assertInitializer_usingArgument_true() async {
    await assertNoErrorsInCode('''
class A {
  const A(int x): assert(x > 0);
}
const a = const A(1);
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  variable: self::@variable::a
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/50045
  test_bool_fromEnvironment_dartLibraryJsUtil() async {
    await resolveTestCode('''
const a = bool.fromEnvironment('dart.library.js_util');
''');

    assertDartObjectText(_topLevelVar('a'), '''
<unknown> bool
  variable: self::@variable::a
''');
  }

  test_fieldInitializer_functionReference_withTypeParameter() async {
    await assertNoErrorsInCode('''
void g<U>(U a) {}
class A<T> {
  final void Function(T) f;
  const A(): f = g;
}
const a = const A<int>();
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<int>
  f: void Function(int)
    element: self::@function::g
    typeArguments
      T
  variable: self::@variable::a
''');
  }

  test_fieldInitializer_typeParameter() async {
    await assertNoErrorsInCode('''
class A<T> {
  final Object f;
  const A(): f = T;
}
const a = const A<int>();
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<int>
  f: Type int
  variable: self::@variable::a
''');
  }

  test_fieldInitializer_typeParameter_implicitTypeArgs() async {
    await assertNoErrorsInCode('''
class A<T> {
  final Object f;
  const A(): f = T;
}
const a = const A();
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<dynamic>
  f: Type dynamic
  variable: self::@variable::a
''');
  }

  test_fieldInitializer_typeParameter_typeAlias() async {
    await assertNoErrorsInCode('''
class A<T, U> {
  final Object f, g;
  const A(): f = T, g = U;
}
typedef B<S> = A<int, S>;
const a = const B<String>();
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<int, String>
  f: Type int
  g: Type String
  variable: self::@variable::a
''');
  }

  test_fieldInitializer_typeParameter_withoutConstructorTearoffs() async {
    await assertErrorsInCode('''
// @dart=2.12
class A<T> {
  final Object f;
  const A(): f = T;
}
const a = const A<int>();
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 62, 1),
      error(
        CompileTimeErrorCode.INVALID_CONSTANT,
        77,
        14,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 62, 1,
              text:
                  "The error is in the field initializer of 'A', and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 77,
          14),
    ]);
    final result = _topLevelVar('a');
    _assertNull(result);
  }

  test_fieldInitializer_visitAsExpression_potentialConstType() async {
    await assertNoErrorsInCode('''
const num three = 3;

class C<T extends num> {
  final T w;
  const C() : w = three as T;
}

void main() {
  const C<int>().w;
}
''');
  }

  test_issue49389() async {
    await assertErrorsInCode('''
class Foo {
  const Foo({required this.bar});
  final Map<String, String> bar;
}

void main() {
  final data = <String, String>{};
  const Foo(bar: data);
}
''', [
      // TODO(kallentu): Fix [InvalidConstant.genericError] to handle
      // NamedExpressions.
      error(CompileTimeErrorCode.INVALID_CONSTANT, 148, 4),
    ]);
  }

  test_redirectingConstructor_typeParameter() async {
    await assertNoErrorsInCode('''
class A<T> {
  final Object f;
  const A(): this.named(T);
  const A.named(Object t): f = t;
}
const a = const A<int>();
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<int>
  f: Type int
  variable: self::@variable::a
''');
  }

  test_superInitializer_formalParameter_explicitSuper_hasNamedArgument_requiredNamed() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  final int b;
  const A({required this.a, required this.b});
}

class B extends A {
  final int c;
  const B(this.c, {required super.b}) : super(a: 1);
}

const x = B(3, b: 2);
''');

    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
B
  (super): A
    a: int 1
    b: int 2
  c: int 3
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_explicitSuper_hasNamedArgument_requiredPositional() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  final int b;
  const A(this.a, {required this.b});
}

class B extends A {
  final int c;
  const B(super.a, {required this.c}) : super(b: 2);
}

const x = B(1, c: 3);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
    b: int 2
  c: int 3
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_explicitSuper_requiredNamed() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A({required this.a});
}

class B extends A {
  final int b;
  const B(this.b, {required super.a}) : super();
}

const x = B(2, a: 1);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
  b: int 2
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_explicitSuper_requiredNamed_generic() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A({required this.a});
}

class B<T> extends A {
  final int b;
  const B(this.b, {required super.a}) : super();
}

const x = B<int>(2, a: 1);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B<int>
  (super): A
    a: int 1
  b: int 2
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_explicitSuper_requiredPositional() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A(this.a);
}

class B extends A {
  final int b;
  const B(super.a, this.b) : super();
}

const x = B(1, 2);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
  b: int 2
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_explicitSuper_requiredPositional_generic() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A(this.a);
}

class B<T> extends A {
  final int b;
  const B(super.a, this.b) : super();
}

const x = B<int>(1, 2);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B<int>
  (super): A
    a: int 1
  b: int 2
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_implicitSuper_requiredNamed() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A({required this.a});
}

class B extends A {
  final int b;
  const B(this.b, {required super.a});
}

const x = B(2, a: 1);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
  b: int 2
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_implicitSuper_requiredNamed_generic() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A({required this.a});
}

class B<T> extends A {
  final int b;
  const B(this.b, {required super.a});
}

const x = B<int>(2, a: 1);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B<int>
  (super): A
    a: int 1
  b: int 2
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_implicitSuper_requiredPositional() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A(this.a);
}

class B extends A {
  final int b;
  const B(super.a, this.b);
}

const x = B(1, 2);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
  b: int 2
  variable: self::@variable::x
''');
  }

  test_superInitializer_formalParameter_implicitSuper_requiredPositional_generic() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A(this.a);
}

class B<T> extends A {
  final int b;
  const B(super.a, this.b);
}

const x = B<int>(1, 2);
''');

    var value = _topLevelVar('x');
    assertDartObjectText(value, r'''
B<int>
  (super): A
    a: int 1
  b: int 2
  variable: self::@variable::x
''');
  }

  test_superInitializer_paramTypeMismatch_indirect() async {
    await assertErrorsInCode('''
class C {
  final double d;
  const C(this.d);
}
class D extends C {
  const D(d) : super(d);
}
class E extends D {
  const E(e) : super(e);
}
const f = const E('0.0');
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        153,
        14,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 77, 1,
              text:
                  "The evaluated constructor 'C' is called by 'D' and 'D' is defined here."),
          ExpectedContextMessage(testFile.path, 124, 1,
              text:
                  "The evaluated constructor 'D' is called by 'E' and 'E' is defined here."),
          ExpectedContextMessage(testFile.path, 90, 1,
              text:
                  "The exception is 'A value of type 'String' can't be assigned to a parameter of type 'double' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }

  test_superInitializer_typeParameter() async {
    await assertNoErrorsInCode('''
class A<T> {
  final Object f;
  const A(Object t): f = t;
}
class B<T> extends A<T> {
  const B(): super(T);
}
const a = const B<int>();
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
B<int>
  (super): A<int>
    f: Type int
  variable: self::@variable::a
''');
  }

  test_superInitializer_typeParameter_superNonGeneric() async {
    await assertNoErrorsInCode('''
class A {
  final Object f;
  const A(Object t): f = t;
}
class B<T> extends A {
  const B(): super(T);
}
const a = const B<int>();
''');
    final result = _topLevelVar('a');
    assertDartObjectText(result, '''
B<int>
  (super): A
    f: Type int
  variable: self::@variable::a
''');
  }
}

@reflectiveTest
mixin InstanceCreationEvaluatorTestCases on ConstantVisitorTestSupport {
  test_assertInitializer_indirect() async {
    await assertErrorsInCode(r'''
class A {
  const A(int i)
  : assert(i == 1); // (2)
}
class B extends A {
  const B(int i) : super(i);
}
main() {
  print(const B(2)); // (1)
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        124,
        10,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 84, 1,
              text:
                  "The evaluated constructor 'A' is called by 'B' and 'B' is defined here."),
          ExpectedContextMessage(testFile.path, 31, 14,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
    ]);
  }

  test_assertInitializer_intInDoubleContext_false() async {
    await assertErrorsInCode('''
class A {
  const A(double x): assert((x + 3) / 2 == 1.5);
}
const a = const A(1);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        71,
        10,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 31, 26,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
    ]);
  }

  test_assertInitializer_simple_false() async {
    await assertErrorsInCode('''
class A {
  const A(): assert(1 is String);
}
const a = const A();
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        56,
        9,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 23, 19,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
    ]);
  }

  test_assertInitializer_simpleInSuperInitializer_false() async {
    await assertErrorsInCode('''
class A {
  const A(): assert(1 is String);
}
class B extends A {
  const B() : super();
}
const b = const B();
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        101,
        9,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 74, 1,
              text:
                  "The evaluated constructor 'A' is called by 'B' and 'B' is defined here."),
          ExpectedContextMessage(testFile.path, 23, 19,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
    ]);
  }

  test_assertInitializer_usingArgument_false() async {
    await assertErrorsInCode('''
class A {
  const A(int x): assert(x > 0);
}
const a = const A(0);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        55,
        10,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 28, 13,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
    ]);
  }

  test_bool_fromEnvironment() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('a');
const b = bool.fromEnvironment('b', defaultValue: true);
''');
    assertDartObjectText(_topLevelVar('a'), '''
bool false
  variable: self::@variable::a
''');
    assertDartObjectText(
        _evaluateConstant('a', declaredVariables: {'a': 'true'}), '''
bool true
''');

    final bResult = _evaluateConstant(
      'b',
      declaredVariables: {'b': 'bbb'},
      lexicalEnvironment: {
        'defaultValue':
            DartObjectImpl(typeSystem, typeProvider.boolType, BoolState(true)),
      },
    );
    assertDartObjectText(bResult, '''
bool true
''');
  }

  test_bool_hasEnvironment() async {
    await assertNoErrorsInCode('''
const a = bool.hasEnvironment('a');
''');
    assertDartObjectText(_topLevelVar('a'), '''
bool false
  variable: self::@variable::a
''');
    assertDartObjectText(
        _evaluateConstant('a', declaredVariables: {'a': '42'}), '''
bool true
''');
  }

  test_field_deferred_issue48991() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  const A();
}

const aa = A();
''');

    await assertErrorsInCode('''
import 'a.dart' deferred as a;

class B {
  const B(Object a);
}

main() {
  print(const B(a.aa));
}
''', [
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_CONSTANT_FROM_DEFERRED_LIBRARY,
          93,
          2),
    ]);
  }

  test_field_imported_staticConst() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static const A instance = const A();
  const A();
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';
class B {
  final A v;
  const B(this.v);
}
B f1() => const B(A.instance);
''');
  }

  test_int_fromEnvironment() async {
    await assertNoErrorsInCode('''
const a = int.fromEnvironment('a');
const b = int.fromEnvironment('b', defaultValue: 42);
''');

    assertDartObjectText(_topLevelVar('a'), '''
int 0
  variable: self::@variable::a
''');
    assertDartObjectText(
        _evaluateConstant('a', declaredVariables: {'a': '5'}), '''
int 5
''');

    final bResult = _evaluateConstant(
      'b',
      declaredVariables: {'b': 'bbb'},
      lexicalEnvironment: {
        'defaultValue':
            DartObjectImpl(typeSystem, typeProvider.intType, IntState(42)),
      },
    );
    assertDartObjectText(bResult, '''
int 42
''');
  }

  test_issue47351() async {
    await assertErrorsInCode('''
class Foo {
  final int bar;
  const Foo(this.bar);
}

int bar = 2;
const a = const Foo(bar);
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT, 88, 3),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 88,
          3),
    ]);
  }

  test_issue47603() async {
    await assertErrorsInCode('''
class C {
  final void Function() c;
  const C(this.c);
}

void main() {
  const C(() {});
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT, 83, 5),
    ]);
  }

  test_string_fromEnvironment() async {
    await assertNoErrorsInCode('''
const a = String.fromEnvironment('a');
''');
    assertDartObjectText(_topLevelVar('a'), '''
String <empty>
  variable: self::@variable::a
''');
    assertDartObjectText(
        _evaluateConstant('a', declaredVariables: {'a': 'test'}), '''
String test
''');
  }
}

@reflectiveTest
class InstanceCreationEvaluatorWithoutNullSafetyTest
    extends ConstantVisitorTestSupport
    with InstanceCreationEvaluatorTestCases, WithoutNullSafetyMixin {}
