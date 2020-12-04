// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_support.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantVisitorTest);
    defineReflectiveTests(ConstantVisitorWithNullSafetyWithTripleShiftTest);
    defineReflectiveTests(ConstantVisitorWithNullSafetyTest);
  });
}

@reflectiveTest
class ConstantVisitorTest extends ConstantVisitorTestSupport
    with ConstantVisitorTestCases {}

@reflectiveTest
mixin ConstantVisitorTestCases on ConstantVisitorTestSupport {
  test_listLiteral_ifElement_false_withElse() async {
    await resolveTestCode('''
const c = [1, if (1 < 0) 2 else 3, 4];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType2(typeProvider.intType));
    expect(result.toListValue().map((e) => e.toIntValue()), [1, 3, 4]);
  }

  test_listLiteral_ifElement_false_withoutElse() async {
    await resolveTestCode('''
const c = [1, if (1 < 0) 2, 3];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType2(typeProvider.intType));
    expect(result.toListValue().map((e) => e.toIntValue()), [1, 3]);
  }

  test_listLiteral_ifElement_true_withElse() async {
    await resolveTestCode('''
const c = [1, if (1 > 0) 2 else 3, 4];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType2(typeProvider.intType));
    expect(result.toListValue().map((e) => e.toIntValue()), [1, 2, 4]);
  }

  test_listLiteral_ifElement_true_withoutElse() async {
    await resolveTestCode('''
const c = [1, if (1 > 0) 2, 3];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType2(typeProvider.intType));
    expect(result.toListValue().map((e) => e.toIntValue()), [1, 2, 3]);
  }

  test_listLiteral_nested() async {
    await resolveTestCode('''
const c = [1, if (1 > 0) if (2 > 1) 2, 3];
''');
    DartObjectImpl result = _evaluateConstant('c');
    // The expected type ought to be `List<int>`, but type inference isn't yet
    // implemented.
    expect(result.type, typeProvider.listType2(typeProvider.intType));
    expect(result.toListValue().map((e) => e.toIntValue()), [1, 2, 3]);
  }

  test_listLiteral_spreadElement() async {
    await resolveTestCode('''
const c = [1, ...[2, 3], 4];
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.listType2(typeProvider.intType));
    expect(result.toListValue().map((e) => e.toIntValue()), [1, 2, 3, 4]);
  }

  test_mapLiteral_ifElement_false_withElse() async {
    await resolveTestCode('''
const c = {'a' : 1, if (1 < 0) 'b' : 2 else 'c' : 3, 'd' : 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type,
        typeProvider.mapType2(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue();
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
        typeProvider.mapType2(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue();
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
        typeProvider.mapType2(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue();
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
        typeProvider.mapType2(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue();
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
        typeProvider.mapType2(typeProvider.intType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue();
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
        typeProvider.mapType2(typeProvider.stringType, typeProvider.intType));
    Map<DartObject, DartObject> value = result.toMapValue();
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
    expect(result.type, typeProvider.setType2(typeProvider.intType));
    expect(result.toSetValue().map((e) => e.toIntValue()), [1, 3, 4]);
  }

  test_setLiteral_ifElement_false_withoutElse() async {
    await resolveTestCode('''
const c = {1, if (1 < 0) 2, 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType2(typeProvider.intType));
    expect(result.toSetValue().map((e) => e.toIntValue()), [1, 3]);
  }

  test_setLiteral_ifElement_true_withElse() async {
    await resolveTestCode('''
const c = {1, if (1 > 0) 2 else 3, 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType2(typeProvider.intType));
    expect(result.toSetValue().map((e) => e.toIntValue()), [1, 2, 4]);
  }

  test_setLiteral_ifElement_true_withoutElse() async {
    await resolveTestCode('''
const c = {1, if (1 > 0) 2, 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType2(typeProvider.intType));
    expect(result.toSetValue().map((e) => e.toIntValue()), [1, 2, 3]);
  }

  test_setLiteral_nested() async {
    await resolveTestCode('''
const c = {1, if (1 > 0) if (2 > 1) 2, 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType2(typeProvider.intType));
    expect(result.toSetValue().map((e) => e.toIntValue()), [1, 2, 3]);
  }

  test_setLiteral_spreadElement() async {
    await resolveTestCode('''
const c = {1, ...{2, 3}, 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.setType2(typeProvider.intType));
    expect(result.toSetValue().map((e) => e.toIntValue()), [1, 2, 3, 4]);
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
    await resolveTestCode('''
const a = const A();
const b = a as B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant('b',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    expect(result, isNull);
  }

  test_visitAsExpression_instanceOfUnrelatedClass() async {
    await resolveTestCode('''
const a = const A();
const b = a as B;
class A {
  const A();
}
class B {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant('b',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    expect(result, isNull);
  }

  test_visitAsExpression_null() async {
    await resolveTestCode('''
const a = null;
const b = a as A;
class A {}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.nullType);
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
    await resolveTestCode('''
const c = 3 & 5;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
  }

  test_visitBinaryExpression_and_mixed() async {
    await resolveTestCode('''
const c = 3 & false;
''');
    _evaluateConstant('c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT]);
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

  test_visitBinaryExpression_or_mixed() async {
    await resolveTestCode('''
const c = 3 | false;
''');
    _evaluateConstant('c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT]);
  }

  test_visitBinaryExpression_questionQuestion_eager_notNull_notNull() async {
    await resolveTestCode('''
const c = 'a' ?? 'b';
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.stringType);
    expect(result.toStringValue(), 'a');
  }

  test_visitBinaryExpression_questionQuestion_eager_null_notNull() async {
    await resolveTestCode('''
const c = null ?? 'b';
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.stringType);
    expect(result.toStringValue(), 'b');
  }

  test_visitBinaryExpression_questionQuestion_eager_null_null() async {
    await resolveTestCode('''
const c = null ?? null;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.isNull, isTrue);
  }

  test_visitBinaryExpression_questionQuestion_lazy_notNull_invalid() async {
    await resolveTestCode('''
const c = 'a' ?? new C();
class C {}
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.stringType);
    expect(result.toStringValue(), 'a');
  }

  test_visitBinaryExpression_questionQuestion_lazy_notNull_notNull() async {
    await resolveTestCode('''
const c = 'a' ?? 'b';
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.stringType);
    expect(result.toStringValue(), 'a');
  }

  test_visitBinaryExpression_questionQuestion_lazy_null_invalid() async {
    await resolveTestCode('''
const c = null ?? new C();
class C {}
''');
    _evaluateConstant('c', errorCodes: [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitBinaryExpression_questionQuestion_lazy_null_notNull() async {
    await resolveTestCode('''
const c = null ?? 'b';
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.stringType);
    expect(result.toStringValue(), 'b');
  }

  test_visitBinaryExpression_questionQuestion_lazy_null_null() async {
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
    await resolveTestCode('''
const c = 3 ^ false;
''');
    _evaluateConstant('c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT]);
  }

  test_visitConditionalExpression_eager_false_int_int() async {
    await resolveTestCode('''
const c = false ? 1 : 0;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0);
  }

  test_visitConditionalExpression_eager_invalid_int_int() async {
    await resolveTestCode('''
const c = null ? 1 : 0;
''');
    DartObjectImpl result = _evaluateConstant(
      'c',
      errorCodes: [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL],
    );
    expect(result, isNull);
  }

  test_visitConditionalExpression_eager_true_int_int() async {
    await resolveTestCode('''
const c = true ? 1 : 0;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 1);
  }

  test_visitConditionalExpression_eager_true_int_invalid() async {
    await resolveTestCode('''
const c = true ? 1 : x;
''');
    DartObjectImpl result = _evaluateConstant(
      'c',
      errorCodes: [CompileTimeErrorCode.INVALID_CONSTANT],
    );
    if (analysisOptions.experimentStatus.constant_update_2018) {
      expect(result.toIntValue(), 1);
    } else {
      expect(result, isNull);
    }
  }

  test_visitConditionalExpression_eager_true_invalid_int() async {
    await resolveTestCode('''
const c = true ? x : 0;
''');
    DartObjectImpl result = _evaluateConstant(
      'c',
      errorCodes: [CompileTimeErrorCode.INVALID_CONSTANT],
    );
    expect(result, isNull);
  }

  test_visitConditionalExpression_lazy_false_int_int() async {
    await resolveTestCode('''
const c = false ? 1 : 0;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0);
  }

  test_visitConditionalExpression_lazy_false_int_invalid() async {
    await resolveTestCode('''
const c = false ? 1 : new C();
''');
    _evaluateConstant('c', errorCodes: [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitConditionalExpression_lazy_false_invalid_int() async {
    await resolveTestCode('''
const c = false ? new C() : 0;
''');
    DartObjectImpl result = _evaluateConstant('c',
        errorCodes: [CompileTimeErrorCode.INVALID_CONSTANT]);
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0);
  }

  test_visitConditionalExpression_lazy_invalid_int_int() async {
    await resolveTestCode('''
const c = 3 ? 1 : 0;
''');
    _evaluateConstant('c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL]);
  }

  test_visitConditionalExpression_lazy_true_int_int() async {
    await resolveTestCode('''
const c = true ? 1 : 0;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 1);
  }

  test_visitConditionalExpression_lazy_true_int_invalid() async {
    await resolveTestCode('''
const c = true ? 1: new C();
''');
    DartObjectImpl result = _evaluateConstant('c',
        errorCodes: [CompileTimeErrorCode.INVALID_CONSTANT]);
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 1);
  }

  test_visitConditionalExpression_lazy_true_invalid_int() async {
    await resolveTestCode('''
const c = true ? new C() : 0;
class C {}
''');
    _evaluateConstant('c', errorCodes: [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitInstanceCreationExpression_bool_fromEnvironment() async {
    await resolveTestCode('''
const a = bool.fromEnvironment('a');
const b = bool.fromEnvironment('b', defaultValue: true);
''');
    expect(
      _evaluateConstant('a'),
      _boolValue(false),
    );
    expect(
      _evaluateConstant('a', declaredVariables: {'a': 'true'}),
      _boolValue(true),
    );

    expect(
      _evaluateConstant(
        'b',
        declaredVariables: {'b': 'bbb'},
        lexicalEnvironment: {'defaultValue': _boolValue(true)},
      ),
      _boolValue(true),
    );
  }

  test_visitInstanceCreationExpression_bool_hasEnvironment() async {
    await resolveTestCode('''
const a = bool.hasEnvironment('a');
''');
    expect(
      _evaluateConstant('a'),
      _boolValue(false),
    );

    expect(
      _evaluateConstant('a', declaredVariables: {'a': '42'}),
      _boolValue(true),
    );
  }

  test_visitInstanceCreationExpression_int_fromEnvironment() async {
    await resolveTestCode('''
const a = int.fromEnvironment('a');
const b = int.fromEnvironment('b', defaultValue: 42);
''');
    expect(
      _evaluateConstant('a'),
      _intValue(0),
    );
    expect(
      _evaluateConstant('a', declaredVariables: {'a': '5'}),
      _intValue(5),
    );

    expect(
      _evaluateConstant(
        'b',
        declaredVariables: {'b': 'bbb'},
        lexicalEnvironment: {'defaultValue': _intValue(42)},
      ),
      _intValue(42),
    );
  }

  test_visitInstanceCreationExpression_string_fromEnvironment() async {
    await resolveTestCode('''
const a = String.fromEnvironment('a');
''');
    expect(
      _evaluateConstant('a'),
      DartObjectImpl(
        typeSystem,
        typeProvider.stringType,
        StringState(''),
      ),
    );
    expect(
      _evaluateConstant('a', declaredVariables: {'a': 'test'}),
      DartObjectImpl(
        typeSystem,
        typeProvider.stringType,
        StringState('test'),
      ),
    );
  }

  test_visitIntegerLiteral() async {
    await resolveTestCode('''
const double d = 3;
''');
    DartObjectImpl result = _evaluateConstant('d');
    expect(result.type, typeProvider.doubleType);
    expect(result.toDoubleValue(), 3.0);
  }

  test_visitIsExpression_is_instanceOfSameClass() async {
    await resolveTestCode('''
const a = const A();
const b = a is A;
class A {
  const A();
}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_is_instanceOfSubclass() async {
    await resolveTestCode('''
const a = const B();
const b = a is A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_is_instanceOfSuperclass() async {
    await resolveTestCode('''
const a = const A();
const b = a is B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_is_instanceOfUnrelatedClass() async {
    await resolveTestCode('''
const a = const A();
const b = a is B;
class A {
  const A();
}
class B {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_is_null() async {
    await resolveTestCode('''
const a = null;
const b = a is A;
class A {}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_is_null_dynamic() async {
    await resolveTestCode('''
const a = null;
const b = a is dynamic;
class A {}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_is_null_null() async {
    await resolveTestCode('''
const a = null;
const b = a is Null;
class A {}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_is_null_object() async {
    await resolveTestCode('''
const a = null;
const b = a is Object;
class A {}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_isNot_instanceOfSameClass() async {
    await resolveTestCode('''
const a = const A();
const b = a is! A;
class A {
  const A();
}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_isNot_instanceOfSubclass() async {
    await resolveTestCode('''
const a = const B();
const b = a is! A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), false);
  }

  test_visitIsExpression_isNot_instanceOfSuperclass() async {
    await resolveTestCode('''
const a = const A();
const b = a is! B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_isNot_instanceOfUnrelatedClass() async {
    await resolveTestCode('''
const a = const A();
const b = a is! B;
class A {
  const A();
}
class B {
  const B();
}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitIsExpression_isNot_null() async {
    await resolveTestCode('''
const a = null;
const b = a is! A;
class A {}
''');
    DartObjectImpl result = _evaluateConstant('b');
    expect(result.type, typeProvider.boolType);
    expect(result.toBoolValue(), true);
  }

  test_visitPropertyAccess_fromExtension() async {
    await resolveTestCode('''
extension ExtObject on Object {
  int get length => 4;
}

class B {
  final l;
  const B(Object o) : l = o.length;
}

const b = B('');
''');
    _evaluateConstant('b', errorCodes: [
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION
    ]);
  }

  test_visitSimpleIdentifier_className() async {
    await resolveTestCode('''
const a = C;
class C {}
''');
    DartObjectImpl result = _evaluateConstant('a');
    expect(result.type, typeProvider.typeType);
    assertType(result.toTypeValue(), 'C');
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
    await resolveTestCode(r'''
const a = b;
const b = 3;''');
    var environment = <String, DartObjectImpl>{
      'b': DartObjectImpl(typeSystem, typeProvider.intType, IntState(6)),
    };
    var result = _evaluateConstant('a', lexicalEnvironment: environment);
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 6);
  }

  test_visitSimpleIdentifier_notInEnvironment() async {
    await resolveTestCode(r'''
const a = b;
const b = 3;''');
    var environment = <String, DartObjectImpl>{
      'c': DartObjectImpl(typeSystem, typeProvider.intType, IntState(6)),
    };
    var result = _evaluateConstant('a', lexicalEnvironment: environment);
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 3);
  }

  test_visitSimpleIdentifier_withoutEnvironment() async {
    await resolveTestCode(r'''
const a = b;
const b = 3;''');
    var result = _evaluateConstant('a');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 3);
  }

  DartObjectImpl _boolValue(bool value) {
    if (identical(value, false)) {
      return DartObjectImpl(
        typeSystem,
        typeProvider.boolType,
        BoolState.FALSE_STATE,
      );
    } else if (identical(value, true)) {
      return DartObjectImpl(
        typeSystem,
        typeProvider.boolType,
        BoolState.TRUE_STATE,
      );
    }
    fail("Invalid boolean value used in test");
  }

  DartObjectImpl _intValue(int value) {
    return DartObjectImpl(
      typeSystem,
      typeProvider.intType,
      IntState(value),
    );
  }
}

class ConstantVisitorTestSupport extends PubPackageResolutionTest {
  DartObjectImpl _evaluateConstant(
    String name, {
    List<ErrorCode> errorCodes,
    Map<String, String> declaredVariables = const {},
    Map<String, DartObjectImpl> lexicalEnvironment,
  }) {
    var expression = findNode.topVariableDeclarationByName(name).initializer;

    var source = this.result.unit.declaredElement.source;
    var errorListener = GatheringErrorListener();
    var errorReporter = ErrorReporter(
      errorListener,
      source,
      isNonNullableByDefault: false,
    );

    DartObjectImpl result = expression.accept(
      ConstantVisitor(
        ConstantEvaluationEngine(
          DeclaredVariables.fromMap(declaredVariables),
        ),
        this.result.libraryElement,
        errorReporter,
        lexicalEnvironment: lexicalEnvironment,
      ),
    );
    if (errorCodes == null) {
      errorListener.assertNoErrors();
    } else {
      errorListener.assertErrorsWithCodes(errorCodes);
    }
    return result;
  }
}

@reflectiveTest
class ConstantVisitorWithNullSafetyTest extends ConstantVisitorTestSupport
    with WithNullSafetyMixin {
  test_visitAsExpression_potentialConstType() async {
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
}

@reflectiveTest
class ConstantVisitorWithNullSafetyWithTripleShiftTest
    extends ConstantVisitorTestSupport {
  @override
  String get testPackageLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  @override
  void setUp() {
    super.setUp();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: [
          EnableString.triple_shift,
        ],
      ),
    );
  }

  test_visitBinaryExpression_gtGtGt_negative_fewerBits() async {
    await resolveTestCode('''
const c = 0xFFFFFFFF >>> 8;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0xFFFFFF);
  }

  test_visitBinaryExpression_gtGtGt_negative_moreBits() async {
    await resolveTestCode('''
const c = 0xFFFFFFFF >>> 33;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0);
  }

  test_visitBinaryExpression_gtGtGt_negative_moreThan64Bits() async {
    await resolveTestCode('''
const c = 0xFFFFFFFF >>> 65;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0);
  }

  test_visitBinaryExpression_gtGtGt_negative_negativeBits() async {
    await resolveTestCode('''
const c = 0xFFFFFFFF >>> -2;
''');
    _evaluateConstant('c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
  }

  test_visitBinaryExpression_gtGtGt_negative_zeroBits() async {
    await resolveTestCode('''
const c = 0xFFFFFFFF >>> 0;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0xFFFFFFFF);
  }

  test_visitBinaryExpression_gtGtGt_positive_fewerBits() async {
    await resolveTestCode('''
const c = 0xFF >>> 3;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0x1F);
  }

  test_visitBinaryExpression_gtGtGt_positive_moreBits() async {
    await resolveTestCode('''
const c = 0xFF >>> 9;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0);
  }

  test_visitBinaryExpression_gtGtGt_positive_moreThan64Bits() async {
    await resolveTestCode('''
const c = 0xFF >>> 65;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0);
  }

  test_visitBinaryExpression_gtGtGt_positive_negativeBits() async {
    await resolveTestCode('''
const c = 0xFF >>> -2;
''');
    _evaluateConstant('c',
        errorCodes: [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
  }

  test_visitBinaryExpression_gtGtGt_positive_zeroBits() async {
    await resolveTestCode('''
const c = 0xFF >>> 0;
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(result.type, typeProvider.intType);
    expect(result.toIntValue(), 0xFF);
  }
}
