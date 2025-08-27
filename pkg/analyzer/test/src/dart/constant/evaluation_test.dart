// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
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
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantVisitorTest);
    defineReflectiveTests(InstanceCreationEvaluatorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstantVisitorTest extends ConstantVisitorTestSupport
    with ConstantVisitorTestCases {
  test_asExpression_fromExtensionType() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const a = E(42);
const x = a as int;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
int 42
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_asExpression_fromExtensionType_nullable() async {
    await assertNoErrorsInCode(r'''
extension type E(int? it) {}

const x = null as E;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
Null null
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_asExpression_toExtensionType() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const x = 42 as E;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
int 42
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_binaryExpression_extensionType() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const a = E(2);
const b = E(3);
const x = (a as num) * (b as num);
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
int 6
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_declaration_staticError_notAssignable() async {
    await assertErrorsInCode(
      '''
const int x = 'foo';
''',
      [error(CompileTimeErrorCode.invalidAssignment, 14, 5)],
    );
  }

  test_dotShorthand_enum_simple() async {
    await resolveTestCode('''
enum E { v1, v2 }
const E x1 = .v1;
const E x2 = .v2;
''');
    assertDartObjectText(_topLevelVar('x1'), r'''
E
  _name: String v1
  index: int 0
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::x1
''');
    assertDartObjectText(_topLevelVar('x2'), r'''
E
  _name: String v2
  index: int 1
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::x2
''');
  }

  test_dotShorthand_equalEqual_constructor() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}

const v = A() == .new();
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_dotShorthand_equalEqual_constructor_lhsShorthand() async {
    await assertErrorsInCode(
      '''
class A {
  const A();
}

const v = .new() == A();
''',
      [
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 36, 6),
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 37, 3),
      ],
    );
  }

  test_dotShorthand_equalEqual_field() async {
    await assertNoErrorsInCode('''
class A {
  const A();
  static const A field = A();
}

const v = A() == .field;
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_dotShorthand_equalEqual_method_error() async {
    await assertErrorsInCode(
      '''
class A {
  static A method() => A();
}

const v = A() == .method();
''',
      [
        error(CompileTimeErrorCode.constWithNonConst, 51, 3),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 51, 3),
      ],
    );
  }

  test_dotShorthand_method_invalid() async {
    await assertErrorsInCode(
      '''
class A {
  static A method() => A();
}
const A a = .method();
''',
      [error(CompileTimeErrorCode.constEvalMethodInvocation, 52, 9)],
    );
  }

  test_dotShorthand_missingContext_invocation() async {
    await assertErrorsInCode(
      '''
const a = .new();
''',
      [
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 10, 6),
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 11, 3),
      ],
    );
  }

  test_dotShorthand_missingContext_propertyAccess() async {
    await assertErrorsInCode(
      '''
const a = .id;
''',
      [
        error(CompileTimeErrorCode.dotShorthandMissingContext, 10, 3),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 10, 3),
      ],
    );
  }

  test_dotShorthand_propertyAccess() async {
    await assertNoErrorsInCode('''
class A {
  const A();
  static const A field = A();
}

const A a = .field;
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_dotShorthand_propertyAccess_enum() async {
    await assertNoErrorsInCode('''
enum E { a }
const E e = .a;
''');
    var result = _topLevelVar('e');
    assertDartObjectText(result, r'''
E
  _name: String a
  index: int 0
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::e
''');
  }

  test_enum_argument_methodInvocation() async {
    await assertErrorsInCode(
      '''
enum E {
  enumValue(["text"].map((x) => x));

  const E(this.strings);
  final Iterable<String> strings;
}
''',
      [error(CompileTimeErrorCode.constEvalMethodInvocation, 21, 22)],
    );
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
    constructorInvocation
      constructor: <testLibrary>::@enum::E::@constructor::new
      positionalArguments
        0: int 42
    variable: <testLibrary>::@enum::E::@field::v1
  index: int 1
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
    positionalArguments
      0: E
        _name: String v1
        a: int 42
        index: int 0
        constructorInvocation
          constructor: <testLibrary>::@enum::E::@constructor::new
          positionalArguments
            0: int 42
        variable: <testLibrary>::@enum::E::@field::v1
  variable: <testLibrary>::@enum::E::@field::v2
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
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@enum::E::@constructor::named
      substitution: {T: double}
    positionalArguments
      0: double 10.0
  variable: <testLibrary>::@topLevelVariable::x1
''');
    assertDartObjectText(_topLevelVar('x2'), r'''
E<int>
  _name: String v2
  f: int 20
  index: int 1
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@enum::E::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 20
  variable: <testLibrary>::@topLevelVariable::x2
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
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@enum::E::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 10
  variable: <testLibrary>::@topLevelVariable::x1
''');
    assertDartObjectText(_topLevelVar('x2'), r'''
E<int>
  _name: String v2
  f: int 20
  index: int 1
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@enum::E::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 20
  variable: <testLibrary>::@topLevelVariable::x2
''');
    assertDartObjectText(_topLevelVar('x3'), r'''
E<String>
  _name: String v3
  f: String abc
  index: int 2
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@enum::E::@constructor::new
      substitution: {T: String}
    positionalArguments
      0: String abc
  variable: <testLibrary>::@topLevelVariable::x3
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
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::x1
''');
    assertDartObjectText(_topLevelVar('x2'), r'''
E
  _name: String v2
  index: int 1
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::x2
''');
  }

  test_equalEqual_bool_bool_false() async {
    await assertNoErrorsInCode('''
const v = true == false;
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_bool_bool_true() async {
    await assertNoErrorsInCode('''
const v = true == true;
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_double_object() async {
    await assertNoErrorsInCode('''
const v = 1.2 == Object();
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_int_false() async {
    await assertNoErrorsInCode('''
const v = 1 == 2;
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_int_true() async {
    await assertNoErrorsInCode('''
const v = 1 == 1;
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_null() async {
    await assertNoErrorsInCode('''
const int? a = 1;
const v = a == null;
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_object() async {
    await assertNoErrorsInCode('''
const v = 1 == Object();
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_userClass() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}

const v = 1 == A();
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_invalidLeft() async {
    await assertErrorsInCode(
      '''
const v = a == 1;
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 10, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 10, 1),
      ],
    );
  }

  test_equalEqual_invalidRight() async {
    await assertErrorsInCode(
      '''
const v = 1 == a;
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 15, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 15, 1),
      ],
    );
  }

  test_equalEqual_list_matchingTypeArgs_explicit() async {
    await assertNoErrorsInCode('''
const v = <int>[] == <int>[];
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_list_matchingTypeArgs_inferred() async {
    await assertNoErrorsInCode('''
const v = [1, 2] == [1, 2];
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_list_mismatchedTypeArgs() async {
    await assertNoErrorsInCode('''
const v = const <int>[] == const <num>[];
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_map_matchingTypeArgs_explicit() async {
    await assertNoErrorsInCode('''
const v = <String, int>{} == <String, int>{};
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_map_matchingTypeArgs_inferred() async {
    await assertNoErrorsInCode('''
const v = {'x': 1, 'y': 2} == {'x': 1, 'y': 2};
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_map_mismatchedTypeArgs() async {
    await assertNoErrorsInCode('''
const v = const <String, int>{} == const <String, num>{};
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_null_object() async {
    await assertNoErrorsInCode('''
const Object? a = null;
const v = a == Object();
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_set_matchingTypeArgs_explicit() async {
    await assertNoErrorsInCode('''
const v = <int>{} == <int>{};
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_set_matchingTypeArgs_inferred() async {
    await assertNoErrorsInCode('''
const v = {1, 2} == {1, 2};
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_set_mismatchedTypeArgs() async {
    await assertNoErrorsInCode('''
const v = const <int>{} == const <num>{};
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_string_object() async {
    await assertNoErrorsInCode('''
const v = 'foo' == Object();
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_userClass_hasEqEq() async {
    await assertErrorsInCode(
      '''
class A {
  const A();
  bool operator ==(other) => false;
}

const v = A() == 0;
''',
      [error(CompileTimeErrorCode.constEvalPrimitiveEquality, 72, 8)],
    );
    var result = _topLevelVar('v');
    _assertNull(result);
  }

  test_equalEqual_userClass_hasHashCode() async {
    await assertErrorsInCode(
      '''
class A {
  const A();
  int get hashCode => 0;
}

const v = A() == 0;
''',
      [error(CompileTimeErrorCode.constEvalPrimitiveEquality, 61, 8)],
    );
    var result = _topLevelVar('v');
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
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_userClass_hasPrimitiveEquality_language219() async {
    await assertErrorsInCode(
      '''
// @dart = 2.19
class A {
  const A();
}

const v = A() == 0;
''',
      [error(CompileTimeErrorCode.constEvalTypeBoolNumString, 52, 8)],
    );
    var result = _topLevelVar('v');
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
    var result = _topLevelVar('v');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_userClass_noPrimitiveEquality() async {
    await assertErrorsInCode(
      '''
class A {
  const A();
  bool operator ==(other) => false;
}

const v = A() == A();
''',
      [error(CompileTimeErrorCode.constEvalPrimitiveEquality, 72, 10)],
    );
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

  test_identical_extensionType_nullable() async {
    await assertNoErrorsInCode('''
extension type E(int it) {}

class A {
  final E? f;
  const A() : f = null;
}

const v = A();
''');
    var result = _topLevelVar('v');
    assertDartObjectText(result, r'''
A
  f: Null null
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_identical_extensionType_types_recursive() async {
    await assertNoErrorsInCode('''
const c = identical(ExList<ExInt>, List<int>);

extension type const ExInt(int value) implements int {}
extension type const ExList<T>(List<T> value) implements List<T> {}
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_type_functionType_different() async {
    await assertNoErrorsInCode('''
const c = identical(typeof<void Function()>, typeof<void Function()?>);
typedef typeof<T> = T;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_type_functionType_same() async {
    await assertNoErrorsInCode('''
const c = identical(typeof<void Function()>, typeof<void Function()>);
typedef typeof<T> = T;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_differentTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
const c = identical(C<int>, C<String>);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_differentTypes() async {
    await assertNoErrorsInCode('''
class C<T> {}
class D<T> {}
const c = identical(C<int>, D<int>);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_sameType() async {
    await assertNoErrorsInCode('''
class C<T> {}
const c = identical(C<int>, C<int>);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_simpleTypeAlias() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef TC = C<int>;
const c = identical(C<int>, TC);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<int>, TC<int>);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_differentTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<int>, TC<String>);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_implicitTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<dynamic>, TC);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_implicitTypeArgs_bound() async {
    await assertNoErrorsInCode('''
class C<T extends num> {}
typedef TC<T extends num> = C<T>;
const c = identical(C<num>, TC);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_simple_differentTypes() async {
    await assertNoErrorsInCode('''
const c = identical(int, String);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_simple_sameType() async {
    await assertNoErrorsInCode('''
const c = identical(int, int);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
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

    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
A<int>
  t: int 0
  constructorInvocation
    constructor: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 0
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_instanceCreationExpression_custom_generic_extensionType_explicit() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

class C<T> {
  const C();
}

const x = C<E>();
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
C<int>
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::C::@constructor::new
      substitution: {T: E}
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_instanceCreationExpression_custom_generic_extensionType_inferred() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

class C<T> {
  final T f;
  const C(this.f);
}

const x = C(E(42));
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
C<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::C::@constructor::new
      substitution: {T: E}
    positionalArguments
      0: int 42
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_instanceCreationExpression_extensionType() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const x = E(42);
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
int 42
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_isExpression_fromExtensionType_false() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const a = E(42);
const x = a is String;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_isExpression_fromExtensionType_true() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const a = E(42);
const x = a is int;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_isExpression_toExtensionType_false() async {
    await assertNoErrorsInCode(r'''
extension type const E(String it) {}

const x = 42 is E;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
bool false
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_isExpression_toExtensionType_true() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const x = 42 is E;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
bool true
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_listLiteral_extensionType_explicitType() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const x = <E>[];
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
List
  elementType: int
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_listLiteral_extensionType_inferredType() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const x = [E(0), E(1)];
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
List
  elementType: int
  elements
    int 0
    int 1
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_mapLiteral_extensionType() async {
    await assertNoErrorsInCode(r'''
extension type const E(int it) {}

const x = {E(0): E(1)};
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
Map
  entries
    entry
      key: int 0
      value: int 1
  variable: <testLibrary>::@topLevelVariable::x
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

  test_propertyAccess_nullAware_dynamic_length_notNull() async {
    await assertNoErrorsInCode(r'''
const dynamic d = 'foo';
const int? c = d?.length;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_dynamic_length_null() async {
    await assertNoErrorsInCode(r'''
const dynamic d = null;
const int? c = d?.length;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_list_length_null() async {
    await assertNoErrorsInCode(r'''
const List? l = null;
const int? c = l?.length;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_string_length_notNull() async {
    await assertNoErrorsInCode(r'''
const String? s = 'foo';
const int? c = s?.length;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_string_length_null() async {
    await assertNoErrorsInCode(r'''
const String? s = null;
const int? c = s?.length;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_recordTypeAnnotation() async {
    await assertNoErrorsInCode(r'''
const a = ('',) is (int,);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_typeParameter() async {
    await assertErrorsInCode(
      '''
class A<X> {
  const A();
  void m() {
    const x = X;
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 49, 1),
        error(CompileTimeErrorCode.constTypeParameter, 53, 1),
      ],
    );
    var result = _localVar('x');
    _assertNull(result);
  }

  test_visitBinaryExpression_extensionMethod() async {
    await assertErrorsInCode(
      '''
extension on Object {
  int operator +(Object other) => 0;
}

const Object v1 = 0;
const v2 = v1 + v1;
''',
      [error(CompileTimeErrorCode.constEvalExtensionMethod, 94, 7)],
    );
    var result = _topLevelVar('v2');
    _assertNull(result);
  }

  test_visitBinaryExpression_extensionType() async {
    await assertErrorsInCode(
      '''
extension type const A(int it) {
  int operator +(Object other) => 0;
}

const v1 = A(1);
const v2 = v1 + 2;
''',
      [error(CompileTimeErrorCode.constEvalExtensionTypeMethod, 101, 6)],
    );
    var result = _topLevelVar('v2');
    _assertNull(result);
  }

  test_visitBinaryExpression_extensionType_implementsInt() async {
    await assertNoErrorsInCode('''
extension type const A(int it) implements int {}

const v1 = A(1);
const v2 = v1 + 2;
''');
    var result = _topLevelVar('v2');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::v2
''');
  }

  test_visitBinaryExpression_gt_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 > 3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gte_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 >= 3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_fewerBits() async {
    await assertNoErrorsInCode('''
const c = 0xFFFFFFFF >>> 8;
''');
    var result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xffffff
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_moreBits() async {
    await assertNoErrorsInCode('''
const c = 0xFFFFFFFF >>> 33;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_moreThan64Bits() async {
    await assertNoErrorsInCode('''
const c = 0xFFFFFFFF >>> 65;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_negativeBits() async {
    await assertErrorsInCode(
      '''
const c = 0xFFFFFFFF >>> -2;
''',
      [error(CompileTimeErrorCode.constEvalThrowsException, 10, 17)],
    );
    var result = _topLevelVar('c');
    _assertNull(result);
  }

  test_visitBinaryExpression_gtGtGt_negative_zeroBits() async {
    await assertNoErrorsInCode('''
const c = 0xFFFFFFFF >>> 0;
''');
    var result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xffffffff
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_fewerBits() async {
    await assertNoErrorsInCode('''
const c = 0xFF >>> 3;
''');
    var result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0x1f
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_moreBits() async {
    await assertNoErrorsInCode('''
const c = 0xFF >>> 9;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_moreThan64Bits() async {
    await assertNoErrorsInCode('''
const c = 0xFF >>> 65;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_negativeBits() async {
    await assertErrorsInCode(
      '''
const c = 0xFF >>> -2;
''',
      [error(CompileTimeErrorCode.constEvalThrowsException, 10, 11)],
    );
    var result = _topLevelVar('c');
    _assertNull(result);
  }

  test_visitBinaryExpression_gtGtGt_positive_zeroBits() async {
    await assertNoErrorsInCode('''
const c = 0xFF >>> 0;
''');
    var result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xff
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_lt_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 < 3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_lte_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 <= 3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_questionQuestion_invalid_notNull() async {
    await assertErrorsInCode(
      '''
final x = 0;
const c = x ?? 1;
''',
      [
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 23, 1),
        error(WarningCode.deadCode, 25, 4),
        error(StaticWarningCode.deadNullAwareExpression, 28, 1),
      ],
    );
  }

  test_visitBinaryExpression_questionQuestion_notNull_invalid() async {
    await assertErrorsInCode(
      '''
final x = 1;
const c = 0 ?? x;
''',
      [
        error(WarningCode.deadCode, 25, 4),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 28, 1),
        error(StaticWarningCode.deadNullAwareExpression, 28, 1),
      ],
    );
  }

  test_visitConditionalExpression_eager_invalid_int_int() async {
    await assertErrorsInCode(
      '''
const c = null ? 1 : 0;
''',
      [
        error(CompileTimeErrorCode.nonBoolCondition, 10, 4),
        error(CompileTimeErrorCode.constEvalTypeBool, 10, 4),
      ],
    );
  }

  test_visitConditionalExpression_instantiatedFunctionType_variable() async {
    await assertNoErrorsInCode('''
void f<T>(T p, {T? q}) {}

const void Function<T>(T p) g = f;

const bool b = false;
const void Function(int p) h = b ? g : g;
''');
    var result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int, {int? q})
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitConditionalExpression_unknownCondition() async {
    await assertNoErrorsInCode('''
const bool kIsWeb = identical(0, 0.0);
const x = kIsWeb ? 0 : 1;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
<unknown> int
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitConditionalExpression_unknownCondition_errorInConstructor() async {
    await assertErrorsInCode(
      r'''
const bool kIsWeb = identical(0, 0.0);

var a = 2;
const x = A(kIsWeb ? 0 : a);

class A {
  const A(int _);
}
''',
      [
        error(CompileTimeErrorCode.invalidConstant, 76, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 76, 1),
      ],
    );
    var result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitConditionalExpression_unknownCondition_undefinedIdentifier() async {
    await assertErrorsInCode(
      r'''
const bool kIsWeb = identical(0, 0.0);
const x = kIsWeb ? a : b;
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 58, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 58, 1),
        error(CompileTimeErrorCode.undefinedIdentifier, 62, 1),
      ],
    );
    var result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitConstructorDeclaration_cycle() async {
    await assertErrorsInCode(
      '''
class A {
  final A a;
  const A() : a = const A();
}

''',
      [error(CompileTimeErrorCode.recursiveConstantConstructor, 31, 1)],
    );
  }

  test_visitConstructorDeclaration_cycle_subclass_issue46735() async {
    await assertErrorsInCode(
      '''
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
''',
      [
        error(CompileTimeErrorCode.recursiveConstantConstructor, 110, 12),
        error(CompileTimeErrorCode.recursiveConstantConstructor, 344, 13),
      ],
    );
  }

  test_visitConstructorDeclaration_field_asExpression_nonConst() async {
    await assertErrorsInCode(
      r'''
dynamic y = 2;
class A {
  const A();
  final x = y as num;
}
''',
      [
        error(
          CompileTimeErrorCode.constConstructorWithFieldInitializedByNonConst,
          27,
          5,
        ),
      ],
    );
  }

  test_visitConstructorReference_generic_named() async {
    await assertNoErrorsInCode('''
class C<T> {
  C.foo();
}
const c = C<int>.foo;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: <testLibrary>::@class::C::@constructor::foo
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConstructorReference_generic_unnamed() async {
    await assertNoErrorsInCode('''
class C<T> {
  C();
}
const c = C<int>.new;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: <testLibrary>::@class::C::@constructor::new
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConstructorReference_identical_aliasIsNotGeneric() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC = C<int>;
const a = identical(MyC.new, C<int>.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentBound() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC.new, C.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentCount() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef MyC<T> = C<T, int>;
const a = identical(MyC.new, C.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentCount2() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef MyC<T> = C;
const a = identical(MyC.new, C.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentOrder() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef MyC<T, U> = C<U, T>;
const a = identical(MyC.new, C.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_instantiated() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, C<int>.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_mixedInstantiations() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, (MyC.new)<int>);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_instantiated() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mixedInstantiations() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC<int>.new, (MyC.new)<int>);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mutualSubtypes_dynamic() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T extends Object?> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mutualSubtypes_futureOr() async {
    await assertNoErrorsInCode('''
import 'dart:async';
class C<T extends FutureOr<num>> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_uninstantiated() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC.new, MyC.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_differentClasses() async {
    await assertNoErrorsInCode('''
class C<T> {}
class D<T> {}
const a = identical(C<int>.new, D<int>.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_differentTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
const a = identical(C<int>.new, C<String>.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_sameElement() async {
    await assertNoErrorsInCode('''
class C<T> {}
const a = identical(C<int>.new, C<int>.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_inferredTypeArgs_sameElement() async {
    await assertNoErrorsInCode('''
class C<T> {}
const C<int> Function() c1 = C.new;
const c2 = C<int>.new;
const a = identical(c1, c2);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_notInstantiated_differentClasses() async {
    await assertNoErrorsInCode('''
class C<T> {}
class D<T> {}
const a = identical(C.new, D.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_notInstantiated_sameElement() async {
    await assertNoErrorsInCode('''
class C<T> {}
const a = identical(C.new, C.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_onlyOneHasTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {}
const a = identical(C<int>.new, C.new);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_nonGeneric_named() async {
    await assertNoErrorsInCode('''
class C<T> {
  const C.foo();
}
const c = C<int>.foo;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: <testLibrary>::@class::C::@constructor::foo
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConstructorReference_nonGeneric_unnamed() async {
    await assertNoErrorsInCode('''
class C<T> {
  const C();
}
const c = C<int>.new;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: <testLibrary>::@class::C::@constructor::new
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_defaultConstructorValue() async {
    await assertErrorsInCode(
      r'''
void f<T>(T t) => t;

class C<T> {
  final void Function(T) p;
  const C({this.p = f});
}
''',
      [
        error(
          CompileTimeErrorCode.constWithTypeParametersFunctionTearoff,
          83,
          1,
        ),
      ],
    );
  }

  test_visitFunctionReference_explicitTypeArgs_complexExpression() async {
    await assertNoErrorsInCode(r'''
const b = true;
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = (b ? foo : bar)<int>;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::foo
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_complexExpression_differentTypes() async {
    await assertNoErrorsInCode(r'''
const b = true;
void foo<T>(String a, T b) {}
void bar<T>(T a, String b) {}
const g = (b ? foo : bar)<int>;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function(String, int)
  element: <testLibrary>::@function::foo
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_constantType() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {}
const g = f<int>;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_notMatchingBound() async {
    await assertErrorsInCode(
      r'''
void f<T extends num>(T a) {}
const g = f<String>;
''',
      [error(CompileTimeErrorCode.typeArgumentNotMatchingBounds, 42, 6)],
    );
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function(String)
  element: <testLibrary>::@function::f
  typeArguments
    String
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_notType() async {
    await assertErrorsInCode(
      r'''
void foo<T>(T a) {}
const g = foo<true>;
''',
      [
        error(CompileTimeErrorCode.constEvalTypeNum, 30, 8),
        error(CompileTimeErrorCode.undefinedOperator, 33, 1),
        error(ParserErrorCode.equalityCannotBeEqualityOperand, 38, 1),
        error(ParserErrorCode.missingIdentifier, 39, 1),
      ],
    );
    var result = _topLevelVar('g');
    _assertNull(result);
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_tooFew() async {
    await assertErrorsInCode(
      r'''
void foo<T, U>(T a, U b) {}
const g = foo<int>;
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsFunction, 41, 5)],
    );
    var result = _topLevelVar('g');
    _assertNull(result);
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_tooMany() async {
    await assertErrorsInCode(
      r'''
void foo<T>(T a) {}
const g = foo<int, String>;
''',
      [error(CompileTimeErrorCode.wrongNumberOfTypeArgumentsFunction, 33, 13)],
    );
    var result = _topLevelVar('g');
    _assertNull(result);
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_typeParameter() async {
    await assertErrorsInCode(
      r'''
void f<T>(T a) {}

class C<U> {
  void m() {
    const g = f<U>;
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 55, 1),
        error(
          CompileTimeErrorCode.constWithTypeParametersFunctionTearoff,
          61,
          1,
        ),
      ],
    );
  }

  test_visitFunctionReference_explicitTypeArgs_identical_differentElements() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = identical(foo<int>, bar<int>);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_differentTypeArgs() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<String>);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_onlyOneHasTypeArgs() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_sameElement() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<int>);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_sameElement_runtimeTypeEquality() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
void foo<T>(T a) {}
const g = identical(foo<Object>, foo<FutureOr<Object>>);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_differentElements() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = identical(foo<int>, bar<int>);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_differentTypeArgs() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<String>);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_onlyOneHasTypeArgs() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_sameElement() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<int>);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_sameElement_runtimeTypeEquality() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
void foo<T>(T a) {}
const g = identical(foo<Object>, foo<FutureOr<Object>>);
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_implicitTypeArgs_differentTypes() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(String) g = foo;
const c = identical(f, g);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_identical_implicitTypeArgs_sameTypes() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(int) g = foo;
const c = identical(f, g);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_identical_uninstantiated_sameElement() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const c = identical(foo, foo);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_implicitTypeArgs_identical_differentTypes() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(String) g = foo;
const c = identical(f, g);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_implicitTypeArgs_identical_sameTypes() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(int) g = foo;
const c = identical(f, g);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_uninstantiated_complexExpression() async {
    await assertNoErrorsInCode(r'''
const b = true;
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = b ? foo : bar;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function<T>(T)
  element: <testLibrary>::@function::foo
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_uninstantiated_functionName() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {}
const g = f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, r'''
void Function<T>(T)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_uninstantiated_identical_sameElement() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T a) {}
const c = identical(foo, foo);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_wildcard_local() async {
    await assertErrorsInCode(
      r'''
test() {
  void _() {}
  const c = _;
  print(c);
}
''',
      [
        error(WarningCode.deadCode, 11, 11),
        error(CompileTimeErrorCode.undefinedIdentifier, 35, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 35, 1),
      ],
    );
  }

  test_visitFunctionReference_wildcard_top() async {
    await assertNoErrorsInCode(r'''
void _() {}
const c = _;
''');
  }

  test_visitInstanceCreationExpression_invalidNamedArg() async {
    await assertErrorsInCode(
      '''
class A {
  const A({ required int x });
}
const a = A(x: false);
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 58, 5),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 55, 8),
      ],
    );
  }

  test_visitInstanceCreationExpression_invalidNamedArg_superParam() async {
    await assertErrorsInCode(
      '''
class A {
  const A({ required int x });
}
class B extends A {
  const B({ required super.x });
}
const a = B(x: false);
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 113, 5),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 110, 8),
      ],
    );
  }

  test_visitInstanceCreationExpression_invalidPositionalArg() async {
    await assertErrorsInCode(
      '''
class A {
  const A(int x);
}
const a = A(false);
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 42, 5),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 42, 5),
      ],
    );
  }

  test_visitInstanceCreationExpression_invalidPositionalArg_superParam() async {
    await assertErrorsInCode(
      '''
class A {
  const A(int x);
}
class B extends A {
  const B(super.x);
}
const a = B(false);
''',
      [
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 84, 5),
        error(CompileTimeErrorCode.constConstructorParamTypeMismatch, 84, 5),
      ],
    );
  }

  test_visitInstanceCreationExpression_missingNamedArg() async {
    await assertErrorsInCode(
      '''
class A {
  const A({required int x });
}
const a = A();
''',
      [error(CompileTimeErrorCode.missingRequiredArgument, 52, 1)],
    );
  }

  test_visitInstanceCreationExpression_missingNamedArg_superParam() async {
    await assertErrorsInCode(
      '''
class A {
  const A({required int x });
}
class B extends A {
  const B({required super.x });
}
const a = B();
''',
      [
        error(CompileTimeErrorCode.missingRequiredArgument, 106, 1),
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          106,
          3,
        ),
        error(
          CompileTimeErrorCode.invalidConstant,
          106,
          3,
          contextMessages: [message(testFile, 88, 1)],
        ),
      ],
    );
  }

  test_visitInstanceCreationExpression_missingPositionalArg() async {
    await assertErrorsInCode(
      '''
class A {
  const A(int x);
}
const a = A();
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          42,
          1,
        ),
      ],
    );
  }

  test_visitInstanceCreationExpression_missingPositionalArg_superParam() async {
    await assertErrorsInCode(
      '''
class A {
  const A(int x);
}
class B extends A {
  const B(super.x);
}
const a = B();
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          84,
          1,
        ),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 82, 3),
        error(
          CompileTimeErrorCode.invalidConstant,
          82,
          3,
          contextMessages: [message(testFile, 66, 1)],
        ),
      ],
    );
  }

  test_visitInstanceCreationExpression_noArgs() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}
const a = A();
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitInstanceCreationExpression_noConstConstructor() async {
    await assertErrorsInCode(
      '''
class A {}
const a = A();
''',
      [
        error(CompileTimeErrorCode.constWithNonConst, 21, 3),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 21, 3),
      ],
    );
  }

  test_visitInstanceCreationExpression_simpleArgs() async {
    await assertNoErrorsInCode('''
class A {
  const A(int x);
}
const a = A(1);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitInstanceCreationExpression_unknown() async {
    await assertErrorsInCode(
      '''
class C<T> {
  const C.named();
}

const x = C<int>.();
''',
      [
        // TODO(kallentu): This should not be reported.
        // https://github.com/dart-lang/sdk/issues/50441
        error(
          CompileTimeErrorCode.classInstantiationAccessToUnknownMember,
          45,
          8,
        ),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 45, 8),
        error(ParserErrorCode.missingIdentifier, 52, 1),
      ],
    );
  }

  test_visitInterpolationExpression_list() async {
    await assertErrorsInCode(
      r'''
const x = '${const [2]}';
''',
      [error(CompileTimeErrorCode.constEvalTypeBoolNumString, 11, 12)],
    );
  }

  test_visitIsExpression_is_functionType_correctTypes() async {
    await assertErrorsInCode(
      '''
void foo(int a) {}
const c = foo is void Function(int);
''',
      [error(WarningCode.unnecessaryTypeCheckTrue, 29, 25)],
    );
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitIsExpression_is_instanceOfSameClass() async {
    await assertErrorsInCode(
      '''
const a = const A();
const b = a is A;
class A {
  const A();
}
''',
      [error(WarningCode.unnecessaryTypeCheckTrue, 31, 6)],
    );
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_instanceOfSubclass() async {
    await assertErrorsInCode(
      '''
const a = const B();
const b = a is A;
class A {
  const A();
}
class B extends A {
  const B();
}
''',
      [error(WarningCode.unnecessaryTypeCheckTrue, 31, 6)],
    );
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is A;
class A {}
''');
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null_nullable() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is A?;
class A {}
''');
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null_object() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is Object;
''');
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSameClass() async {
    await assertErrorsInCode(
      '''
const a = const A();
const b = a is! A;
class A {
  const A();
}
''',
      [error(WarningCode.unnecessaryTypeCheckFalse, 31, 7)],
    );
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSubclass() async {
    await assertErrorsInCode(
      '''
const a = const B();
const b = a is! A;
class A {
  const A();
}
class B extends A {
  const B();
}
''',
      [error(WarningCode.unnecessaryTypeCheckFalse, 31, 7)],
    );
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_isNot_null() async {
    await assertNoErrorsInCode('''
const a = null;
const b = a is! A;
class A {}
''');
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitListLiteral_forElement() async {
    await assertErrorsInCode(
      r'''
const x = [for (int i = 0; i < 3; i++) i];
''',
      [
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          10,
          31,
        ),
        error(CompileTimeErrorCode.constEvalForElement, 11, 29),
      ],
    );
    var result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitListLiteral_ifElement_nonBoolCondition() async {
    await assertErrorsInCode(
      r'''
const dynamic c = 2;
const x = [1, if (c) 2 else 3, 4];
''',
      [error(CompileTimeErrorCode.nonBoolCondition, 39, 1)],
    );
    var result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitListLiteral_ifElement_nonBoolCondition_static() async {
    await assertErrorsInCode(
      r'''
const x = [1, if (1) 2 else 3, 4];
''',
      [error(CompileTimeErrorCode.nonBoolCondition, 18, 1)],
    );
    var result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitListLiteral_listElement_explicitType() async {
    await assertNoErrorsInCode(r'''
const x = <String>['a', 'b', 'c'];
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
List
  elementType: String
  elements
    String a
    String b
    String c
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitListLiteral_listElement_explicitType_functionType() async {
    await assertNoErrorsInCode(r'''
const x = <void Function()>[];
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
List
  elementType: void Function()
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitListLiteral_listElement_field_final() async {
    await assertErrorsInCode(
      r'''
class A {
  final String bar = '';
  const A();
  List<String> foo() => const [bar];
}
''',
      [error(CompileTimeErrorCode.nonConstantListElement, 79, 3)],
    );
  }

  test_visitListLiteral_listElement_field_static() async {
    await assertNoErrorsInCode(r'''
class A {
  static const String bar = '';
  const A();
  List<String> foo() => const [bar];
}
''');
  }

  test_visitListLiteral_listElement_simple() async {
    await assertNoErrorsInCode(r'''
const x = ['a', 'b', 'c'];
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
List
  elementType: String
  elements
    String a
    String b
    String c
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitListLiteral_listElement_variableElements() async {
    await assertNoErrorsInCode(r'''
const a = 0;
const b = 2;
const c = [a, 1, b];
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
List
  elementType: int
  elements
    int 0
      variable: <testLibrary>::@topLevelVariable::a
    int 1
    int 2
      variable: <testLibrary>::@topLevelVariable::b
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitListLiteral_spreadElement() async {
    await assertErrorsInCode(
      r'''
const dynamic a = 5;
const x = <int>[...a];
''',
      [error(CompileTimeErrorCode.constSpreadExpectedListOrSet, 40, 1)],
    );
    var result = _topLevelVar('x');
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
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
List
  elementType: String
  elements
    String anotherString
  variable: <testLibrary>::@topLevelVariable::x
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
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
List
  elementType: String
  elements
    String anotherString
    String string
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitMethodInvocation_notIdentical() async {
    await assertErrorsInCode(
      r'''
int f() {
  return 3;
}
const a = f();
''',
      [error(CompileTimeErrorCode.constEvalMethodInvocation, 34, 3)],
    );
  }

  test_visitNamedType_typeLiteral_typeParameter_nested() async {
    await assertErrorsInCode(
      r'''
void f<T>(Object? x) {
  if (x case const (T)) {}
}
''',
      [error(CompileTimeErrorCode.constTypeParameter, 43, 1)],
    );
  }

  test_visitNamedType_typeLiteral_typeParameter_nested2() async {
    await assertErrorsInCode(
      r'''
void f<T>(Object? x) {
  if (x case const (List<T>)) {}
}
''',
      [error(CompileTimeErrorCode.constTypeParameter, 43, 7)],
    );
  }

  test_visitPrefixedIdentifier_function() async {
    await assertNoErrorsInCode('''
import '' as self;
void f(int a) {}
const g = self.f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPrefixedIdentifier_genericFunction_instantiated() async {
    await assertNoErrorsInCode('''
import '' as self;
void f<T>(T a) {}
const void Function(int) g = self.f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
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
    var result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitPrefixedIdentifier_genericFunction_instantiatedPrefixed() async {
    await assertNoErrorsInCode('''
import '' as self;
void f<T>(T a) {}
const g = f;
const void Function(int) h = self.g;
''');
    var result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitPrefixedIdentifier_genericVariable_uninstantiated() async {
    await assertNoErrorsInCode('''
import '' as self;
void f<T>(T a) {}
const g = f;
const h = self.g;
''');
    var result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function<T>(T)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitPrefixedIdentifier_length_invalidTarget() async {
    await assertErrorsInCode(
      '''
void main() {
  const RequiresNonEmptyList([1]);
}

class RequiresNonEmptyList {
  const RequiresNonEmptyList(List<int> numbers) : assert(numbers.length > 0);
}
''',
      [
        error(
          CompileTimeErrorCode.constEvalPropertyAccess,
          16,
          31,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              138,
              14,
              text:
                  "The error is in the assert initializer of 'RequiresNonEmptyList', and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_visitPrefixExpression_bitNot() async {
    await assertNoErrorsInCode('''
const c = ~42;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
int -43
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitPrefixExpression_extensionMethod() async {
    await assertErrorsInCode(
      '''
extension on Object {
  int operator -() => 0;
}

const Object v1 = 1;
const v2 = -v1;
''',
      [error(CompileTimeErrorCode.constEvalExtensionMethod, 82, 3)],
    );
    var result = _topLevelVar('v2');
    _assertNull(result);
  }

  test_visitPrefixExpression_extensionType() async {
    await assertErrorsInCode(
      '''
extension type const A(int it) {
  int operator -() => 0;
}

const v1 = A(1);
const v2 = -v1;
''',
      [error(CompileTimeErrorCode.constEvalExtensionTypeMethod, 89, 3)],
    );
    var result = _topLevelVar('v2');
    _assertNull(result);
  }

  test_visitPrefixExpression_extensionType_implementsInt() async {
    await assertNoErrorsInCode('''
extension type const A(int it) implements int {}

const v1 = A(1);
const v2 = -v1;
''');
    var result = _topLevelVar('v2');
    assertDartObjectText(result, r'''
int -1
  variable: <testLibrary>::@topLevelVariable::v2
''');
  }

  test_visitPrefixExpression_logicalNot() async {
    await assertNoErrorsInCode('''
const c = !true;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitPrefixExpression_negated_bool() async {
    await assertErrorsInCode(
      '''
const c = -true;
''',
      [
        error(CompileTimeErrorCode.undefinedOperator, 10, 1),
        error(CompileTimeErrorCode.constEvalTypeNum, 10, 5),
      ],
    );
  }

  test_visitPrefixExpression_negated_double() async {
    await assertNoErrorsInCode('''
const c = -42.3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double -42.3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitPrefixExpression_negated_int() async {
    await assertNoErrorsInCode('''
const c = -42;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int -42
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitPropertyAccess_length_complex() async {
    await assertNoErrorsInCode('''
const x = ('qwe' + 'rty').length;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
int 6
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitPropertyAccess_length_simple() async {
    await assertNoErrorsInCode('''
const x = 'Dvorak'.length;
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
int 6
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitPropertyAccess_staticMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
class C {
  static void f(int a) {}
}
const g = self.C.f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@class::C::@method::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPropertyAccess_staticMethod_generic_instantiated() async {
    await assertNoErrorsInCode('''
import '' as self;
class C {
  static void f<T>(T a) {}
}
const void Function(int) g = self.C.f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@class::C::@method::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPropertyAccess_staticMethod_ofExtension() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  static int f(String s) => 7;
}
const g = self.E.f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
int Function(String)
  element: <testLibrary>::@extension::E::@method::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPropertyAccess_staticMethod_ofExtensionType() async {
    await assertNoErrorsInCode('''
import '' as self;
extension type ET(int it) {
  static int f(String s) => 7;
}
const g = self.ET.f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
int Function(String)
  element: <testLibrary>::@extensionType::ET::@method::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitRecordLiteral_inConstructorInitializer() async {
    await assertNoErrorsInCode(r'''
class A {
  final bool b;
  const A(r) : b = r is (int, ) ? true : true;
}
''');
  }

  test_visitRecordLiteral_mixedTypes() async {
    await assertNoErrorsInCode(r'''
const x = (0, f1: 10, f2: 2.3);
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
Record(int, {int f1, double f2})
  positionalFields
    $1: int 0
  namedFields
    f1: int 10
    f2: double 2.3
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitRecordLiteral_named() async {
    await assertNoErrorsInCode(r'''
const x = (f1: 10, f2: -3);
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
Record({int f1, int f2})
  namedFields
    f1: int 10
    f2: int -3
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitRecordLiteral_namedField_final() async {
    await assertErrorsInCode(
      r'''
final bar = '';
({String bar, }) foo() => const (bar: bar, );
''',
      [error(CompileTimeErrorCode.nonConstantRecordField, 54, 3)],
    );
  }

  test_visitRecordLiteral_objectField_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final (T, T) record;
  const A(T a) : record = (a, a);
}

const a = A(42);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
A<int>
  record: Record(int, int)
    positionalFields
      $1: int 42
      $2: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitRecordLiteral_positional() async {
    await assertNoErrorsInCode(r'''
const x = (20, 0, 7);
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
Record(int, int, int)
  positionalFields
    $1: int 20
    $2: int 0
    $3: int 7
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitRecordLiteral_positionalField_final() async {
    await assertErrorsInCode(
      r'''
final bar = '';
(String, ) foo() => const (bar, );
''',
      [error(CompileTimeErrorCode.nonConstantRecordField, 43, 3)],
    );
  }

  test_visitRecordLiteral_withoutEnvironment() async {
    await assertNoErrorsInCode(r'''
const a = (1, 'b', c: false);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
Record(int, String, {bool c})
  positionalFields
    $1: int 1
    $2: String b
  namedFields
    c: bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitSetOrMapLiteral_ambiguous() async {
    await assertErrorsInCode(
      r'''
const l = [];
const ambiguous = {...l, 1: 2};
''',
      [error(CompileTimeErrorCode.ambiguousSetOrMapLiteralBoth, 32, 12)],
    );
  }

  test_visitSetOrMapLiteral_ambiguous_either() async {
    await assertErrorsInCode(
      r'''
const int? i = 1;
const res  = {...?i};
''',
      [error(CompileTimeErrorCode.ambiguousSetOrMapLiteralEither, 31, 7)],
    );
  }

  test_visitSetOrMapLiteral_ambiguous_expression() async {
    await assertErrorsInCode(
      r'''
const m = {1: 1};
const res = {...m, 2};
''',
      [error(CompileTimeErrorCode.ambiguousSetOrMapLiteralBoth, 30, 9)],
    );
  }

  test_visitSetOrMapLiteral_ambiguous_inList() async {
    await assertErrorsInCode(
      r'''
const l = [];
const ambiguous = {...l, 1: 2};
const anotherList = [...ambiguous];
''',
      [error(CompileTimeErrorCode.ambiguousSetOrMapLiteralBoth, 32, 12)],
    );
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
    var result = _topLevelVar('x');
    assertDartObjectText(result, r'''
Map
  entries
    entry
      key: A
        x: int 0
        constructorInvocation
          constructor: <testLibrary>::@class::A::@constructor::new
          positionalArguments
            0: int 0
      value: int 1
    entry
      key: void Function()
        element: <testLibrary>::@function::fn
      value: int 2
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitSetOrMapLiteral_map_forElement() async {
    await assertErrorsInCode(
      r'''
const x = {1: null, for (final i in const []) i: null};
''',
      [
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          10,
          44,
        ),
        error(CompileTimeErrorCode.constEvalForElement, 20, 33),
      ],
    );
    var result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_map_forElement_nested() async {
    await assertErrorsInCode(
      r'''
const x = {1: null, if (true) for (final i in const []) i: null};
''',
      [
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          10,
          54,
        ),
        error(CompileTimeErrorCode.constEvalForElement, 30, 33),
      ],
    );
    var result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_map_ifElement_nonBoolCondition() async {
    await assertErrorsInCode(
      r'''
const dynamic nonBool = null;
const c = const {if (nonBool) 'a' : 1};
''',
      [error(CompileTimeErrorCode.nonBoolCondition, 51, 7)],
    );
    var result = _topLevelVar('c');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_map_mapElement() async {
    await assertNoErrorsInCode(r'''
const x = {'a' : 'm', 'b' : 'n', 'c' : 'o'};
''');
    var result = _topLevelVar('x');
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
  variable: <testLibrary>::@topLevelVariable::x
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
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
Map
  entries
    entry
      key: String string
      value: int 1
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitSetOrMapLiteral_map_spread_notMap() async {
    await assertErrorsInCode(
      '''
const x = ['string'];
const Map<String, int> alwaysInclude = {
  'anotherString': 0,
  ...x,
};
''',
      [
        error(CompileTimeErrorCode.constSpreadExpectedMap, 90, 1),
        error(CompileTimeErrorCode.notMapSpread, 90, 1),
      ],
    );
  }

  test_visitSetOrMapLiteral_map_spread_null() async {
    await assertNoErrorsInCode('''
const a = null;
const Map<String, int> x = {
  'anotherString': 0,
  ...?a,
};
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
Map
  entries
    entry
      key: String anotherString
      value: int 0
  variable: <testLibrary>::@topLevelVariable::x
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
Set
  elements
    C
      x: double 0.0
      constructorInvocation
        constructor: <testLibrary>::@class::C::@constructor::new
        positionalArguments
          0: double 0.0
      variable: <testLibrary>::@topLevelVariable::cp0
    C
      x: double -0.0
      constructorInvocation
        constructor: <testLibrary>::@class::C::@constructor::new
        positionalArguments
          0: double -0.0
      variable: <testLibrary>::@topLevelVariable::cm0
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitSetOrMapLiteral_set_forElement() async {
    await assertErrorsInCode(
      r'''
const Set set = {};
const x = {for (final i in set) i};
''',
      [
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          30,
          24,
        ),
        error(CompileTimeErrorCode.constEvalForElement, 31, 22),
      ],
    );
    var result = _topLevelVar('x');
    _assertNull(result);
  }

  test_visitSetOrMapLiteral_set_ifElement_nonBoolCondition() async {
    await assertErrorsInCode(
      r'''
const dynamic nonBool = 'a';
const c = const {if (nonBool) 3};
''',
      [error(CompileTimeErrorCode.nonBoolCondition, 50, 7)],
    );
    var result = _topLevelVar('c');
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
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
Set
  elements
    String anotherString
    String string
  variable: <testLibrary>::@topLevelVariable::x
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
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
Set
  elements
    String anotherString
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitSimpleIdentifier_className() async {
    await assertNoErrorsInCode('''
const a = C;
class C {}
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
Type C
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitSimpleIdentifier_function() async {
    await assertNoErrorsInCode('''
void f(int a) {}
const g = f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitSimpleIdentifier_genericFunction_instantiated() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
const void Function(int) g = f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitSimpleIdentifier_genericFunction_nonGeneric() async {
    await assertNoErrorsInCode('''
void f(int a) {}
const void Function(int) g = f;
''');
    var result = _topLevelVar('g');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitSimpleIdentifier_genericVariable_instantiated() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
const g = f;
const void Function(int) h = g;
''');
    var result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitSimpleIdentifier_genericVariable_uninstantiated() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
const g = f;
const h = g;
''');
    var result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function<T>(T)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::h
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
    var result = _field('h');
    assertDartObjectText(result, '''
void Function(int, {int? b})
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@class::C::@field::h
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
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
C
  h: void Function(int, {int? b})
    element: <testLibrary>::@function::f
    typeArguments
      int
  constructorInvocation
    constructor: <testLibrary>::@class::C::@constructor::new
    positionalArguments
      0: void Function<T>(T, {T? b})
        element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitSimpleIdentifier_instantiatedFunctionType_variable() async {
    await assertNoErrorsInCode('''
void f<T>(T a, {T? b}) {}

const void Function<T>(T a) g = f;

const void Function(int a) h = g;
''');
    var result = _topLevelVar('h');
    assertDartObjectText(result, '''
void Function(int, {int? b})
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitUnaryExpression_extensionType() async {
    await assertErrorsInCode(
      '''
extension type const A(int it) {
  int operator -() => 0;
}

const v1 = A(1);
const v2 = -v1;
''',
      [error(CompileTimeErrorCode.constEvalExtensionTypeMethod, 89, 3)],
    );
    var result = _topLevelVar('v2');
    _assertNull(result);
  }

  void _assertHasPrimitiveEqualityFalse(String name) {
    var value = _evaluateConstant(name);
    var featureSet = result.libraryElement.featureSet;
    var has = value.hasPrimitiveEquality(featureSet);
    expect(has, isFalse);
  }

  void _assertHasPrimitiveEqualityTrue(String name) {
    var value = _evaluateConstant(name);
    var featureSet = result.libraryElement.featureSet;
    var has = value.hasPrimitiveEquality(featureSet);
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
    expect(
      result.type,
      typeProvider.mapType(typeProvider.stringType, typeProvider.intType),
    );
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(
      value.keys.map((e) => e.toStringValue()),
      unorderedEquals(['a', 'c', 'd']),
    );
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 3, 4]));
  }

  test_mapLiteral_ifElement_false_withoutElse() async {
    await resolveTestCode('''
const c = {'a' : 1, if (1 < 0) 'b' : 2, 'c' : 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(
      result.type,
      typeProvider.mapType(typeProvider.stringType, typeProvider.intType),
    );
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(
      value.keys.map((e) => e.toStringValue()),
      unorderedEquals(['a', 'c']),
    );
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 3]));
  }

  test_mapLiteral_ifElement_true_withElse() async {
    await resolveTestCode('''
const c = {'a' : 1, if (1 > 0) 'b' : 2 else 'c' : 3, 'd' : 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(
      result.type,
      typeProvider.mapType(typeProvider.stringType, typeProvider.intType),
    );
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(
      value.keys.map((e) => e.toStringValue()),
      unorderedEquals(['a', 'b', 'd']),
    );
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 2, 4]));
  }

  test_mapLiteral_ifElement_true_withoutElse() async {
    await resolveTestCode('''
const c = {'a' : 1, if (1 > 0) 'b' : 2, 'c' : 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(
      result.type,
      typeProvider.mapType(typeProvider.stringType, typeProvider.intType),
    );
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(
      value.keys.map((e) => e.toStringValue()),
      unorderedEquals(['a', 'b', 'c']),
    );
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 2, 3]));
  }

  @failingTest
  test_mapLiteral_nested() async {
    // Fails because we're not yet parsing nested elements.
    await resolveTestCode('''
const c = {'a' : 1, if (1 > 0) if (2 > 1) {'b' : 2}, 'c' : 3};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(
      result.type,
      typeProvider.mapType(typeProvider.intType, typeProvider.intType),
    );
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(
      value.keys.map((e) => e.toStringValue()),
      unorderedEquals(['a', 'b', 'c']),
    );
    expect(value.values.map((e) => e.toIntValue()), unorderedEquals([1, 2, 3]));
  }

  test_mapLiteral_spreadElement() async {
    await resolveTestCode('''
const c = {'a' : 1, ...{'b' : 2, 'c' : 3}, 'd' : 4};
''');
    DartObjectImpl result = _evaluateConstant('c');
    expect(
      result.type,
      typeProvider.mapType(typeProvider.stringType, typeProvider.intType),
    );
    Map<DartObject, DartObject> value = result.toMapValue()!;
    expect(
      value.keys.map((e) => e.toStringValue()),
      unorderedEquals(['a', 'b', 'c', 'd']),
    );
    expect(
      value.values.map((e) => e.toIntValue()),
      unorderedEquals([1, 2, 3, 4]),
    );
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
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
String abcdef
  variable: <testLibrary>::@topLevelVariable::c
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
    await assertErrorsInCode(
      '''
const a = const A();
const b = a as B;
class A {
  const A();
}
class B extends A {
  const B();
}
''',
      [error(CompileTimeErrorCode.constEvalThrowsException, 31, 6)],
    );
    var result = _topLevelVar('b');
    _assertNull(result);
  }

  test_visitAsExpression_instanceOfUnrelatedClass() async {
    await assertErrorsInCode(
      '''
const a = const A();
const b = a as B;
class A {
  const A();
}
class B {
  const B();
}
''',
      [error(CompileTimeErrorCode.constEvalThrowsException, 31, 6)],
    );
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
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 5.5
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_add_instance_String() async {
    await assertErrorsInCode(
      '''
class C {
  const C();
  String operator +(String other) => other;
}

const c = C() + 1;
''',
      [
        error(CompileTimeErrorCode.constEvalTypeNumString, 80, 7),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 86, 1),
      ],
    );
  }

  test_visitBinaryExpression_add_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 + 3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 5
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_add_string_string() async {
    await assertNoErrorsInCode('''
const c = 'a' + 'b';
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
String ab
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_bool_bool() async {
    await assertNoErrorsInCode('''
const c = true && false;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_bool_false_invalid() async {
    await assertErrorsInCode(
      '''
final a = false;
const c = false && a;
''',
      [
        error(WarningCode.deadCode, 33, 4),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 36, 1),
      ],
    );
  }

  test_visitBinaryExpression_and_bool_invalid_false() async {
    await assertErrorsInCode(
      '''
final a = false;
const c = a && false;
''',
      [error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 27, 1)],
    );
  }

  test_visitBinaryExpression_and_bool_invalid_true() async {
    await assertErrorsInCode(
      '''
final a = false;
const c = a && true;
''',
      [error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 27, 1)],
    );
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
    await assertErrorsInCode(
      '''
final a = false;
const c = true && a;
''',
      [error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 27, 9)],
    );
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
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 10
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_mixed() async {
    await assertErrorsInCode(
      '''
const c = 3 & false;
''',
      [
        error(CompileTimeErrorCode.constEvalTypeBoolInt, 10, 9),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 14, 5),
      ],
    );
  }

  test_visitBinaryExpression_divide_double_double() async {
    await assertNoErrorsInCode('''
const c = 3.2 / 2.3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 1.3913043478260871
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_divide_double_double_byZero() async {
    await assertNoErrorsInCode('''
const c = 3.2 / 0.0;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double Infinity
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_divide_int_int() async {
    await assertNoErrorsInCode('''
const c = 3 / 2;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 1.5
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_divide_int_int_byZero() async {
    await assertNoErrorsInCode('''
const c = 3 / 0;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double Infinity
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_eqeq_double_double_nan_left() async {
    await assertErrorsInCode(
      '''
const c = double.nan == 2.3;
''',
      [error(WarningCode.unnecessaryNanComparisonFalse, 10, 13)],
    );
    // This test case produces a warning, but the value of the constant should
    // be `false`.
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_eqeq_double_double_nan_right() async {
    await assertErrorsInCode(
      '''
const c = 2.3 == double.nan;
''',
      [error(WarningCode.unnecessaryNanComparisonFalse, 14, 13)],
    );
    // This test case produces a warning, but the value of the constant should
    // be `false`.
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_minus_double_double() async {
    await assertNoErrorsInCode('''
const c = 3.2 - 2.3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 0.9000000000000004
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_minus_int_int() async {
    await assertNoErrorsInCode('''
const c = 3 - 2;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 1
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_notEqual_bool_bool() async {
    await assertNoErrorsInCode('''
const c = true != false;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_notEqual_int_int() async {
    await assertNoErrorsInCode('''
const c = 2 != 3;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_notEqual_invalidLeft() async {
    await assertErrorsInCode(
      '''
const c = a != 3;
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 10, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 10, 1),
      ],
    );
  }

  test_visitBinaryExpression_notEqual_invalidRight() async {
    await assertErrorsInCode(
      '''
const c = 2 != a;
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 15, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 15, 1),
      ],
    );
  }

  test_visitBinaryExpression_notEqual_string_string() async {
    await assertNoErrorsInCode('''
const c = 'a' != 'b';
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_bool_false_invalid() async {
    await assertErrorsInCode(
      '''
final a = false;
const c = false || a;
''',
      [
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          27,
          10,
        ),
      ],
    );
  }

  test_visitBinaryExpression_or_bool_invalid_false() async {
    await assertErrorsInCode(
      '''
final a = false;
const c = a || false;
''',
      [error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 27, 1)],
    );
  }

  test_visitBinaryExpression_or_bool_invalid_true() async {
    await assertErrorsInCode(
      '''
final a = false;
const c = a || true;
''',
      [error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 27, 1)],
    );
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
    await assertErrorsInCode(
      '''
final a = false;
const c = true || a;
''',
      [
        error(WarningCode.deadCode, 32, 4),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 35, 1),
      ],
    );
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
    await assertErrorsInCode(
      '''
const c = true || false;
''',
      [error(WarningCode.deadCode, 15, 8)],
    );
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_mixed() async {
    await assertErrorsInCode(
      '''
const c = 3 | false;
''',
      [
        error(CompileTimeErrorCode.constEvalTypeBoolInt, 10, 9),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 14, 5),
      ],
    );
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
    await assertErrorsInCode(
      '''
const c = null ?? new C();
class C {}
''',
      [error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 18, 7)],
    );
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
    await assertErrorsInCode(
      '''
const c = 3 ^ false;
''',
      [
        error(CompileTimeErrorCode.constEvalTypeBoolInt, 10, 9),
        error(CompileTimeErrorCode.argumentTypeNotAssignable, 14, 5),
      ],
    );
  }

  test_visitBoolLiteral_false() async {
    await assertNoErrorsInCode('''
const c = false;
''');
    var result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBoolLiteral_true() async {
    await assertNoErrorsInCode('''
const c = true;
''');
    var result = _topLevelVar('c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_eager_false_int_int() async {
    await assertErrorsInCode(
      '''
const c = false ? 1 : 0;
''',
      [error(WarningCode.deadCode, 18, 1)],
    );
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_eager_true_int_int() async {
    await assertErrorsInCode(
      '''
const c = true ? 1 : 0;
''',
      [error(WarningCode.deadCode, 21, 1)],
    );
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 1
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_eager_true_int_invalid() async {
    await assertErrorsInCode(
      '''
const c = true ? 1 : x;
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 21, 1),
        error(WarningCode.deadCode, 21, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 21, 1),
      ],
    );
  }

  test_visitConditionalExpression_eager_true_invalid_int() async {
    await assertErrorsInCode(
      '''
const c = true ? x : 0;
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 17, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 17, 1),
        error(WarningCode.deadCode, 21, 1),
      ],
    );
  }

  test_visitConditionalExpression_lazy_false_int_int() async {
    await assertErrorsInCode(
      '''
const c = false ? 1 : 0;
''',
      [error(WarningCode.deadCode, 18, 1)],
    );
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_lazy_false_int_invalid() async {
    await assertErrorsInCode(
      '''
const c = false ? 1 : new C();
''',
      [
        error(WarningCode.deadCode, 18, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 22, 7),
        error(CompileTimeErrorCode.newWithNonType, 26, 1),
      ],
    );
  }

  test_visitConditionalExpression_lazy_false_invalid_int() async {
    await assertErrorsInCode(
      '''
const c = false ? new C() : 0;
''',
      [
        error(WarningCode.deadCode, 18, 7),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 18, 7),
        error(CompileTimeErrorCode.newWithNonType, 22, 1),
      ],
    );
  }

  test_visitConditionalExpression_lazy_invalid_int_int() async {
    await assertErrorsInCode(
      '''
const c = 3 ? 1 : 0;
''',
      [
        error(CompileTimeErrorCode.nonBoolCondition, 10, 1),
        error(CompileTimeErrorCode.constEvalTypeBool, 10, 1),
      ],
    );
  }

  test_visitConditionalExpression_lazy_true_int_int() async {
    await assertErrorsInCode(
      '''
const c = true ? 1 : 0;
''',
      [error(WarningCode.deadCode, 21, 1)],
    );
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 1
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_lazy_true_int_invalid() async {
    await assertErrorsInCode(
      '''
const c = true ? 1: new C();
''',
      [
        error(WarningCode.deadCode, 20, 7),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 20, 7),
        error(CompileTimeErrorCode.newWithNonType, 24, 1),
      ],
    );
  }

  test_visitConditionalExpression_lazy_true_invalid_int() async {
    await assertErrorsInCode(
      '''
const c = true ? new C() : 0;
class C {}
''',
      [
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 17, 7),
        error(WarningCode.deadCode, 27, 1),
      ],
    );
  }

  test_visitConditionalExpression_lazy_unknown_int_invalid() async {
    await assertErrorsInCode(
      '''
const c = identical(0, 0.0) ? 1 : new Object();
''',
      [
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          34,
          12,
        ),
      ],
    );
  }

  test_visitConditionalExpression_lazy_unknown_invalid_int() async {
    await assertErrorsInCode(
      '''
const c = identical(0, 0.0) ? 1 : new Object();
''',
      [
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          34,
          12,
        ),
      ],
    );
  }

  test_visitDoubleLiteral() async {
    await assertNoErrorsInCode('''
const c = 3.45;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
double 3.45
  variable: <testLibrary>::@topLevelVariable::c
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
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitIsExpression_is_functionType_badTypes() async {
    await assertNoErrorsInCode('''
void foo(int a) {}
const c = foo is void Function(String);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitIsExpression_is_functionType_nonFunction() async {
    await assertNoErrorsInCode('''
const c = false is void Function();
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
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
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
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
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null_dynamic() async {
    await assertErrorsInCode(
      '''
const a = null;
const b = a is dynamic;
class A {}
''',
      [error(WarningCode.unnecessaryTypeCheckTrue, 26, 12)],
    );
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null_null() async {
    await assertErrorsInCode(
      '''
const a = null;
const b = a is Null;
class A {}
''',
      [error(WarningCode.typeCheckIsNull, 26, 9)],
    );
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
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
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
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
    var result = _topLevelVar('b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitNullLiteral_null() async {
    await assertNoErrorsInCode('''
const c = null;
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitParenthesizedExpression_string() async {
    await assertNoErrorsInCode('''
const a = ('a');
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
String a
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitPropertyAccess_constant_extensionType_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type const E(int it) {
  static const v = 42;
}
''');

    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

const x = prefix.E.v;
''');

    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
int 42
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitPropertyAccess_length_extension() async {
    await assertErrorsInCode(
      '''
extension ExtObject on Object {
  int get length => 4;
}

class B {
  final l;
  const B(Object o) : l = o.length;
}

const b = B('');
''',
      [
        error(
          CompileTimeErrorCode.constEvalExtensionMethod,
          128,
          5,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              105,
              8,
              text:
                  "The error is in the field initializer of 'B', and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_visitPropertyAccess_length_extensionType() async {
    await assertErrorsInCode(
      '''
extension type const A(String it) {
  int get length => 0;
}

const v1 = A('');
const v2 = v1.length;
''',
      [error(CompileTimeErrorCode.constEvalExtensionTypeMethod, 91, 9)],
    );
    var result = _topLevelVar('v2');
    _assertNull(result);
  }

  test_visitPropertyAccess_length_extensionType_implementsString() async {
    await assertNoErrorsInCode('''
extension type const A(String it) implements String {}

const v1 = A('abc');
const v2 = v1.length;
''');
    var result = _topLevelVar('v2');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::v2
''');
  }

  test_visitPropertyAccess_length_unresolvedType() async {
    await assertErrorsInCode(
      '''
class B {
  final l;
  const B(String o) : l = o.length;
}

const y = B(x);
''',
      [
        error(
          CompileTimeErrorCode.constEvalTypeString,
          70,
          4,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              47,
              8,
              text:
                  "The error is in the field initializer of 'B', and occurs here.",
            ),
          ],
        ),
        error(CompileTimeErrorCode.undefinedIdentifier, 72, 1),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 72, 1),
      ],
    );
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
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitSimpleIdentifier_variable() async {
    await assertNoErrorsInCode('''
const a = 42;
const b = a;
''');
    var result = _topLevelVar('b');
    assertDartObjectText(result, '''
int 42
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitSimpleIdentifier_wildcard_local() async {
    await assertErrorsInCode(
      r'''
test() {
  const _ = true;
  const c = _;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 35, 1, messageContains: ["'c'"]),
        error(CompileTimeErrorCode.undefinedIdentifier, 39, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 39, 1),
      ],
    );
  }

  test_visitSimpleIdentifier_wildcard_top() async {
    await assertNoErrorsInCode(r'''
const _ = true;
const c = _;
''');
  }

  test_visitSimpleIdentifier_withoutEnvironment() async {
    await assertNoErrorsInCode(r'''
const a = b;
const b = 3;''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitSimpleStringLiteral_valid() async {
    await assertNoErrorsInCode(r'''
const c = 'abc';
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
String abc
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitStringInterpolation_invalid() async {
    await assertErrorsInCode(
      r'''
const c = 'a${f()}c';
''',
      [
        error(CompileTimeErrorCode.undefinedFunction, 14, 1),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 14, 3),
      ],
    );
  }

  test_visitStringInterpolation_valid() async {
    await assertNoErrorsInCode(r'''
const c = 'a${3}c';
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, r'''
String a3c
  variable: <testLibrary>::@topLevelVariable::c
''');
  }
}

class ConstantVisitorTestSupport extends PubPackageResolutionTest {
  void _assertNull(DartObjectImpl? result) {
    expect(result, isNull);
  }

  DartObjectImpl _evaluateConstant(
    String name, {
    List<DiagnosticCode>? diagnosticCodes,
    Map<String, String> declaredVariables = const {},
    Map<String, DartObjectImpl>? lexicalEnvironment,
  }) {
    var expression = findNode.topVariableDeclarationByName(name).initializer!;
    return _evaluateExpression(
      expression,
      diagnosticCodes: diagnosticCodes,
      declaredVariables: declaredVariables,
      lexicalEnvironment: lexicalEnvironment,
    )!;
  }

  DartObjectImpl? _evaluateExpression(
    Expression expression, {
    List<DiagnosticCode>? diagnosticCodes,
    Map<String, String> declaredVariables = const {},
    Map<String, DartObjectImpl>? lexicalEnvironment,
  }) {
    var unit = this.result.unit;
    var source = unit.declaredFragment!.source;
    var errorListener = GatheringDiagnosticListener();
    var diagnosticReporter = DiagnosticReporter(errorListener, source);
    var constantVisitor = ConstantVisitor(
      ConstantEvaluationEngine(
        declaredVariables: DeclaredVariables.fromMap(declaredVariables),
        configuration: ConstantEvaluationConfiguration(),
      ),
      this.result.libraryElement,
      diagnosticReporter,
      lexicalEnvironment: lexicalEnvironment,
    );

    var expressionConstant = constantVisitor.evaluateAndReportInvalidConstant(
      expression,
    );
    var result = expressionConstant is DartObjectImpl
        ? expressionConstant
        : null;
    if (diagnosticCodes == null) {
      errorListener.assertNoErrors();
    } else {
      errorListener.assertErrorsWithCodes(diagnosticCodes);
    }
    return result;
  }

  DartObjectImpl? _evaluationResult(VariableElementImpl element) {
    var evaluationResult = element.evaluationResult;
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
    var element = findElement2.field(variableName);
    return _evaluationResult(element as VariableElementImpl);
  }

  DartObjectImpl? _localVar(String variableName) {
    var element = findElement2.localVar(variableName);
    return _evaluationResult(element as VariableElementImpl);
  }

  DartObjectImpl? _topLevelVar(String variableName) {
    var element = findElement2.topVar(variableName);
    return _evaluationResult(element as VariableElementImpl);
  }
}

@reflectiveTest
class InstanceCreationEvaluatorTest extends ConstantVisitorTestSupport {
  test_assertInitializer_assertIsNot_false() async {
    await assertErrorsInCode(
      '''
class A {
  const A() : assert(0 is! int);
}

const a = const A(null);
''',
      [
        error(WarningCode.unnecessaryTypeCheckFalse, 31, 9),
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          56,
          13,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              24,
              17,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
        error(CompileTimeErrorCode.extraPositionalArguments, 64, 4),
      ],
    );
  }

  test_assertInitializer_assertIsNot_null_nullableType() async {
    await assertErrorsInCode(
      '''
class A<T> {
  const A() : assert(null is! T);
}

const a = const A<int?>();
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          60,
          15,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              27,
              18,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_assertInitializer_assertIsNot_true() async {
    await assertErrorsInCode(
      '''
class A {
  const A() : assert(0 is! String);
}

const a = const A(null);
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 67, 4)],
    );
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: Null null
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_assertInitializer_enum_false() async {
    await assertErrorsInCode(
      '''
enum E { a, b }
class A {
  const A(E e) : assert(e != E.a);
}
const c = const A(E.a);
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          73,
          12,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              43,
              16,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_assertInitializer_enum_true() async {
    await assertNoErrorsInCode('''
enum E { a, b }
class A {
  const A(E e) : assert(e != E.a);
}
const c = const A(E.b);
''');
    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: E
        _name: String b
        index: int 1
        constructorInvocation
          constructor: <testLibrary>::@enum::E::@constructor::new
        variable: <testLibrary>::@enum::E::@field::b
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_assertInitializer_indirect() async {
    await assertErrorsInCode(
      r'''
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
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          124,
          10,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              84,
              1,
              text:
                  "The evaluated constructor 'A' is called by 'B' and 'B' is defined here.",
            ),
            ExpectedContextMessage(
              testFile,
              31,
              14,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_assertInitializer_intInDoubleContext_assertIsDouble_true() async {
    await assertErrorsInCode(
      '''
class A {
  const A(double x): assert(x is double);
}
const a = const A(0);
''',
      [error(WarningCode.unnecessaryTypeCheckTrue, 38, 11)],
    );
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: double 0.0
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_assertInitializer_intInDoubleContext_false() async {
    await assertErrorsInCode(
      '''
class A {
  const A(double x): assert((x + 3) / 2 == 1.5);
}
const a = const A(1);
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          71,
          10,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              31,
              26,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
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
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: double 0.0
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_assertInitializer_simple_false() async {
    await assertErrorsInCode(
      '''
class A {
  const A(): assert(1 is String);
}
const a = const A();
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          56,
          9,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              23,
              19,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_assertInitializer_simple_true() async {
    await assertErrorsInCode(
      '''
class A {
  const A(): assert(1 is int);
}
const a = const A();
''',
      [error(WarningCode.unnecessaryTypeCheckTrue, 30, 8)],
    );
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_assertInitializer_simpleInSuperInitializer_false() async {
    await assertErrorsInCode(
      '''
class A {
  const A(): assert(1 is String);
}
class B extends A {
  const B() : super();
}
const b = const B();
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          101,
          9,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              74,
              1,
              text:
                  "The evaluated constructor 'A' is called by 'B' and 'B' is defined here.",
            ),
            ExpectedContextMessage(
              testFile,
              23,
              19,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_assertInitializer_simpleInSuperInitializer_true() async {
    await assertErrorsInCode(
      '''
class A {
  const A(): assert(1 is int);
}
class B extends A {
  const B() : super();
}
const b = const B();
''',
      [error(WarningCode.unnecessaryTypeCheckTrue, 30, 8)],
    );
    var result = _topLevelVar('b');
    assertDartObjectText(result, '''
B
  (super): A
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_assertInitializer_usingArgument_false() async {
    await assertErrorsInCode(
      '''
class A {
  const A(int x): assert(x > 0);
}
const a = const A(0);
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          55,
          10,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              28,
              13,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_assertInitializer_usingArgument_false_withMessage() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int x): assert(x > 0, '$x must be greater than 0');
}
const a = const A(0);
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          84,
          10,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              28,
              42,
              text:
                  "The exception is 'An assertion failed with message '0 must be greater than 0'.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_assertInitializer_usingArgument_false_withMessage_cannotCompute() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int x): assert(x > 0, '${throw ''}');
}
const a = const A(0);
''',
      [
        error(CompileTimeErrorCode.invalidConstant, 45, 8),
        error(CompileTimeErrorCode.constConstructorThrowsException, 45, 8),
        error(WarningCode.deadCode, 54, 3),
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          70,
          10,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              28,
              28,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_assertInitializer_usingArgument_true() async {
    await assertNoErrorsInCode('''
class A {
  const A(int x): assert(x > 0);
}
const a = const A(1);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_bool_fromEnvironment() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('a');
const b = bool.fromEnvironment('b', defaultValue: true);
''');
    assertDartObjectText(_topLevelVar('a'), '''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
    assertDartObjectText(
      _evaluateConstant('a', declaredVariables: {'a': 'true'}),
      '''
bool true
''',
    );

    var bResult = _evaluateConstant(
      'b',
      declaredVariables: {'b': 'bbb'},
      lexicalEnvironment: {
        'defaultValue': DartObjectImpl(
          typeSystem,
          typeProvider.boolType,
          BoolState(true),
        ),
      },
    );
    assertDartObjectText(bResult, '''
bool true
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/50045
  test_bool_fromEnvironment_dartLibraryJsInterop() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_interop');
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/50045
  test_bool_fromEnvironment_dartLibraryJsUtil() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_list_eqeq_known() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = [3, if (a) ...[1] else ...[1, 2], 4];
const left = [3, 1, 2, 4] == b;
const right = b == [3, 1, 2, 4];
''');
    var leftResult = _topLevelVar('left');
    assertDartObjectText(leftResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar('right');
    assertDartObjectText(rightResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_list_eqeq_unknown() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = [3, if (a) ...[1] else ...[1, 2], 4];
const left = [3, if (a) ...[1] else ...[1, 2], 4] == b;
const right = b == [3, if (a) ...[1] else ...[1, 2], 4];
''');
    var leftResult = _topLevelVar('left');
    assertDartObjectText(leftResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar('right');
    assertDartObjectText(rightResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_map() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const x = {3:'3', if (a) 1:'1' else 2:'2', 4:'4'};
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
<unknown> Map<int, String>
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_map_eqeq_known() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = {3:'3', if (a) 1:'1' else 2:'2', 4:'4'};
const left = {3:'3', 2:'2', 4:'4'} == b;
const right = b == {3:'3', 2:'2', 4:'4'};
''');
    var leftResult = _topLevelVar('left');
    assertDartObjectText(leftResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar('right');
    assertDartObjectText(rightResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_map_eqeq_unknown() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = {3:'3', if (a) 1:'1' else 2:'2', 4:'4'};
const left = {3:'3', if (a) 1:'1' else 2:'2', 4:'4'} == b;
const right = b == {3:'3', if (a) 1:'1' else 2:'2', 4:'4'};
''');
    var leftResult = _topLevelVar('left');
    assertDartObjectText(leftResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar('right');
    assertDartObjectText(rightResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_nonConstant() async {
    await assertErrorsInCode(
      '''
const a = bool.fromEnvironment('dart.library.js_util');
var b = 7;
var x = const A([if (a) b]);

class A {
  const A(List<int> p);
}
''',
      [error(CompileTimeErrorCode.nonConstantListElement, 91, 1)],
    );
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_set() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const x = {3, if (a) ...[1] else ...[1, 2], 4};
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
<unknown> Set<int>
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_set_eqeq_known() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = {3, if (a) ...[1] else ...[1, 2], 4};
const left = {3, 1, 4} == b;
const right = b == {3, 1, 4};
''');
    var leftResult = _topLevelVar('left');
    assertDartObjectText(leftResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar('right');
    assertDartObjectText(rightResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_set_eqeq_unknown() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = {3, if (a) ...[1] else ...[1, 2], 4};
const left = {3, if (a) ...[1] else ...[1, 2], 4} == b;
const right = b == {3, if (a) ...[1] else ...[1, 2], 4};
''');
    var leftResult = _topLevelVar('left');
    assertDartObjectText(leftResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar('right');
    assertDartObjectText(rightResult, '''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElementElse_nonConstant() async {
    await assertErrorsInCode(
      '''
const a = bool.fromEnvironment('dart.library.js_util');
var b = 7;
var x = const A([if (a) 3 else b]);

class A {
  const A(List<int> p);
}
''',
      [error(CompileTimeErrorCode.nonConstantListElement, 98, 1)],
    );
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifStatement_list() async {
    await assertNoErrorsInCode('''
const a = bool.fromEnvironment('dart.library.js_util');
const x = [3, if (a) ...[1] else ...[1, 2], 4];
''');
    var result = _topLevelVar('x');
    assertDartObjectText(result, '''
<unknown> List<int>
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_recordField_nonConstant() async {
    await assertErrorsInCode(
      '''
const a = bool.fromEnvironment('dart.library.js_util');
var b = 7;
var x = const A((b, ));

class A {
  const A((int, ) p);
}
''',
      [error(CompileTimeErrorCode.invalidConstant, 84, 1)],
    );
  }

  test_bool_hasEnvironment() async {
    await assertNoErrorsInCode('''
const a = bool.hasEnvironment('a');
''');
    assertDartObjectText(_topLevelVar('a'), '''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
    assertDartObjectText(
      _evaluateConstant('a', declaredVariables: {'a': '42'}),
      '''
bool true
''',
    );
  }

  test_dotShorthand_assertInitializer_assertIsNot_false() async {
    await assertErrorsInCode(
      '''
class A {
  const A() : assert(0 is! int);
}

const A a = .new();
''',
      [
        error(WarningCode.unnecessaryTypeCheckFalse, 31, 9),
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          58,
          6,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              24,
              17,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_dotShorthand_assertInitializer_assertIsNot_true() async {
    await assertNoErrorsInCode('''
class A {
  const A() : assert(0 is! String);
}

const A a = .new();
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_dotShorthand_assertInitializer_enum_false() async {
    await assertErrorsInCode(
      '''
enum E { a, b }
class A {
  const A(E e) : assert(e != .a);
}
const A a = .new(.a);
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          74,
          8,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              43,
              15,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_dotShorthand_assertInitializer_enum_true() async {
    await assertNoErrorsInCode('''
enum E { a, b }
class A {
  const A(E e) : assert(e != .a);
}
const A a = .new(.b);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: E
        _name: String b
        index: int 1
        constructorInvocation
          constructor: <testLibrary>::@enum::E::@constructor::new
        variable: <testLibrary>::@enum::E::@field::b
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_dotShorthand_assertInitializer_simpleInSuperInitializer_true() async {
    await assertErrorsInCode(
      '''
class A {
  const A(): assert(1 is int);
}
class B extends A {
  const B() : super();
}
const B b = .new();
''',
      [error(WarningCode.unnecessaryTypeCheckTrue, 30, 8)],
    );
    var result = _topLevelVar('b');
    assertDartObjectText(result, '''
B
  (super): A
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_dotShorthand_bool_fromEnvironment() async {
    await assertNoErrorsInCode('''
const bool a = .fromEnvironment('a');
const bool b = .fromEnvironment('b', defaultValue: true);
''');
    assertDartObjectText(_topLevelVar('a'), '''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
    assertDartObjectText(
      _evaluateConstant('a', declaredVariables: {'a': 'true'}),
      '''
bool true
''',
    );

    var bResult = _evaluateConstant(
      'b',
      declaredVariables: {'b': 'bbb'},
      lexicalEnvironment: {
        'defaultValue': DartObjectImpl(
          typeSystem,
          typeProvider.boolType,
          BoolState(true),
        ),
      },
    );
    assertDartObjectText(bResult, '''
bool true
''');
  }

  test_dotShorthand_bool_hasEnvironment() async {
    await assertNoErrorsInCode('''
const bool a = .hasEnvironment('a');
''');
    assertDartObjectText(_topLevelVar('a'), '''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
    assertDartObjectText(
      _evaluateConstant('a', declaredVariables: {'a': '42'}),
      '''
bool true
''',
    );
  }

  test_dotShorthand_constantArgument_issue60963() async {
    await assertNoErrorsInCode('''
class A {
  const A();
}
extension type const B(A a) {}

const B b = .new(A());
''');
    var result = _topLevelVar('b');
    assertDartObjectText(result, '''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_dotShorthand_constructor_import_namedParameter() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  final int one;
  const C({this.one = 1});
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';
const C c = .new();
''');

    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
C
  one: int 1
  constructorInvocation
    constructor: package:test/a.dart::@class::C::@constructor::new
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_dotShorthand_constructor_import_namedParameter_positional() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  final int one;
  const C(int x, {this.one = 1});
}
''');
    await assertNoErrorsInCode('''
import 'a.dart';
const C c = .new(1);
''');

    var result = _topLevelVar('c');
    assertDartObjectText(result, '''
C
  one: int 1
  constructorInvocation
    constructor: package:test/a.dart::@class::C::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_dotShorthand_constructor_import_namedParameter_required() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  final int one;
  const C({required this.one});
}
''');
    await assertErrorsInCode(
      '''
import 'a.dart';
const C c = .new();
''',
      [error(CompileTimeErrorCode.missingRequiredArgument, 30, 3)],
    );
  }

  test_dotShorthand_nonConstantArgument_issue60963() async {
    await assertErrorsInCode(
      '''
class A {
  int cannotBeConst;
  A(): cannotBeConst = 0;
}
extension type const B(A a) {}

const B b = .new(A());
''',
      [
        error(CompileTimeErrorCode.constWithNonConst, 108, 3),
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          108,
          3,
        ),
      ],
    );
  }

  test_field_deferred_issue48991() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  const A();
}

const aa = A();
''');

    await assertErrorsInCode(
      '''
import 'a.dart' deferred as a;

class B {
  const B(Object a);
}

main() {
  print(const B(a.aa));
}
''',
      [
        error(
          CompileTimeErrorCode.constConstructorConstantFromDeferredLibrary,
          93,
          2,
        ),
      ],
    );
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

  test_fieldInitializer_functionReference_withTypeParameter() async {
    await assertNoErrorsInCode('''
void g<U>(U a) {}
class A<T> {
  final void Function(T) f;
  const A(): f = g;
}
const a = const A<int>();
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<int>
  f: void Function(int)
    element: <testLibrary>::@function::g
    typeArguments
      T
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<int>
  f: Type int
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<dynamic>
  f: Type dynamic
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: dynamic}
  variable: <testLibrary>::@topLevelVariable::a
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<int, String>
  f: Type int
  g: Type String
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int, U: String}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_fieldInitializer_typeParameter_withoutConstructorTearoffs() async {
    await assertErrorsInCode(
      '''
// @dart=2.12
class A<T> {
  final Object f;
  const A(): f = T;
}
const a = const A<int>();
''',
      [
        error(CompileTimeErrorCode.invalidConstant, 62, 1),
        error(
          CompileTimeErrorCode.invalidConstant,
          77,
          14,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              62,
              1,
              text:
                  "The error is in the field initializer of 'A', and occurs here.",
            ),
          ],
        ),
        error(
          CompileTimeErrorCode.constInitializedWithNonConstantValue,
          77,
          14,
        ),
      ],
    );
    var result = _topLevelVar('a');
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

  test_int_fromEnvironment() async {
    await assertNoErrorsInCode('''
const a = int.fromEnvironment('a');
const b = int.fromEnvironment('b', defaultValue: 42);
''');

    assertDartObjectText(_topLevelVar('a'), '''
int 0
  variable: <testLibrary>::@topLevelVariable::a
''');
    assertDartObjectText(
      _evaluateConstant('a', declaredVariables: {'a': '5'}),
      '''
int 5
''',
    );

    var bResult = _evaluateConstant(
      'b',
      declaredVariables: {'b': 'bbb'},
      lexicalEnvironment: {
        'defaultValue': DartObjectImpl(
          typeSystem,
          typeProvider.intType,
          IntState(42),
        ),
      },
    );
    assertDartObjectText(bResult, '''
int 42
''');
  }

  test_issue47351() async {
    await assertErrorsInCode(
      '''
class Foo {
  final int bar;
  const Foo(this.bar);
}

int bar = 2;
const a = const Foo(bar);
''',
      [
        error(CompileTimeErrorCode.constWithNonConstantArgument, 88, 3),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 88, 3),
      ],
    );
  }

  test_issue47603() async {
    await assertErrorsInCode(
      '''
class C {
  final void Function() c;
  const C(this.c);
}

void main() {
  const C(() {});
}
''',
      [error(CompileTimeErrorCode.constWithNonConstantArgument, 83, 5)],
    );
  }

  test_issue49389() async {
    await assertErrorsInCode(
      '''
class Foo {
  const Foo({required this.bar});
  final Map<String, String> bar;
}

void main() {
  final data = <String, String>{};
  const Foo(bar: data);
}
''',
      [
        // TODO(kallentu): Fix [InvalidConstant.genericError] to handle
        // NamedExpressions.
        error(CompileTimeErrorCode.invalidConstant, 148, 4),
      ],
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/55467')
  test_listLiteral_expression_nonConstant() async {
    await assertErrorsInCode(
      '''
var b = 7;
var x = const A([b]);

class A {
  const A(List<int> p);
}
''',
      [error(CompileTimeErrorCode.nonConstantListElement, 28, 1)],
    );
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A<int>
  f: Type int
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_string_fromEnvironment() async {
    await assertNoErrorsInCode('''
const a = String.fromEnvironment('a');
''');
    assertDartObjectText(_topLevelVar('a'), '''
String <empty>
  variable: <testLibrary>::@topLevelVariable::a
''');
    assertDartObjectText(
      _evaluateConstant('a', declaredVariables: {'a': 'test'}),
      '''
String test
''',
    );
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      namedArguments
        a: int 1
        b: int 2
  c: int 3
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 3
    namedArguments
      b: int 2
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
      namedArguments
        b: int 2
  c: int 3
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 1
    namedArguments
      c: int 3
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      namedArguments
        a: int 1
  b: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 2
    namedArguments
      a: int 1
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      namedArguments
        a: int 1
  b: int 2
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 2
    namedArguments
      a: int 1
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
  b: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 1
      1: int 2
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
  b: int 2
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 1
      1: int 2
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      namedArguments
        a: int 1
  b: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 2
    namedArguments
      a: int 1
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      namedArguments
        a: int 1
  b: int 2
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 2
    namedArguments
      a: int 1
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
  b: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 1
      1: int 2
  variable: <testLibrary>::@topLevelVariable::x
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
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
  b: int 2
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 1
      1: int 2
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_superInitializer_paramTypeMismatch_indirect() async {
    await assertErrorsInCode(
      '''
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
''',
      [
        error(
          CompileTimeErrorCode.constEvalThrowsException,
          153,
          14,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              77,
              1,
              text:
                  "The evaluated constructor 'C' is called by 'D' and 'D' is defined here.",
            ),
            ExpectedContextMessage(
              testFile,
              124,
              1,
              text:
                  "The evaluated constructor 'D' is called by 'E' and 'E' is defined here.",
            ),
            ExpectedContextMessage(
              testFile,
              90,
              1,
              text:
                  "The exception is 'A value of type 'String' can't be assigned to a parameter of type 'double' in a const constructor.' and occurs here.",
            ),
          ],
        ),
      ],
    );
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
B<int>
  (super): A<int>
    f: Type int
    constructorInvocation
      constructor: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: Type int
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
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
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
B<int>
  (super): A
    f: Type int
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: Type int
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_wildcard_regularInitializer() async {
    await assertNoErrorsInCode('''
class A {
  final int _;
  const A(this._);
  int x() => _; // Avoid unused field warning.
}
const a = const A(1);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
A
  _: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_wildcard_regularInitializer_initializerList() async {
    await assertErrorsInCode(
      '''
class A {
  final int _;
  final int y;
  const A(this._): y = _;
}
''',
      [
        error(CompileTimeErrorCode.invalidConstant, 63, 1),
        error(CompileTimeErrorCode.implicitThisReferenceInInitializer, 63, 1),
      ],
    );
  }

  test_wildcard_superInitializer() async {
    await assertNoErrorsInCode('''
class A {
  final int _;
  const A(this._);
  int x() => _; // Avoid unused field warning.
}
class B extends A {
  const B(super._);
}
const a = const B(1);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
B
  (super): A
    _: int 1
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_wildcard_superInitializer_multiple() async {
    await assertNoErrorsInCode('''
class A {
  final int _;
  final int y;
  const A(this._, this.y);
  int x() => _; // Avoid unused field warning.
}
class B extends A {
  const B(super._, super._);
}
const a = const B(1, 2);
''');
    var result = _topLevelVar('a');
    assertDartObjectText(result, '''
B
  (super): A
    _: int 2
    y: int 2
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 2
        1: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 1
      1: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }
}
