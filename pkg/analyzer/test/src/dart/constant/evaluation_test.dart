// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const a = E(42);
const x = a as int;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
int 42
  variable: <testLibrary>::@topLevelVariable::x
  typeNotExtensionTypeErased: E
''');
  }

  test_asExpression_fromExtensionType_nullable() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type E(int? it) {}

const x = null as E;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Null null
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_asExpression_null_neverQuestion() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = null as Never?;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Null null
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_asExpression_toExtensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const x = 42 as E;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
int 42
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_binaryExpression_extensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const a = E(2);
const b = E(3);
const x = (a as num) * (b as num);
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
int 6
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_declaration_staticError_notAssignable() async {
    await resolveTestCodeWithDiagnostics('''
const int x = 'foo';
//            ^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
''');
  }

  test_dotShorthand_enum_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E { v1, v2 }
const E x1 = .v1;
const E x2 = .v2;
''');
    assertDartObjectText(_topLevelVar(result, 'x1'), r'''
E
  _name: String v1
  index: int 0
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::x1
''');
    assertDartObjectText(_topLevelVar(result, 'x2'), r'''
E
  _name: String v2
  index: int 1
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::x2
''');
  }

  test_dotShorthand_equalEqual_constructor() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
}

const v = A() == .new();
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_dotShorthand_equalEqual_constructor_lhsShorthand() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  const A();
}

const v = .new() == A();
//        ^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//         ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'new' isn't defined for the context type '_'.
''');
  }

  test_dotShorthand_equalEqual_field() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
  static const A field = A();
}

const v = A() == .field;
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_dotShorthand_equalEqual_method_error() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static A method() => A();
}

const v = A() == .method();
//        ^^^
// [diag.constWithNonConst] The constructor being called isn't a const constructor.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_dotShorthand_method_invalid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static A method() => A();
}
const A a = .method();
//          ^^^^^^^^^
// [diag.constEvalMethodInvocation] Methods can't be invoked in constant expressions.
''');
  }

  test_dotShorthand_missingContext_invocation() async {
    await resolveTestCodeWithDiagnostics('''
const a = .new();
//        ^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//         ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'new' isn't defined for the context type '_'.
''');
  }

  test_dotShorthand_missingContext_propertyAccess() async {
    await resolveTestCodeWithDiagnostics('''
const a = .id;
//        ^^^
// [diag.dotShorthandMissingContext] A dot shorthand can't be used where there is no context type.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_dotShorthand_propertyAccess() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
  static const A field = A();
}

const A a = .field;
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_dotShorthand_propertyAccess_enum() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
enum E { a }
const E e = .a;
''');
    var result = _topLevelVar(unitResult, 'e');
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
    await resolveTestCodeWithDiagnostics('''
enum E {
  enumValue(["text"].map((x) => x));
//          ^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalMethodInvocation] Methods can't be invoked in constant expressions.

  const E(this.strings);
  final Iterable<String> strings;
}
''');
  }

  /// Enum constants can reference other constants.
  test_enum_enhanced_constants() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E {
  v1(42), v2(v1);
  final Object? a;
  const E([this.a]);
}
''');
    assertDartObjectText(_field(result, 'v2'), r'''
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
    var result = await resolveTestCodeWithDiagnostics('''
enum E<T> {
  v1<double>.named(10),
  v2.named(20);
  final T f;
  const E.named(this.f);
}

const x1 = E.v1;
const x2 = E.v2;
''');
    assertDartObjectText(_topLevelVar(result, 'x1'), r'''
E<double>
  _name: String v1
  f: double 10.0
  index: int 0
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@enum::E::@constructor::named
      substitution: {T: double}
    positionalArguments
      0: double 10.0
  variable: <testLibrary>::@topLevelVariable::x1
''');
    assertDartObjectText(_topLevelVar(result, 'x2'), r'''
E<int>
  _name: String v2
  f: int 20
  index: int 1
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@enum::E::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 20
  variable: <testLibrary>::@topLevelVariable::x2
''');
  }

  test_enum_enhanced_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
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
    assertDartObjectText(_topLevelVar(result, 'x1'), r'''
E<int>
  _name: String v1
  f: int 10
  index: int 0
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@enum::E::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 10
  variable: <testLibrary>::@topLevelVariable::x1
''');
    assertDartObjectText(_topLevelVar(result, 'x2'), r'''
E<int>
  _name: String v2
  f: int 20
  index: int 1
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@enum::E::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 20
  variable: <testLibrary>::@topLevelVariable::x2
''');
    assertDartObjectText(_topLevelVar(result, 'x3'), r'''
E<String>
  _name: String v3
  f: String abc
  index: int 2
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@enum::E::@constructor::new
      substitution: {T: String}
    positionalArguments
      0: String abc
  variable: <testLibrary>::@topLevelVariable::x3
''');
  }

  test_enum_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E { v1, v2 }
const x1 = E.v1;
const x2 = E.v2;
''');
    assertDartObjectText(_topLevelVar(result, 'x1'), r'''
E
  _name: String v1
  index: int 0
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::x1
''');
    assertDartObjectText(_topLevelVar(result, 'x2'), r'''
E
  _name: String v2
  index: int 1
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::x2
''');
  }

  test_equalEqual_bool_bool_false() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = true == false;
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_bool_bool_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = true == true;
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_double_object() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = 1.2 == Object();
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_int_false() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = 1 == 2;
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_int_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = 1 == 1;
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const int? a = 1;
const v = a == null;
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_object() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = 1 == Object();
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_int_userClass() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
}

const v = 1 == A();
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_invalidLeft() async {
    await resolveTestCodeWithDiagnostics('''
const v = a == 1;
//        ^
// [diag.undefinedIdentifier] Undefined name 'a'.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_equalEqual_invalidRight() async {
    await resolveTestCodeWithDiagnostics('''
const v = 1 == a;
//             ^
// [diag.undefinedIdentifier] Undefined name 'a'.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_equalEqual_list_matchingTypeArgs_explicit() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = <int>[] == <int>[];
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_list_matchingTypeArgs_inferred() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = [1, 2] == [1, 2];
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_list_mismatchedTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = const <int>[] == const <num>[];
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_map_matchingTypeArgs_explicit() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = <String, int>{} == <String, int>{};
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_map_matchingTypeArgs_inferred() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = {'x': 1, 'y': 2} == {'x': 1, 'y': 2};
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_map_mismatchedTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = const <String, int>{} == const <String, num>{};
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_null_object() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const Object? a = null;
const v = a == Object();
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_set_matchingTypeArgs_explicit() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = <int>{} == <int>{};
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_set_matchingTypeArgs_inferred() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = {1, 2} == {1, 2};
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_set_mismatchedTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = const <int>{} == const <num>{};
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_string_object() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const v = 'foo' == Object();
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_userClass_hasEqEq() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
  bool operator ==(other) => false;
}

const v = A() == 0;
//        ^^^^^^^^
// [diag.constEvalPrimitiveEquality] In constant expressions, operands of the equality operator must have primitive equality.
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_equalEqual_userClass_hasHashCode() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
  int get hashCode => 0;
}

const v = A() == 0;
//        ^^^^^^^^
// [diag.constEvalPrimitiveEquality] In constant expressions, operands of the equality operator must have primitive equality.
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_equalEqual_userClass_hasPrimitiveEquality_false() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  final int f;
  const A(this.f);
}

const v = A(0) == 0;
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_userClass_hasPrimitiveEquality_language219() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
// @dart = 2.19
class A {
  const A();
}

const v = A() == 0;
//        ^^^^^^^^
// [diag.constEvalTypeBoolNumString] In constant expressions, operands of this operator must be of type 'bool', 'num', 'String' or 'null'.
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_equalEqual_userClass_hasPrimitiveEquality_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  final int f;
  const A(this.f);
}

const v = A(0) == A(0);
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_equalEqual_userClass_noPrimitiveEquality() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  const A();
  bool operator ==(other) => false;
}

const v = A() == A();
//        ^^^^^^^^^^
// [diag.constEvalPrimitiveEquality] In constant expressions, operands of the equality operator must have primitive equality.
''');
  }

  test_hasPrimitiveEquality_bool() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = true;
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_class_hasEqEq() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = const A();

class A {
  const A();
  bool operator ==(other) => false;
}
''');
    _assertHasPrimitiveEqualityFalse(result, 'v');
  }

  test_hasPrimitiveEquality_class_hasEqEq_language219() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart = 2.19
const v = const A();

class A {
  const A();
  bool operator ==(other) => false;
}
''');
    _assertHasPrimitiveEqualityFalse(result, 'v');
  }

  test_hasPrimitiveEquality_class_hasHashCode() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = const A();

class A {
  const A();
  int get hashCode => 0;
}
''');
    _assertHasPrimitiveEqualityFalse(result, 'v');
  }

  test_hasPrimitiveEquality_class_hasHashCode_language219() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart = 2.19
const v = const A();

class A {
  const A();
  int get hashCode => 0;
}
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_class_hasNone() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = const A();

class A {
  const A();
}
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_double() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = 1.2;
''');
    _assertHasPrimitiveEqualityFalse(result, 'v');
  }

  test_hasPrimitiveEquality_functionReference_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = A.foo;

class A {
  static void foo() {}
}
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_functionReference_topLevelFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = foo;

void foo() {}
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_int() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = 0;
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_list() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = const [0];
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_map() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = const <int, String>{0: ''};
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = null;
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_record_named_false() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = (f1: true, f2: 1.2);
''');
    _assertHasPrimitiveEqualityFalse(result, 'v');
  }

  test_hasPrimitiveEquality_record_named_true() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = (f1: true, f2: 0);
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_record_positional_false() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = (true, 1.2);
''');
    _assertHasPrimitiveEqualityFalse(result, 'v');
  }

  test_hasPrimitiveEquality_record_positional_true() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = (true, 0);
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_set() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = const {0};
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_symbol() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = #foo.bar;
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_hasPrimitiveEquality_type() async {
    var result = await resolveTestCodeWithDiagnostics('''
const v = int;
''');
    _assertHasPrimitiveEqualityTrue(result, 'v');
  }

  test_identical_extensionType_nullable() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
extension type E(int it) {}

class A {
  final E? f;
  const A() : f = null;
}

const v = A();
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
A
  f: Null null
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_identical_extensionType_types_recursive() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = identical(ExList<ExInt>, List<int>);

extension type const ExInt(int value) implements int {}
extension type const ExList<T>(List<T> value) implements List<T> {}
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_type_functionType_different() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = identical(typeof<void Function()>, typeof<void Function()?>);
typedef typeof<T> = T;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_type_functionType_same() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = identical(typeof<void Function()>, typeof<void Function()>);
typedef typeof<T> = T;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_differentTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
const c = identical(C<int>, C<String>);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_differentTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
class D<T> {}
const c = identical(C<int>, D<int>);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_sameType() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
const c = identical(C<int>, C<int>);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_simpleTypeAlias() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef TC = C<int>;
const c = identical(C<int>, TC);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<int>, TC<int>);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_differentTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<int>, TC<String>);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_implicitTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef TC<T> = C<T>;
const c = identical(C<dynamic>, TC);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_explicitTypeArgs_typeAlias_implicitTypeArgs_bound() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T extends num> {}
typedef TC<T extends num> = C<T>;
const c = identical(C<num>, TC);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_simple_differentTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = identical(int, String);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_identical_typeLiteral_simple_sameType() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = identical(int, int);
''');
    var result = _topLevelVar(unitResult, 'c');
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

    var unitResult = await resolveTestCodeWithDiagnostics('''
import 'a.dart';

const b = a;
''');

    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
A<int>
  t: int 0
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 0
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_instanceCreationExpression_custom_generic_extensionType_explicit() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

class C<T> {
  const C();
}

const x = C<E>();
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
C<int>
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::C::@constructor::new
      substitution: {T: E}
  variable: <testLibrary>::@topLevelVariable::x
  typeNotExtensionTypeErased: C<E>
''');
  }

  test_instanceCreationExpression_custom_generic_extensionType_inferred() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

class C<T> {
  final T f;
  const C(this.f);
}

const x = C(E(42));
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
C<int>
  f: int 42
    typeNotExtensionTypeErased: E
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::C::@constructor::new
      substitution: {T: E}
    positionalArguments
      0: int 42
        typeNotExtensionTypeErased: E
  variable: <testLibrary>::@topLevelVariable::x
  typeNotExtensionTypeErased: C<E>
''');
  }

  test_instanceCreationExpression_extensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const x = E(42);
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
int 42
  variable: <testLibrary>::@topLevelVariable::x
  typeNotExtensionTypeErased: E
''');
  }

  test_isExpression_fromExtensionType_false() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const a = E(42);
const x = a is String;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_isExpression_fromExtensionType_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const a = E(42);
const x = a is int;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_isExpression_toExtensionType_false() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(String it) {}

const x = 42 is E;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_isExpression_toExtensionType_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const x = 42 is E;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_listLiteral_extensionType_explicitType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const x = <E>[];
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
List<int>
  variable: <testLibrary>::@topLevelVariable::x
  typeNotExtensionTypeErased: List<E>
''');
  }

  test_listLiteral_extensionType_inferredType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const x = [E(0), E(1)];
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
List<int>
  elements
    int 0
      typeNotExtensionTypeErased: E
    int 1
      typeNotExtensionTypeErased: E
  variable: <testLibrary>::@topLevelVariable::x
  typeNotExtensionTypeErased: List<E>
''');
  }

  test_mapLiteral_extensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const E(int it) {}

const x = {E(0): E(1)};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Map<int, int>
  entries
    entry
      key: int 0
        typeNotExtensionTypeErased: E
      value: int 1
        typeNotExtensionTypeErased: E
  variable: <testLibrary>::@topLevelVariable::x
  typeNotExtensionTypeErased: Map<E, E>
''');
  }

  /// https://github.com/dart-lang/sdk/issues/53029
  /// Dependencies of map patterns should be considered.
  test_mapPattern_dependencies() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

void f(Object? x) {
  if (x case {a: _}) {}
}
''');
  }

  test_privateNamedParameter() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C {
  final int _x;
  final int _y;
  const C({required this._x, required this._y});
  int get xy => _x + _y; // Avoid unused field warning.
}
const c = C(x: 123, y: 456);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
C
  _x: int 123
  _y: int 456
  constructorInvocation
    constructor: <testLibrary>::@class::C::@constructor::new
    namedArguments
      x: int 123
      y: int 456
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_dynamic_length_notNull() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const dynamic d = 'foo';
const int? c = d?.length;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_dynamic_length_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const dynamic d = null;
const int? c = d?.length;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_list_length_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const List? l = null;
const int? c = l?.length;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_string_length_notNull() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const String? s = 'foo';
const int? c = s?.length;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_propertyAccess_nullAware_string_length_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const String? s = null;
const int? c = s?.length;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_recordTypeAnnotation() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = ('',) is (int,);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_typeParameter() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A<X> {
  const A();
  void m() {
    const x = X;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//            ^
// [diag.constTypeParameter] Type parameters can't be used in a constant expression.
  }
}
''');
    var result = _localVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitBinaryExpression_extensionMethod() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
extension on Object {
  int operator +(Object other) => 0;
}

const Object v1 = 0;
const v2 = v1 + v1;
//         ^^^^^^^
// [diag.constEvalExtensionMethod] Extension methods can't be used in constant expressions.
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitBinaryExpression_extensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
extension type const A(int it) {
  int operator +(Object other) => 0;
}

const v1 = A(1);
const v2 = v1 + 2;
//         ^^^^^^
// [diag.constEvalExtensionTypeMethod] Extension type methods can't be used in constant expressions.
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitBinaryExpression_extensionType_implementsInt() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
extension type const A(int it) implements int {}

const v1 = A(1);
const v2 = v1 + 2;
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::v2
''');
  }

  test_visitBinaryExpression_gt_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 2 > 3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gte_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 2 >= 3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_fewerBits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFFFFFFFF >>> 8;
''');
    var result = _topLevelVar(unitResult, 'c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xffffff
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_moreBits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFFFFFFFF >>> 33;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_moreThan64Bits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFFFFFFFF >>> 65;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_negativeBits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFFFFFFFF >>> -2;
//        ^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitBinaryExpression_gtGtGt_negative_zeroBits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFFFFFFFF >>> 0;
''');
    var result = _topLevelVar(unitResult, 'c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xffffffff
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_fewerBits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFF >>> 3;
''');
    var result = _topLevelVar(unitResult, 'c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0x1f
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_moreBits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFF >>> 9;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_moreThan64Bits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFF >>> 65;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_negativeBits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFF >>> -2;
//        ^^^^^^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitBinaryExpression_gtGtGt_positive_zeroBits() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 0xFF >>> 0;
''');
    var result = _topLevelVar(unitResult, 'c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
int 0xff
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_lt_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 2 < 3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_lte_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 2 <= 3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_questionQuestion_invalid_notNull() async {
    await resolveTestCodeWithDiagnostics('''
final x = 0;
const c = x ?? 1;
//        ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//          ^^^^
// [diag.deadCode] Dead code.
//             ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
''');
  }

  test_visitBinaryExpression_questionQuestion_notNull_invalid() async {
    await resolveTestCodeWithDiagnostics('''
final x = 1;
const c = 0 ?? x;
//          ^^^^
// [diag.deadCode] Dead code.
//             ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
''');
  }

  test_visitConditionalExpression_eager_invalid_int_int() async {
    await resolveTestCodeWithDiagnostics('''
const c = null ? 1 : 0;
//        ^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
// [diag.constEvalTypeBool] In constant expressions, operands of this operator must be of type 'bool'.
''');
  }

  test_visitConditionalExpression_instantiatedFunctionType_variable() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f<T>(T p, {T? q}) {}

const void Function<T>(T p) g = f;

const bool b = false;
const void Function(int p) h = b ? g : g;
''');
    var result = _topLevelVar(unitResult, 'h');
    assertDartObjectText(result, r'''
void Function(int, {int? q})
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitConditionalExpression_unknownCondition() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const bool kIsWeb = identical(0, 0.0);
const x = kIsWeb ? 0 : 1;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<unknown> int
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitConditionalExpression_unknownCondition_errorInConstructor() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const bool kIsWeb = identical(0, 0.0);

var a = 2;
const x = A(kIsWeb ? 0 : a);
//                       ^
// [diag.invalidConstant] Invalid constant value.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.

class A {
  const A(int _);
}
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitConditionalExpression_unknownCondition_undefinedIdentifier() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const bool kIsWeb = identical(0, 0.0);
const x = kIsWeb ? a : b;
//                 ^
// [diag.undefinedIdentifier] Undefined name 'a'.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                     ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitConstructorDeclaration_cycle() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final A a;
  const A() : a = const A();
//      ^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
}

''');
  }

  test_visitConstructorDeclaration_cycle_subclass_issue46735() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  const EmptyInjector();
}

abstract class BaseInjector {
  final BaseInjector parent;

  const BaseInjector([BaseInjector? parent])
//      ^^^^^^^^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
      : parent = parent ?? const EmptyInjector();
}

abstract class Injector implements BaseInjector {
  const Injector();
}

class EmptyInjector extends BaseInjector implements Injector {
  const EmptyInjector();
//      ^^^^^^^^^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
}
''');
  }

  test_visitConstructorDeclaration_field_asExpression_nonConst() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic y = 2;
class A {
  const A();
//^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'x' is initialized with a non-constant value.
  final x = y as num;
}
''');
  }

  test_visitConstructorReference_generic_named() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {
  C.foo();
}
const c = C<int>.foo;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: <testLibrary>::@class::C::@constructor::foo
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConstructorReference_generic_unnamed() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {
  C();
}
const c = C<int>.new;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: <testLibrary>::@class::C::@constructor::new
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConstructorReference_identical_aliasIsNotGeneric() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef MyC = C<int>;
const a = identical(MyC.new, C<int>.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentBound() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC.new, C.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentCount() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T, U> {}
typedef MyC<T> = C<T, int>;
const a = identical(MyC.new, C.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentCount2() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T, U> {}
typedef MyC<T> = C;
const a = identical(MyC.new, C.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_differentOrder() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T, U> {}
typedef MyC<T, U> = C<U, T>;
const a = identical(MyC.new, C.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_instantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, C<int>.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsNotProperRename_mixedInstantiations() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, (MyC.new)<int>);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_instantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mixedInstantiations() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC<int>.new, (MyC.new)<int>);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mutualSubtypes_dynamic() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef MyC<T extends Object?> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_mutualSubtypes_futureOr() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import 'dart:async';
class C<T extends FutureOr<num>> {}
typedef MyC<T extends num> = C<T>;
const a = identical(MyC<int>.new, MyC<int>.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_aliasIsProperRename_uninstantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
typedef MyC<T> = C<T>;
const a = identical(MyC.new, MyC.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_differentClasses() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
class D<T> {}
const a = identical(C<int>.new, D<int>.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_differentConstructors() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {
  C();
  C.named();
}
const a = identical(C<int>.new, C<int>.named);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_differentTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
const a = identical(C<int>.new, C<String>.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_explicitTypeArgs_sameElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
const a = identical(C<int>.new, C<int>.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_inferredTypeArgs_sameElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
const C<int> Function() c1 = C.new;
const c2 = C<int>.new;
const a = identical(c1, c2);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_notInstantiated_differentClasses() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
class D<T> {}
const a = identical(C.new, D.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_notInstantiated_differentConstructors() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {
  C();
  C.named();
}
const a = identical(C.new, C.named);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_notInstantiated_sameElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
const a = identical(C.new, C.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_identical_onlyOneHasTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {}
const a = identical(C<int>.new, C.new);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitConstructorReference_nonGeneric_named() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {
  const C.foo();
}
const c = C<int>.foo;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: <testLibrary>::@class::C::@constructor::foo
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConstructorReference_nonGeneric_unnamed() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class C<T> {
  const C();
}
const c = C<int>.new;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
C<int> Function()
  element: <testLibrary>::@class::C::@constructor::new
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_defaultConstructorValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

class C<T> {
  final void Function(T) p;
  const C({this.p = f});
//                  ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
}
''');
  }

  test_visitFunctionReference_explicitTypeArgs_complexExpression() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const b = true;
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = (b ? foo : bar)<int>;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::foo
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_complexExpression_differentTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const b = true;
void foo<T>(String a, T b) {}
void bar<T>(T a, String b) {}
const g = (b ? foo : bar)<int>;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(String, int)
  element: <testLibrary>::@function::foo
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_constantType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
const g = f<int>;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_notMatchingBound() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void f<T extends num>(T a) {}
const g = f<String>;
//          ^^^^^^
// [diag.typeArgumentNotMatchingBounds] 'String' doesn't conform to the bound 'num' of the type parameter 'T'.
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(String)
  element: <testLibrary>::@function::f
  typeArguments
    String
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_notType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const g = foo<true>;
//        ^^^^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
//           ^
// [diag.undefinedOperator] The operator '<' isn't defined for the type 'void Function<T>(T)'.
//                ^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
//                 ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_tooFew() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T, U>(T a, U b) {}
const g = foo<int>;
//           ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 2 type parameters, but 1 type arguments are given.
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_tooMany() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const g = foo<int, String>;
//           ^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The function 'foo' is declared with 1 type parameters, but 2 type arguments are given.
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitFunctionReference_explicitTypeArgs_functionName_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}

class C<U> {
  void m() {
    const g = f<U>;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
//              ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
  }
}
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_differentElements() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = identical(foo<int>, bar<int>);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_differentTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<String>);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_onlyOneHasTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_sameElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<int>);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_explicitTypeArgs_identical_sameElement_runtimeTypeEquality() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void foo<T>(T a) {}
const g = identical(foo<Object>, foo<FutureOr<Object>>);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_differentElements() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = identical(foo<int>, bar<int>);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_differentTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<String>);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_onlyOneHasTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_sameElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const g = identical(foo<int>, foo<int>);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_explicitTypeArgs_sameElement_runtimeTypeEquality() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void foo<T>(T a) {}
const g = identical(foo<Object>, foo<FutureOr<Object>>);
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_identical_implicitTypeArgs_differentTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(String) g = foo;
const c = identical(f, g);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_identical_implicitTypeArgs_sameTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(int) g = foo;
const c = identical(f, g);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_identical_uninstantiated_sameElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const c = identical(foo, foo);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_implicitTypeArgs_identical_differentTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(String) g = foo;
const c = identical(f, g);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_implicitTypeArgs_identical_sameTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const void Function(int) f = foo;
const void Function(int) g = foo;
const c = identical(f, g);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_uninstantiated_complexExpression() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const b = true;
void foo<T>(T a) {}
void bar<T>(T a) {}
const g = b ? foo : bar;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function<T>(T)
  element: <testLibrary>::@function::foo
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_uninstantiated_functionName() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
const g = f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function<T>(T)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitFunctionReference_uninstantiated_identical_sameElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo<T>(T a) {}
const c = identical(foo, foo);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitFunctionReference_wildcard_local() async {
    await resolveTestCodeWithDiagnostics(r'''
test() {
  void _() {}
//^^^^^^^^^^^
// [diag.deadCode] Dead code.
  const c = _;
//          ^
// [diag.undefinedIdentifier] Undefined name '_'.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
  print(c);
}
''');
  }

  test_visitFunctionReference_wildcard_top() async {
    await resolveTestCodeWithDiagnostics(r'''
void _() {}
const c = _;
''');
  }

  test_visitInstanceCreationExpression_invalidNamedArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A({ required int x });
}
const a = A(x: false);
//          ^^^^^^^^
// [diag.constConstructorParamTypeMismatch] A value of type 'bool' can't be assigned to a parameter of type 'int' in a const constructor.
//             ^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'bool' can't be assigned to the parameter type 'int'.
''');
  }

  test_visitInstanceCreationExpression_invalidNamedArg_superParam() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A({ required int x });
}
class B extends A {
  const B({ required super.x });
}
const a = B(x: false);
//          ^^^^^^^^
// [diag.constConstructorParamTypeMismatch] A value of type 'bool' can't be assigned to a parameter of type 'int' in a const constructor.
//             ^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'bool' can't be assigned to the parameter type 'int'.
''');
  }

  test_visitInstanceCreationExpression_invalidPositionalArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int x);
}
const a = A(false);
//          ^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'bool' can't be assigned to the parameter type 'int'.
// [diag.constConstructorParamTypeMismatch] A value of type 'bool' can't be assigned to a parameter of type 'int' in a const constructor.
''');
  }

  test_visitInstanceCreationExpression_invalidPositionalArg_superParam() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int x);
}
class B extends A {
  const B(super.x);
}
const a = B(false);
//          ^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'bool' can't be assigned to the parameter type 'int'.
// [diag.constConstructorParamTypeMismatch] A value of type 'bool' can't be assigned to a parameter of type 'int' in a const constructor.
''');
  }

  test_visitInstanceCreationExpression_missingNamedArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A({required int x });
}
const a = A();
//        ^
// [diag.missingRequiredArgument] The named parameter 'x' is required, but there's no corresponding argument.
''');
  }

  test_visitInstanceCreationExpression_missingNamedArg_superParam() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A({required int x });
}
class B extends A {
  const B({required super.x });
}
const a = B();
//        ^
// [diag.missingRequiredArgument] The named parameter 'x' is required, but there's no corresponding argument.
''');
  }

  test_visitInstanceCreationExpression_missingPositionalArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int x);
}
const a = A();
//          ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
''');
  }

  test_visitInstanceCreationExpression_missingPositionalArg_superParam() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int x);
}
class B extends A {
  const B(super.x);
}
const a = B();
//          ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'B.new', but 0 found.
''');
  }

  test_visitInstanceCreationExpression_noArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
}
const a = A();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitInstanceCreationExpression_noConstConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
const a = A();
//        ^^^
// [diag.constWithNonConst] The constructor being called isn't a const constructor.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitInstanceCreationExpression_simpleArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A(int x);
}
const a = A(1);
''');
    var result = _topLevelVar(unitResult, 'a');
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
    // TODO(kallentu): This should not be reported.
    // https://github.com/dart-lang/sdk/issues/50441
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  const C.named();
}

const x = C<int>.();
//        ^^^^^^^^
// [diag.classInstantiationAccessToUnknownMember] The class 'C' doesn't have a constructor named '('.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//               ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }

  test_visitInterpolationExpression_list() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = '${const [2]}';
//         ^^^^^^^^^^^^
// [diag.constEvalTypeBoolNumString] In constant expressions, operands of this operator must be of type 'bool', 'num', 'String' or 'null'.
''');
  }

  test_visitIsExpression_is_functionType_correctTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
void foo(int a) {}
const c = foo is void Function(int);
//        ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitIsExpression_is_instanceOfSameClass() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = const A();
const b = a is A;
//        ^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
class A {
  const A();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_instanceOfSubclass() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = const B();
const b = a is A;
//        ^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = null;
const b = a is A;
class A {}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null_nullable() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = null;
const b = a is A?;
class A {}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null_object() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = null;
const b = a is Object;
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSameClass() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = const A();
const b = a is! A;
//        ^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
class A {
  const A();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSubclass() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = const B();
const b = a is! A;
//        ^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_isNot_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = null;
const b = a is! A;
class A {}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitListLiteral_forElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = [for (int i = 0; i < 3; i++) i];
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitListLiteral_ifElement_nonBoolCondition() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const dynamic c = 2;
const x = [1, if (c) 2 else 3, 4];
//                ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitListLiteral_ifElement_nonBoolCondition_static() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = [1, if (1) 2 else 3, 4];
//                ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitListLiteral_listElement_explicitType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = <String>['a', 'b', 'c'];
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
List<String>
  elements
    String a
    String b
    String c
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitListLiteral_listElement_explicitType_functionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = <void Function()>[];
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
List<void Function()>
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitListLiteral_listElement_field_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final String bar = '';
  const A();
  List<String> foo() => const [bar];
//                             ^^^
// [diag.nonConstantListElement] The values in a const list literal must be constants.
}
''');
  }

  test_visitListLiteral_listElement_field_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static const String bar = '';
  const A();
  List<String> foo() => const [bar];
}
''');
  }

  test_visitListLiteral_listElement_simple() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = ['a', 'b', 'c'];
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
List<String>
  elements
    String a
    String b
    String c
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitListLiteral_listElement_variableElements() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = 0;
const b = 2;
const c = [a, 1, b];
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
List<int>
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
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const dynamic a = 5;
const x = <int>[...a];
//                 ^
// [diag.constSpreadExpectedListOrSet] A list or a set is expected in this spread.
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitListLiteral_spreadElement_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = null;
const List<String> x = [
  'anotherString',
  ...?a,
];
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
List<String>
  elements
    String anotherString
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitListLiteral_spreadElement_set() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = {'string'};
const List<String> x = [
  'anotherString',
  ...a,
];
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
List<String>
  elements
    String anotherString
    String string
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitMethodInvocation_notIdentical() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() {
  return 3;
}
const a = f();
//        ^^^
// [diag.constEvalMethodInvocation] Methods can't be invoked in constant expressions.
''');
  }

  test_visitNamedType_typeLiteral_typeParameter_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(Object? x) {
  if (x case const (T)) {}
//                  ^
// [diag.constTypeParameter] Type parameters can't be used in a constant expression.
}
''');
  }

  test_visitNamedType_typeLiteral_typeParameter_nested2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(Object? x) {
  if (x case const (List<T>)) {}
//                  ^^^^^^^
// [diag.constTypeParameter] Type parameters can't be used in a constant expression.
}
''');
  }

  test_visitPrefixedIdentifier_function() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import '' as self;
void f(int a) {}
const g = self.f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPrefixedIdentifier_genericFunction_instantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import '' as self;
void f<T>(T a) {}
const void Function(int) g = self.f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPrefixedIdentifier_genericFunction_instantiatedNonIdentifier() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f<T>(T a) {}
const b = false;
const g1 = f;
const g2 = f;
const void Function(int) h = b ? g1 : g2;
''');
    var result = _topLevelVar(unitResult, 'h');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitPrefixedIdentifier_genericFunction_instantiatedPrefixed() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import '' as self;
void f<T>(T a) {}
const g = f;
const void Function(int) h = self.g;
''');
    var result = _topLevelVar(unitResult, 'h');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitPrefixedIdentifier_genericVariable_uninstantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import '' as self;
void f<T>(T a) {}
const g = f;
const h = self.g;
''');
    var result = _topLevelVar(unitResult, 'h');
    assertDartObjectText(result, r'''
void Function<T>(T)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitPrefixedIdentifier_length_invalidTarget() async {
    await resolveTestCodeWithDiagnostics('''
void main() {
  const RequiresNonEmptyList([1]);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalPropertyAccess][context 1] The property 'length' can't be accessed on the type 'List<int>' in a constant expression.
}

class RequiresNonEmptyList {
  const RequiresNonEmptyList(List<int> numbers) : assert(numbers.length > 0);
//                                                       ^^^^^^^^^^^^^^
// [context 1] The error is in the assert initializer of 'RequiresNonEmptyList', and occurs here.
}
''');
  }

  test_visitPrefixExpression_bitNot() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = ~42;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int -43
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitPrefixExpression_extensionMethod() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension on Object {
  int operator -() => 0;
}

const Object v1 = 1;
const v2 = -v1;
//         ^^^
// [diag.constEvalExtensionMethod] Extension methods can't be used in constant expressions.
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitPrefixExpression_extensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const A(int it) {
  int operator -() => 0;
}

const v1 = A(1);
const v2 = -v1;
//         ^^^
// [diag.constEvalExtensionTypeMethod] Extension type methods can't be used in constant expressions.
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitPrefixExpression_extensionType_implementsInt() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
extension type const A(int it) implements int {}

const v1 = A(1);
const v2 = -v1;
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
int -1
  variable: <testLibrary>::@topLevelVariable::v2
''');
  }

  test_visitPrefixExpression_logicalNot() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = !true;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitPrefixExpression_negated_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = -true;
//        ^
// [diag.undefinedOperator] The operator 'unary-' isn't defined for the type 'bool'.
//        ^^^^^
// [diag.constEvalTypeNum] In constant expressions, operands of this operator must be of type 'num'.
''');
  }

  test_visitPrefixExpression_negated_double() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = -42.3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
double -42.3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitPrefixExpression_negated_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = -42;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int -42
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitPropertyAccess_length_complex() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const x = ('qwe' + 'rty').length;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
int 6
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitPropertyAccess_length_simple() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const x = 'Dvorak'.length;
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
int 6
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitPropertyAccess_staticMethod() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import '' as self;
class C {
  static void f(int a) {}
}
const g = self.C.f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@class::C::@method::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPropertyAccess_staticMethod_generic_instantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import '' as self;
class C {
  static void f<T>(T a) {}
}
const void Function(int) g = self.C.f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@class::C::@method::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPropertyAccess_staticMethod_ofExtension() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  static int f(String s) => 7;
}
const g = self.E.f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
int Function(String)
  element: <testLibrary>::@extension::E::@method::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitPropertyAccess_staticMethod_ofExtensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type ET(int it) {
  static int f(String s) => 7;
}
const g = self.ET.f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
int Function(String)
  element: <testLibrary>::@extensionType::ET::@method::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitRecordLiteral_inConstructorInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final bool b;
  const A(r) : b = r is (int, ) ? true : true;
}
''');
  }

  test_visitRecordLiteral_mixedTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = (0, f1: 10, f2: 2.3);
''');
    var result = _topLevelVar(unitResult, 'x');
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
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = (f1: 10, f2: -3);
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Record({int f1, int f2})
  namedFields
    f1: int 10
    f2: int -3
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitRecordLiteral_namedField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
final bar = '';
({String bar, }) foo() => const (bar: bar, );
//                                    ^^^
// [diag.nonConstantRecordField] The fields in a const record literal must be constants.
''');
  }

  test_visitRecordLiteral_objectField_generic() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final (T, T) record;
  const A(T a) : record = (a, a);
}

const a = A(42);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A<int>
  record: Record(int, int)
    positionalFields
      $1: int 42
      $2: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitRecordLiteral_positional() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = (20, 0, 7);
''');
    var result = _topLevelVar(unitResult, 'x');
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
    await resolveTestCodeWithDiagnostics(r'''
final bar = '';
(String, ) foo() => const (bar, );
//                         ^^^
// [diag.nonConstantRecordField] The fields in a const record literal must be constants.
''');
  }

  test_visitRecordLiteral_withoutEnvironment() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = (1, 'b', c: false);
''');
    var result = _topLevelVar(unitResult, 'a');
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
    await resolveTestCodeWithDiagnostics(r'''
const l = [];
const ambiguous = {...l, 1: 2};
//                ^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralBoth] The literal can't be either a map or a set because it contains at least one literal map entry or a spread operator spreading a 'Map', and at least one element which is neither of these.
''');
  }

  test_visitSetOrMapLiteral_ambiguous_either() async {
    await resolveTestCodeWithDiagnostics(r'''
const int? i = 1;
const res  = {...?i};
//           ^^^^^^^
// [diag.ambiguousSetOrMapLiteralEither] This literal must be either a map or a set, but the elements don't have enough information for type inference to work.
''');
  }

  test_visitSetOrMapLiteral_ambiguous_expression() async {
    await resolveTestCodeWithDiagnostics(r'''
const m = {1: 1};
const res = {...m, 2};
//          ^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralBoth] The literal can't be either a map or a set because it contains at least one literal map entry or a spread operator spreading a 'Map', and at least one element which is neither of these.
''');
  }

  test_visitSetOrMapLiteral_ambiguous_inList() async {
    await resolveTestCodeWithDiagnostics(r'''
const l = [];
const ambiguous = {...l, 1: 2};
//                ^^^^^^^^^^^^
// [diag.ambiguousSetOrMapLiteralBoth] The literal can't be either a map or a set because it contains at least one literal map entry or a spread operator spreading a 'Map', and at least one element which is neither of these.
const anotherList = [...ambiguous];
''');
  }

  test_visitSetOrMapLiteral_map_complexKey() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A(this.x);
}
void fn() => 2;
const x = {A(0): 1, fn: 2};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Map<Object, int>
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
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = {1: null, for (final i in const []) i: null};
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitSetOrMapLiteral_map_forElement_nested() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = {1: null, if (true) for (final i in const []) i: null};
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitSetOrMapLiteral_map_ifElement_nonBoolCondition() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const dynamic nonBool = null;
const c = const {if (nonBool) 'a' : 1};
//                   ^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitSetOrMapLiteral_map_mapElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const x = {'a' : 'm', 'b' : 'n', 'c' : 'o'};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Map<String, String>
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
    var unitResult = await resolveTestCodeWithDiagnostics('''
const x = {'string': 1};
const Map<String, int> alwaysInclude = {
  'anotherString': 0,
  ...x,
};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Map<String, int>
  entries
    entry
      key: String string
      value: int 1
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitSetOrMapLiteral_map_spread_notMap() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = ['string'];
const Map<String, int> alwaysInclude = {
  'anotherString': 0,
  ...x,
//   ^
// [diag.constSpreadExpectedMap] A map is expected in this spread.
// [diag.notMapSpread] Spread elements in map literals must implement 'Map'.
};
''');
  }

  test_visitSetOrMapLiteral_map_spread_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = null;
const Map<String, int> x = {
  'anotherString': 0,
  ...?a,
};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Map<String, int>
  entries
    entry
      key: String anotherString
      value: int 0
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitSetOrMapLiteral_set_double_zeros() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class C {
  final double x;
  const C(this.x);
}

const cp0 = C(0.0);
const cm0 = C(-0.0);

const a = {cp0, cm0};
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
Set<C>
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
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const Set set = {};
const x = {for (final i in set) i};
//        ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//         ^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalForElement] Constant expressions don't support 'for' elements.
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitSetOrMapLiteral_set_ifElement_nonBoolCondition() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const dynamic nonBool = 'a';
const c = const {if (nonBool) 3};
//                   ^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitSetOrMapLiteral_set_spread_list() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = ['string'];
const Set<String> x = {
  'anotherString',
  ...a,
};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Set<String>
  elements
    String anotherString
    String string
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitSetOrMapLiteral_set_spread_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = null;
const Set<String> x = {
  'anotherString',
  ...?a,
};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
Set<String>
  elements
    String anotherString
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitSimpleIdentifier_className() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = C;
class C {}
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
Type
  toTypeValue: C
  toTypeValueNotExtensionTypeErased: C
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitSimpleIdentifier_extensionTypeName() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = E;
extension type E(int it);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
Type
  toTypeValue: int
  toTypeValueNotExtensionTypeErased: E
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitSimpleIdentifier_extensionTypeObject() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = E(0);
extension type const E(int it);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::a
  typeNotExtensionTypeErased: E
''');
  }

  test_visitSimpleIdentifier_function() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f(int a) {}
const g = f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitSimpleIdentifier_genericFunction_instantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f<T>(T a) {}
const void Function(int) g = f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitSimpleIdentifier_genericFunction_nonGeneric() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f(int a) {}
const void Function(int) g = f;
''');
    var result = _topLevelVar(unitResult, 'g');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::g
''');
  }

  test_visitSimpleIdentifier_genericVariable_instantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f<T>(T a) {}
const g = f;
const void Function(int) h = g;
''');
    var result = _topLevelVar(unitResult, 'h');
    assertDartObjectText(result, r'''
void Function(int)
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitSimpleIdentifier_genericVariable_uninstantiated() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f<T>(T a) {}
const g = f;
const h = g;
''');
    var result = _topLevelVar(unitResult, 'h');
    assertDartObjectText(result, r'''
void Function<T>(T)
  element: <testLibrary>::@function::f
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitSimpleIdentifier_instantiatedFunctionType_field() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f<T>(T a, {T? b}) {}

class C {
  static const void Function<T>(T a) g = f;
  static const void Function(int a) h = g;
}
''');
    var result = _field(unitResult, 'h');
    assertDartObjectText(result, r'''
void Function(int, {int? b})
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@class::C::@field::h
''');
  }

  test_visitSimpleIdentifier_instantiatedFunctionType_parameter() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f<T>(T a, {T? b}) {}

class C {
  const C(void Function<T>(T a) g) : h = g;
  final void Function(int a) h;
}

const c = C(f);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
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
    var unitResult = await resolveTestCodeWithDiagnostics('''
void f<T>(T a, {T? b}) {}

const void Function<T>(T a) g = f;

const void Function(int a) h = g;
''');
    var result = _topLevelVar(unitResult, 'h');
    assertDartObjectText(result, r'''
void Function(int, {int? b})
  element: <testLibrary>::@function::f
  typeArguments
    int
  variable: <testLibrary>::@topLevelVariable::h
''');
  }

  test_visitUnaryExpression_extensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const A(int it) {
  int operator -() => 0;
}

const v1 = A(1);
const v2 = -v1;
//         ^^^
// [diag.constEvalExtensionTypeMethod] Extension type methods can't be used in constant expressions.
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
<null>
''');
  }

  void _assertHasPrimitiveEqualityFalse(
    TestResolvedUnitResult unitResult,
    String name,
  ) {
    var value = _topLevelVar(unitResult, name)!;
    var featureSet = unitResult.libraryElement.featureSet;
    var has = value.hasPrimitiveEquality(featureSet);
    expect(has, isFalse);
  }

  void _assertHasPrimitiveEqualityTrue(
    TestResolvedUnitResult unitResult,
    String name,
  ) {
    var value = _topLevelVar(unitResult, name)!;
    var featureSet = unitResult.libraryElement.featureSet;
    var has = value.hasPrimitiveEquality(featureSet);
    expect(has, isTrue);
  }
}

@reflectiveTest
mixin ConstantVisitorTestCases on ConstantVisitorTestSupport {
  test_listLiteral_ifElement_false_withElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = [1, if (1 < 0) 2 else 3, 4];
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
List<int>
  elements
    int 1
    int 3
    int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_listLiteral_ifElement_false_withoutElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = [1, if (1 < 0) 2, 3];
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
List<int>
  elements
    int 1
    int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_listLiteral_ifElement_true_withElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = [1, if (1 > 0) 2 else 3, 4];
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
List<int>
  elements
    int 1
    int 2
    int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_listLiteral_ifElement_true_withoutElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = [1, if (1 > 0) 2, 3];
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
List<int>
  elements
    int 1
    int 2
    int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_listLiteral_nested() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = [1, if (1 > 0) if (2 > 1) 2, 3];
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
List<int>
  elements
    int 1
    int 2
    int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_listLiteral_spreadElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = [1, ...[2, 3], 4];
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
List<int>
  elements
    int 1
    int 2
    int 3
    int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_mapLiteral_ifElement_false_withElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {'a' : 1, if (1 < 0) 'b' : 2 else 'c' : 3, 'd' : 4};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Map<String, int>
  entries
    entry
      key: String a
      value: int 1
    entry
      key: String c
      value: int 3
    entry
      key: String d
      value: int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_mapLiteral_ifElement_false_withoutElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {'a' : 1, if (1 < 0) 'b' : 2, 'c' : 3};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Map<String, int>
  entries
    entry
      key: String a
      value: int 1
    entry
      key: String c
      value: int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_mapLiteral_ifElement_true_withElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {'a' : 1, if (1 > 0) 'b' : 2 else 'c' : 3, 'd' : 4};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Map<String, int>
  entries
    entry
      key: String a
      value: int 1
    entry
      key: String b
      value: int 2
    entry
      key: String d
      value: int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_mapLiteral_ifElement_true_withoutElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {'a' : 1, if (1 > 0) 'b' : 2, 'c' : 3};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Map<String, int>
  entries
    entry
      key: String a
      value: int 1
    entry
      key: String b
      value: int 2
    entry
      key: String c
      value: int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_mapLiteral_nested() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {'a' : 1, if (1 > 0) if (2 > 1) ...{'b' : 2}, 'c' : 3};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Map<String, int>
  entries
    entry
      key: String a
      value: int 1
    entry
      key: String b
      value: int 2
    entry
      key: String c
      value: int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_mapLiteral_spreadElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {'a' : 1, ...{'b' : 2, 'c' : 3}, 'd' : 4};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Map<String, int>
  entries
    entry
      key: String a
      value: int 1
    entry
      key: String b
      value: int 2
    entry
      key: String c
      value: int 3
    entry
      key: String d
      value: int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_setLiteral_ifElement_false_withElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {1, if (1 < 0) 2 else 3, 4};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Set<int>
  elements
    int 1
    int 3
    int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_setLiteral_ifElement_false_withoutElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {1, if (1 < 0) 2, 3};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Set<int>
  elements
    int 1
    int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_setLiteral_ifElement_true_withElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {1, if (1 > 0) 2 else 3, 4};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Set<int>
  elements
    int 1
    int 2
    int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_setLiteral_ifElement_true_withoutElse() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {1, if (1 > 0) 2, 3};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Set<int>
  elements
    int 1
    int 2
    int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_setLiteral_nested() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {1, if (1 > 0) if (2 > 1) 2, 3};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Set<int>
  elements
    int 1
    int 2
    int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_setLiteral_spreadElement() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = {1, ...{2, 3}, 4};
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Set<int>
  elements
    int 1
    int 2
    int 3
    int 4
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitAdjacentInterpolation_simple() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 'abc' 'def';
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
String abcdef
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitAsExpression_instanceOfSameClass() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = const A();
const b = a as A;
//        ^^^^^^
// [diag.unnecessaryCast] Unnecessary cast.
class A {
  const A();
}
''');

    var resultA = _topLevelVar(result, 'a');
    assertDartObjectText(resultA, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');

    var resultB = _topLevelVar(result, 'b');
    assertDartObjectText(resultB, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::b
''');

    expect(resultB, resultA);
  }

  test_visitAsExpression_instanceOfSubclass() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = const B();
const b = a as A;
class A {
  const A();
}
class B extends A {
  const B();
}
''');

    var resultA = _topLevelVar(result, 'a');
    assertDartObjectText(resultA, r'''
B
  (super): A
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');

    var resultB = _topLevelVar(result, 'b');
    assertDartObjectText(resultB, r'''
B
  (super): A
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
  variable: <testLibrary>::@topLevelVariable::b
''');

    expect(resultB, resultA);
  }

  test_visitAsExpression_instanceOfSuperclass() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = const A();
const b = a as B;
//        ^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitAsExpression_instanceOfUnrelatedClass() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = const A();
const b = a as B;
//        ^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
class A {
  const A();
}
class B {
  const B();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitAsExpression_potentialConst() async {
    await resolveTestCodeWithDiagnostics('''
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
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 2.3 + 3.2;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
double 5.5
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_add_instance_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  const C();
  String operator +(String other) => other;
}

const c = C() + 1;
//        ^^^^^^^
// [diag.constEvalTypeNumString] In constant expressions, operands of this operator must be of type 'num' or 'String'.
//              ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
''');
  }

  test_visitBinaryExpression_add_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 2 + 3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 5
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_add_string_string() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 'a' + 'b';
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
String ab
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_bool_bool() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = true && false;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_bool_false_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = false;
const c = false && a;
//              ^^^^
// [diag.deadCode] Dead code.
//                 ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_and_bool_invalid_false() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = false;
const c = a && false;
//        ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_and_bool_invalid_true() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = false;
const c = a && true;
//        ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_and_bool_known_known() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = false & true;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_bool_known_unknown() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const b = bool.fromEnvironment('y');
const c = false & b;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_bool_true_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = false;
const c = true && a;
//        ^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_and_bool_unknown_known() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('x');
const c = a & true;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_bool_unknown_unknown() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('x');
const b = bool.fromEnvironment('y');
const c = a & b;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 74 & 42;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 10
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_and_mixed() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = 3 & false;
//        ^^^^^^^^^
// [diag.constEvalTypeBoolInt] In constant expressions, operands of this operator must be of type 'bool' or 'int'.
//            ^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'bool' can't be assigned to the parameter type 'int'.
''');
  }

  test_visitBinaryExpression_divide_double_double() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3.2 / 2.3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
double 1.3913043478260871
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_divide_double_double_byZero() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3.2 / 0.0;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
double Infinity
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_divide_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3 / 2;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
double 1.5
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_divide_int_int_byZero() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3 / 0;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
double Infinity
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_eqeq_double_double_nan_left() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = double.nan == 2.3;
//        ^^^^^^^^^^^^^
// [diag.unnecessaryNanComparisonFalse] A double can't equal 'double.nan', so the condition is always 'false'.
''');
    // This test case produces a warning, but the value of the constant should
    // be `false`.
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_eqeq_double_double_nan_right() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = 2.3 == double.nan;
//            ^^^^^^^^^^^^^
// [diag.unnecessaryNanComparisonFalse] A double can't equal 'double.nan', so the condition is always 'false'.
''');
    // This test case produces a warning, but the value of the constant should
    // be `false`.
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_minus_double_double() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3.2 - 2.3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
double 0.9000000000000004
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_minus_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3 - 2;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 1
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_notEqual_bool_bool() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = true != false;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_notEqual_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 2 != 3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_notEqual_invalidLeft() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = a != 3;
//        ^
// [diag.undefinedIdentifier] Undefined name 'a'.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_notEqual_invalidRight() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = 2 != a;
//             ^
// [diag.undefinedIdentifier] Undefined name 'a'.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_notEqual_string_string() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 'a' != 'b';
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_bool_false_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = false;
const c = false || a;
//        ^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_or_bool_invalid_false() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = false;
const c = a || false;
//        ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_or_bool_invalid_true() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = false;
const c = a || true;
//        ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_or_bool_known_known() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = false | true;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_bool_known_unknown() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const b = bool.fromEnvironment('y');
const c = false | b;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_bool_true_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = false;
const c = true || a;
//             ^^^^
// [diag.deadCode] Dead code.
//                ^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitBinaryExpression_or_bool_unknown_known() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('x');
const c = a | true;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_bool_unknown_unknown() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('x');
const b = bool.fromEnvironment('y');
const c = a | b;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3 | 5;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 7
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_known_known() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = true || false;
//             ^^^^^^^^
// [diag.deadCode] Dead code.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_or_mixed() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = 3 | false;
//        ^^^^^^^^^
// [diag.constEvalTypeBoolInt] In constant expressions, operands of this operator must be of type 'bool' or 'int'.
//            ^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'bool' can't be assigned to the parameter type 'int'.
''');
  }

  test_visitBinaryExpression_questionQuestion_notNull_notNull() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 'a' ?? 'b';
//            ^^^^^^
// [diag.deadCode] Dead code.
//               ^^^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
String a
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_questionQuestion_null_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = null ?? new C();
//                ^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
class C {}
''');
  }

  test_visitBinaryExpression_questionQuestion_null_notNull() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = null ?? 'b';
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
String b
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_questionQuestion_null_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = null ?? null;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_xor_bool_known_known() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = false ^ true;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_xor_bool_known_unknown() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const b = bool.fromEnvironment('y');
const c = false ^ b;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_xor_bool_unknown_known() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('x');
const c = a ^ true;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_xor_bool_unknown_unknown() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('x');
const b = bool.fromEnvironment('y');
const c = a ^ b;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_xor_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3 ^ 5;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 6
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBinaryExpression_xor_mixed() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = 3 ^ false;
//        ^^^^^^^^^
// [diag.constEvalTypeBoolInt] In constant expressions, operands of this operator must be of type 'bool' or 'int'.
//            ^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'bool' can't be assigned to the parameter type 'int'.
''');
  }

  test_visitBoolLiteral_false() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = false;
''');
    var result = _topLevelVar(unitResult, 'c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitBoolLiteral_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = true;
''');
    var result = _topLevelVar(unitResult, 'c');
    dartObjectPrinterConfiguration.withHexIntegers = true;
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_eager_false_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = false ? 1 : 0;
//                ^
// [diag.deadCode] Dead code.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_eager_true_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = true ? 1 : 0;
//                   ^
// [diag.deadCode] Dead code.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 1
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_eager_true_int_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = true ? 1 : x;
//                   ^
// [diag.undefinedIdentifier] Undefined name 'x'.
// [diag.deadCode] Dead code.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitConditionalExpression_eager_true_invalid_int() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = true ? x : 0;
//               ^
// [diag.undefinedIdentifier] Undefined name 'x'.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                   ^
// [diag.deadCode] Dead code.
''');
  }

  test_visitConditionalExpression_lazy_false_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = false ? 1 : 0;
//                ^
// [diag.deadCode] Dead code.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 0
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_lazy_false_int_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = false ? 1 : new C();
//                ^
// [diag.deadCode] Dead code.
//                    ^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                        ^
// [diag.newWithNonType] The name 'C' isn't a class.
''');
  }

  test_visitConditionalExpression_lazy_false_invalid_int() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = false ? new C() : 0;
//                ^^^^^^^
// [diag.deadCode] Dead code.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                    ^
// [diag.newWithNonType] The name 'C' isn't a class.
''');
  }

  test_visitConditionalExpression_lazy_invalid_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = 3 ? 1 : 0;
//        ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
// [diag.constEvalTypeBool] In constant expressions, operands of this operator must be of type 'bool'.
''');
  }

  test_visitConditionalExpression_lazy_true_int_int() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = true ? 1 : 0;
//                   ^
// [diag.deadCode] Dead code.
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 1
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitConditionalExpression_lazy_true_int_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = true ? 1: new C();
//                  ^^^^^^^
// [diag.deadCode] Dead code.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                      ^
// [diag.newWithNonType] The name 'C' isn't a class.
''');
  }

  test_visitConditionalExpression_lazy_true_invalid_int() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = true ? new C() : 0;
//               ^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
//                         ^
// [diag.deadCode] Dead code.
class C {}
''');
  }

  test_visitConditionalExpression_lazy_unknown_int_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = identical(0, 0.0) ? 1 : new Object();
//                                ^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitConditionalExpression_lazy_unknown_invalid_int() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = identical(0, 0.0) ? 1 : new Object();
//                                ^^^^^^^^^^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitDoubleLiteral() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3.45;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
double 3.45
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitIntegerLiteral_doubleType() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const double d = 3;
''');
    var result = _topLevelVar(unitResult, 'd');
    assertDartObjectText(result, r'''
double 3.0
  variable: <testLibrary>::@topLevelVariable::d
''');
  }

  test_visitIntegerLiteral_integer() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = 3;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitIsExpression_is_functionType_badTypes() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void foo(int a) {}
const c = foo is void Function(String);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitIsExpression_is_functionType_nonFunction() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = false is void Function();
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitIsExpression_is_instanceOfSuperclass() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = const A();
const b = a is B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_instanceOfUnrelatedClass() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = const A();
const b = a is B;
class A {
  const A();
}
class B {
  const B();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool false
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null_dynamic() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = null;
const b = a is dynamic;
//        ^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
class A {}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_is_null_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = null;
const b = a is Null;
//        ^^^^^^^^^
// [diag.typeCheckIsNull] Tests for null should be done with '== null'.
class A {}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfSuperclass() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = const A();
const b = a is! B;
class A {
  const A();
}
class B extends A {
  const B();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitIsExpression_isNot_instanceOfUnrelatedClass() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = const A();
const b = a is! B;
class A {
  const A();
}
class B {
  const B();
}
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitNullLiteral_null() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const c = null;
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
Null null
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitParenthesizedExpression_string() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = ('a');
''');
    var result = _topLevelVar(unitResult, 'a');
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

    var unitResult = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as prefix;

const x = prefix.E.v;
''');

    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
int 42
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_visitPropertyAccess_length_extension() async {
    await resolveTestCodeWithDiagnostics('''
extension ExtObject on Object {
  int get length => 4;
}

class B {
  final l;
  const B(Object o) : l = o.length;
//                        ^^^^^^^^
// [context 1] The error is in the field initializer of 'B', and occurs here.
}

const b = B('');
//        ^^^^^
// [diag.constEvalExtensionMethod][context 1] Extension methods can't be used in constant expressions.
''');
  }

  test_visitPropertyAccess_length_extensionType() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
extension type const A(String it) {
  int get length => 0;
}

const v1 = A('');
const v2 = v1.length;
//         ^^^^^^^^^
// [diag.constEvalExtensionTypeMethod] Extension type methods can't be used in constant expressions.
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_visitPropertyAccess_length_extensionType_implementsString() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
extension type const A(String it) implements String {}

const v1 = A('abc');
const v2 = v1.length;
''');
    var result = _topLevelVar(unitResult, 'v2');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::v2
''');
  }

  test_visitPropertyAccess_length_unresolvedType() async {
    await resolveTestCodeWithDiagnostics('''
class B {
  final l;
  const B(String o) : l = o.length;
//                        ^^^^^^^^
// [context 1] The error is in the field initializer of 'B', and occurs here.
}

const y = B(x);
//        ^^^^
// [diag.constEvalTypeString][context 1] In constant expressions, operands of this operator must be of type 'String'.
//          ^
// [diag.undefinedIdentifier] Undefined name 'x'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
''');
  }

  test_visitSimpleIdentifier_dynamic() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = dynamic;
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
Type
  toTypeValue: dynamic
  toTypeValueNotExtensionTypeErased: dynamic
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitSimpleIdentifier_variable() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = 42;
const b = a;
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
int 42
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_visitSimpleIdentifier_wildcard_local() async {
    await resolveTestCodeWithDiagnostics(r'''
test() {
  const _ = true;
  const c = _;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//          ^
// [diag.undefinedIdentifier] Undefined name '_'.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
}
''');
  }

  test_visitSimpleIdentifier_wildcard_top() async {
    await resolveTestCodeWithDiagnostics(r'''
const _ = true;
const c = _;
''');
  }

  test_visitSimpleIdentifier_withoutEnvironment() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const a = b;
const b = 3;''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
int 3
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_visitSimpleStringLiteral_valid() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = 'abc';
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
String abc
  variable: <testLibrary>::@topLevelVariable::c
''');
  }

  test_visitStringInterpolation_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = 'a${f()}c';
//            ^
// [diag.undefinedFunction] The function 'f' isn't defined.
//            ^^^
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_visitStringInterpolation_valid() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
const c = 'a${3}c';
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
String a3c
  variable: <testLibrary>::@topLevelVariable::c
''');
  }
}

class ConstantVisitorTestSupport extends PubPackageResolutionTest {
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

  DartObjectImpl? _field(TestResolvedUnitResult result, String variableName) {
    var element = result.findElement.field(variableName);
    return _evaluationResult(element as VariableElementImpl);
  }

  DartObjectImpl? _localVar(
    TestResolvedUnitResult result,
    String variableName,
  ) {
    var element = result.findElement.localVar(variableName);
    return _evaluationResult(element as VariableElementImpl);
  }

  DartObjectImpl? _topLevelVar(
    TestResolvedUnitResult result,
    String variableName,
  ) {
    var element = result.findElement.topVar(variableName);
    return _evaluationResult(element as VariableElementImpl);
  }
}

@reflectiveTest
class InstanceCreationEvaluatorTest extends ConstantVisitorTestSupport {
  test_assertInitializer_assertIsNot_false() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  const A() : assert(0 is! int);
//            ^^^^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
//                   ^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
}

const a = const A(null);
//        ^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
//                ^^^^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
''');
  }

  test_assertInitializer_assertIsNot_null_nullableType() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  const A() : assert(null is! T);
//            ^^^^^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}

const a = const A<int?>();
//        ^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_assertInitializer_assertIsNot_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A() : assert(0 is! String);
}

const a = const A();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_assertInitializer_class_privateNamedParameters_false() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  final int _x;
//          ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  const A({required this._x}) : assert(_x > 0);
//                              ^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
const a = A(x: 0);
//        ^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_assertInitializer_class_privateNamedParameters_multiple() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int _x;
//          ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  final int _y;
//          ^^
// [diag.unusedField] The value of the field '_y' isn't used.
  const A({required this._x, required this._y}) : assert(_x < _y);
}
const a = A(x: 1, y: 2);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  _x: int 1
  _y: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    namedArguments
      x: int 1
      y: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_assertInitializer_class_privateNamedParameters_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int _x;
//          ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  const A({required this._x}) : assert(_x > 0);
}
const a = A(x: 1);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  _x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    namedArguments
      x: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_assertInitializer_enum_false() async {
    await resolveTestCodeWithDiagnostics('''
enum E { a, b }
class A {
  const A(E e) : assert(e != E.a);
//               ^^^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
const c = const A(E.a);
//        ^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_assertInitializer_enum_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
enum E { a, b }
class A {
  const A(E e) : assert(e != E.a);
}
const c = const A(E.b);
''');
    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int i)
  : assert(i == 1); // (2)
//  ^^^^^^^^^^^^^^
// [context 2] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
class B extends A {
  const B(int i) : super(i);
//      ^
// [context 1] The evaluated constructor 'A' is called by 'B' and 'B' is defined here.
}
main() {
  print(const B(2)); // (1)
//      ^^^^^^^^^^
// [diag.constEvalThrowsException][context 1][context 2] Evaluation of this constant expression throws an exception.
}
''');
  }

  test_assertInitializer_intInDoubleContext_assertIsDouble_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(double x): assert(x is double);
//                          ^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
const a = const A(0);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: double 0.0
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_assertInitializer_intInDoubleContext_false() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  const A(double x): assert((x + 3) / 2 == 1.5);
//                   ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
const a = const A(1);
//        ^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_assertInitializer_intInDoubleContext_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A(double x): assert((x + 3) / 2 == 1.5);
}
const v = const A(0);
''');
    var result = _topLevelVar(unitResult, 'v');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: double 0.0
  variable: <testLibrary>::@topLevelVariable::v
''');
  }

  test_assertInitializer_simple_false() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  const A(): assert(1 is String);
//           ^^^^^^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
const a = const A();
//        ^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_assertInitializer_simple_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(): assert(1 is int);
//                  ^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
const a = const A();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_assertInitializer_simpleInSuperInitializer_false() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  const A(): assert(1 is String);
//           ^^^^^^^^^^^^^^^^^^^
// [context 2] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
class B extends A {
  const B() : super();
//      ^
// [context 1] The evaluated constructor 'A' is called by 'B' and 'B' is defined here.
}
const b = const B();
//        ^^^^^^^^^
// [diag.constEvalThrowsException][context 1][context 2] Evaluation of this constant expression throws an exception.
''');
  }

  test_assertInitializer_simpleInSuperInitializer_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(): assert(1 is int);
//                  ^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
class B extends A {
  const B() : super();
}
const b = const B();
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
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
    await resolveTestCodeWithDiagnostics('''
class A {
  const A(int x): assert(x > 0);
//                ^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
const a = const A(0);
//        ^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_assertInitializer_usingArgument_false_withMessage() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int x): assert(x > 0, '$x must be greater than 0');
//                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [context 1] The exception is 'An assertion failed with message '0 must be greater than 0'.' and occurs here.
}
const a = const A(0);
//        ^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_assertInitializer_usingArgument_false_withMessage_cannotCompute() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int x): assert(x > 0, '${throw ''}');
//                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
//                                 ^^^^^^^^
// [diag.invalidConstant] Invalid constant value.
// [diag.constConstructorThrowsException] Const constructors can't throw exceptions.
//                                          ^^^
// [diag.deadCode] Dead code.
}
const a = const A(0);
//        ^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_assertInitializer_usingArgument_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A(int x): assert(x > 0);
}
const a = const A(1);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_bool_fromEnvironment() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('a');
const b = bool.fromEnvironment('b', defaultValue: true);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/50045
  test_bool_fromEnvironment_dartLibraryJsInterop() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_interop');
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/50045
  test_bool_fromEnvironment_dartLibraryJsUtil() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_list_eqeq_known() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = [3, if (a) ...[1] else ...[1, 2], 4];
const left = [3, 1, 2, 4] == b;
const right = b == [3, 1, 2, 4];
''');
    var leftResult = _topLevelVar(result, 'left');
    assertDartObjectText(leftResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar(result, 'right');
    assertDartObjectText(rightResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_list_eqeq_unknown() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = [3, if (a) ...[1] else ...[1, 2], 4];
const left = [3, if (a) ...[1] else ...[1, 2], 4] == b;
const right = b == [3, if (a) ...[1] else ...[1, 2], 4];
''');
    var leftResult = _topLevelVar(result, 'left');
    assertDartObjectText(leftResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar(result, 'right');
    assertDartObjectText(rightResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_map() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const x = {3:'3', if (a) 1:'1' else 2:'2', 4:'4'};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<unknown> Map<int, String>
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_map_eqeq_known() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = {3:'3', if (a) 1:'1' else 2:'2', 4:'4'};
const left = {3:'3', 2:'2', 4:'4'} == b;
const right = b == {3:'3', 2:'2', 4:'4'};
''');
    var leftResult = _topLevelVar(result, 'left');
    assertDartObjectText(leftResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar(result, 'right');
    assertDartObjectText(rightResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_map_eqeq_unknown() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = {3:'3', if (a) 1:'1' else 2:'2', 4:'4'};
const left = {3:'3', if (a) 1:'1' else 2:'2', 4:'4'} == b;
const right = b == {3:'3', if (a) 1:'1' else 2:'2', 4:'4'};
''');
    var leftResult = _topLevelVar(result, 'left');
    assertDartObjectText(leftResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar(result, 'right');
    assertDartObjectText(rightResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_nonConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = bool.fromEnvironment('dart.library.js_util');
var b = 7;
var x = const A([if (a) b]);
//                      ^
// [diag.nonConstantListElement] The values in a const list literal must be constants.

class A {
  const A(List<int> p);
}
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_set() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const x = {3, if (a) ...[1] else ...[1, 2], 4};
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<unknown> Set<int>
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_set_eqeq_known() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = {3, if (a) ...[1] else ...[1, 2], 4};
const left = {3, 1, 4} == b;
const right = b == {3, 1, 4};
''');
    var leftResult = _topLevelVar(result, 'left');
    assertDartObjectText(leftResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar(result, 'right');
    assertDartObjectText(rightResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElement_set_eqeq_unknown() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const b = {3, if (a) ...[1] else ...[1, 2], 4};
const left = {3, if (a) ...[1] else ...[1, 2], 4} == b;
const right = b == {3, if (a) ...[1] else ...[1, 2], 4};
''');
    var leftResult = _topLevelVar(result, 'left');
    assertDartObjectText(leftResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::left
''');
    var rightResult = _topLevelVar(result, 'right');
    assertDartObjectText(rightResult, r'''
<unknown> bool
  variable: <testLibrary>::@topLevelVariable::right
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifElementElse_nonConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = bool.fromEnvironment('dart.library.js_util');
var b = 7;
var x = const A([if (a) 3 else b]);
//                             ^
// [diag.nonConstantListElement] The values in a const list literal must be constants.

class A {
  const A(List<int> p);
}
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_ifStatement_list() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('dart.library.js_util');
const x = [3, if (a) ...[1] else ...[1, 2], 4];
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
<unknown> List<int>
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_bool_fromEnvironment_dartLibraryJsUtil_recordField_nonConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = bool.fromEnvironment('dart.library.js_util');
var b = 7;
var x = const A((b, ));
//               ^
// [diag.invalidConstant] Invalid constant value.

class A {
  const A((int, ) p);
}
''');
  }

  test_bool_fromEnvironment_declaredVariables() async {
    declaredVariables = {'a': 'true', 'b': 'bbb'};

    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.fromEnvironment('a');
const b = bool.fromEnvironment('b', defaultValue: true);
''');

    assertDartObjectText(_topLevelVar(result, 'a'), r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');

    var bResult = _topLevelVar(result, 'b');
    assertDartObjectText(bResult, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_bool_hasEnvironment() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.hasEnvironment('a');
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_bool_hasEnvironment_declaredVariables() async {
    declaredVariables = {'a': '42'};

    var result = await resolveTestCodeWithDiagnostics('''
const a = bool.hasEnvironment('a');
''');

    assertDartObjectText(_topLevelVar(result, 'a'), r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_constructor_duplicateInitialization_fieldInitializer_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x = 1;
  const A() : x = 2;
//            ^
// [diag.fieldInitializedInInitializerAndDeclaration] Fields can't be initialized in the constructor if they are final and were already initialized at their declaration.
}

const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_constructor_duplicateInitialization_fieldInitializer_initializingFormal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x = 1;
  const A(this.x);
//             ^
// [diag.finalInitializedInDeclarationAndConstructor] 'x' is final and was given a value when it was declared, so it can't be set to a new value.
}

const a = A(2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_constructor_duplicateInitialization_initializer_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A() : x = 1, x = 2;
//                   ^
// [diag.fieldInitializedByMultipleInitializers] The field 'x' can't be initialized twice in the same constructor.
}

const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_constructor_duplicateInitialization_initializingFormal_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A(this.x) : x = 1;
//                  ^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
}

const a = A(2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_field_declarationInitializer_nonConstant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int x = 0;
class A {
  final int f = x;
//              ^
// [diag.invalidConstant] Invalid constant value.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
  const A();
//^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'f' is initialized with a non-constant value.
}
const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
<null>
''');
  }

  test_class_field_declarationInitializer_thisReference_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x = 0;
  final int f = x;
//              ^
// [diag.invalidConstant] Invalid constant value.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
// [diag.implicitThisReferenceInInitializer] The instance member 'x' can't be accessed in an initializer.
  const A();
//^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'f' is initialized with a non-constant value.
}
const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
<null>
''');
  }

  test_class_field_declarationInitializer_thisReference_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  final int f = x;
//              ^
// [diag.invalidConstant] Invalid constant value.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
// [diag.implicitThisReferenceInInitializer] The instance member 'x' can't be accessed in an initializer.
  const A();
//^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'f' is initialized with a non-constant value.
}
const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
<null>
''');
  }

  test_class_primaryConstructor_assert_false() async {
    await resolveTestCodeWithDiagnostics(r'''
class const A(int x) {
  this : assert(x > 0);
//       ^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
const a = A(0);
//        ^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_class_primaryConstructor_assert_true() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(int x) {
  this : assert(x > 0);
}
const a = A(1);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_constructorFieldInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(int x) {
  final int y;
  this : y = x + 1;
}
const a = A(1);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  y: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_duplicateDefinition_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(final int x) {
//                      ^
// [context 1] The first definition of this name.
  final int x = 1;
//          ^
// [diag.duplicateDefinition][context 1] The name 'x' is already defined.
}

const a = A(2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_duplicateInitialization_fieldInitializer_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A() {
  final int x = 1;
  this : x = 2;
//       ^
// [diag.fieldInitializedInDeclarationAndInitializerOfPrimaryConstructor] Fields can't be initialized in both the primary constructor and at their declaration.
}

const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_duplicateInitialization_fieldInitializer_initializingFormal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(this.x) {
//                 ^
// [diag.fieldInitializedInDeclarationAndParameterOfPrimaryConstructor] Fields can't be initialized in both the primary constructor parameter list and at their declaration.
  final int x = 1;
}

const a = A(2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_duplicateInitialization_initializer_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A() {
  final int x;
  this : x = 1, x = 2;
//              ^
// [diag.fieldInitializedByMultipleInitializers] The field 'x' can't be initialized twice in the same constructor.
}

const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_duplicateInitialization_initializingFormal_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(this.x) {
//            ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.
  this : x = 2;
//       ^^^^^
// [diag.initializerForNonExistentField] 'x' isn't a field in the enclosing class.
}

const a = A(1);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_fieldInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(int x) {
  final int y = x + 1;
}
const a = A(1);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  y: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_fieldInitializer_functionExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class const A(int x) {
//    ^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'foo' is initialized with a non-constant value.
  final int Function() foo = () => x;
}
''');
  }

  test_class_primaryConstructor_fieldInitializer_multipleInvocations() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(int x) {
  final int y = x + 1;
}
const a = A(1);
const b = A(2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  y: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
A
  y: int 3
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_class_primaryConstructor_fieldInitializer_topLevel_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const x = 1;
class const A() {
  final int y = x + 2;
}
const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  y: int 3
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_fieldInitializer_topLevel_final() async {
    await resolveTestCodeWithDiagnostics(r'''
final x = 1;
class const A() {
//    ^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'y' is initialized with a non-constant value.
  final int y = x + 2;
//              ^
// [diag.invalidConstant] Invalid constant value.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
}
const a = A();
''');
  }

  test_class_primaryConstructor_fieldInitializer_topLevel_final_noInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
final x = 1;
class const A(int p) {
//    ^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'y' is initialized with a non-constant value.
  final int y = x + p;
}
''');
  }

  test_class_primaryConstructor_formalParameter_declaring_optionalNamed_noArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A({final int x = 1});
const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_declaring_optionalNamed_withArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A({final int x = 1});
const a = A(x: 2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    namedArguments
      x: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_declaring_optionalPositional_noArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A([final int x = 1]);
const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_declaring_optionalPositional_withArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A([final int x = 1]);
const a = A(2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_declaring_requiredNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A({required final int x});
const a = A(x: 1);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    namedArguments
      x: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_declaring_requiredPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(final int x);
const a = A(1);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_initializing_optionalNamed_noArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A({this.x = 1}) {
  final int x;
}
const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_initializing_optionalNamed_withArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A({this.x = 1}) {
  final int x;
}
const a = A(x: 2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    namedArguments
      x: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_initializing_optionalPositional_noArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A([this.x = 1]) {
  final int x;
}
const a = A();
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_initializing_optionalPositional_withArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A([this.x = 1]) {
  final int x;
}
const a = A(2);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_initializing_requiredNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A({required this.x}) {
  final int x;
}
const a = A(x: 1);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    namedArguments
      x: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_initializing_requiredNamed_generic_inferred() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A<T>({required this.f}) {
  final T f;
}

const x = A(f: 0);
''');
    assertDartObjectText(_topLevelVar(result, 'x'), r'''
A<int>
  f: int 0
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    namedArguments
      f: int 0
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_class_primaryConstructor_formalParameter_initializing_requiredPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(this.x) {
  final int x;
}
const a = A(1);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_formalParameter_initializing_requiredPositional_generic_explicit() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A<T>(this.f) {
  final T f;
}

const x = A<int>(0);
''');
    assertDartObjectText(_topLevelVar(result, 'x'), r'''
A<int>
  f: int 0
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 0
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_class_primaryConstructor_formalParameter_normal_usedInSuperInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A(this.x);
}
class const B(int y) extends A {
  this : super(y + 1);
}
const b = B(1);
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
B
  (super): A
    x: int 2
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_class_primaryConstructor_formalParameter_super_optionalNamed_noArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A({this.x = 1});
}
class const B({super.x}) extends A;
const b = B();
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
B
  (super): A
    x: int 1
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      namedArguments
        x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_class_primaryConstructor_formalParameter_super_optionalNamed_withArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A({this.x = 1});
}
class const B({super.x}) extends A;
const b = B(x: 2);
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
B
  (super): A
    x: int 2
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      namedArguments
        x: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    namedArguments
      x: int 2
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_class_primaryConstructor_formalParameter_super_optionalPositional_noArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A([this.x = 1]);
}
class const B([super.x]) extends A;
const b = B();
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
B
  (super): A
    x: int 1
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_class_primaryConstructor_formalParameter_super_optionalPositional_withArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A([this.x = 1]);
}
class const B([super.x]) extends A;
const b = B(2);
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
B
  (super): A
    x: int 2
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 2
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_class_primaryConstructor_formalParameter_super_requiredNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A({required this.x});
}
class const B({required super.x}) extends A;
const b = B(x: 1);
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
B
  (super): A
    x: int 1
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      namedArguments
        x: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    namedArguments
      x: int 1
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_class_primaryConstructor_formalParameter_super_requiredPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A(this.x);
}
class const B(super.x) extends A;
const b = B(1);
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
B
  (super): A
    x: int 1
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_class_primaryConstructor_initializer_assert_nonConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
int x = 1;
class const A() {
  this : assert(x > 0);
//              ^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_class_primaryConstructor_initializer_field_nonConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
int x = 1;
class const A() {
  final int f;
  this : f = x;
//           ^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_class_primaryConstructor_initializer_super_nonConstantArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
int x = 1;
class A {
  const A(int a);
}
class const B() extends A {
  this : super(x);
//             ^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_class_primaryConstructor_redirect_fieldInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(int x) {
  final int y = x + 1;
  const A.named(int z) : this(z * 2);
}
const a = A.named(10);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  y: int 21
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::named
    positionalArguments
      0: int 10
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_redirect_fieldInitializer_nonRedirectingSecondary() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class const A(int x) {
  final int y = x + 1;
  const A.named(int z) : this(z * 2);
  const A.other() {}
//      ^^^^^^^
// [diag.nonRedirectingGenerativeConstructorWithPrimary] Classes with primary constructors can't have non-redirecting generative constructors.
//                ^
// [diag.constConstructorWithBody] Const constructors can't have a body.
}
const a = A.named(10);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
A
  y: int 21
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::named
    positionalArguments
      0: int 10
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_class_primaryConstructor_superParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  const A(this.x);
}
class const B(super.x) extends A;
const b = B(1);
''');
    assertDartObjectText(_topLevelVar(result, 'b'), r'''
B
  (super): A
    x: int 1
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_dotShorthand_assertInitializer_assertIsNot_false() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  const A() : assert(0 is! int);
//            ^^^^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
//                   ^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
}

const A a = .new();
//          ^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_dotShorthand_assertInitializer_assertIsNot_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A() : assert(0 is! String);
}

const A a = .new();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_dotShorthand_assertInitializer_enum_false() async {
    await resolveTestCodeWithDiagnostics('''
enum E { a, b }
class A {
  const A(E e) : assert(e != .a);
//               ^^^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
const A a = .new(.a);
//          ^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_dotShorthand_assertInitializer_enum_true() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
enum E { a, b }
class A {
  const A(E e) : assert(e != .a);
}
const A a = .new(.b);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
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
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(): assert(1 is int);
//                  ^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
class B extends A {
  const B() : super();
}
const B b = .new();
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
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
    var result = await resolveTestCodeWithDiagnostics('''
const bool a = .fromEnvironment('a');
const bool b = .fromEnvironment('b', defaultValue: true);
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_dotShorthand_bool_fromEnvironment_declaredVariables() async {
    declaredVariables = {'a': 'true', 'b': 'bbb'};

    var result = await resolveTestCodeWithDiagnostics('''
const bool a = .fromEnvironment('a');
const bool b = .fromEnvironment('b', defaultValue: true);
''');

    assertDartObjectText(_topLevelVar(result, 'a'), r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');

    var bResult = _topLevelVar(result, 'b');
    assertDartObjectText(bResult, r'''
bool true
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_dotShorthand_bool_hasEnvironment() async {
    var result = await resolveTestCodeWithDiagnostics('''
const bool a = .hasEnvironment('a');
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
bool false
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_dotShorthand_bool_hasEnvironment_declaredVariables() async {
    declaredVariables = {'a': '42'};

    var result = await resolveTestCodeWithDiagnostics('''
const bool a = .hasEnvironment('a');
''');

    assertDartObjectText(_topLevelVar(result, 'a'), r'''
bool true
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_dotShorthand_constantArgument_issue60963() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const A();
}
extension type const B(A a) {}

const B b = .new(A());
''');
    var result = _topLevelVar(unitResult, 'b');
    assertDartObjectText(result, r'''
A
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
  variable: <testLibrary>::@topLevelVariable::b
  typeNotExtensionTypeErased: B
''');
  }

  test_dotShorthand_constructor_import_namedParameter() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  final int one;
  const C({this.one = 1});
}
''');
    var unitResult = await resolveTestCodeWithDiagnostics('''
import 'a.dart';
const C c = .new();
''');

    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
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
    var unitResult = await resolveTestCodeWithDiagnostics('''
import 'a.dart';
const C c = .new(1);
''');

    var result = _topLevelVar(unitResult, 'c');
    assertDartObjectText(result, r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
const C c = .new();
//           ^^^
// [diag.missingRequiredArgument] The named parameter 'one' is required, but there's no corresponding argument.
''');
  }

  test_dotShorthand_nonConstantArgument_issue60963() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int cannotBeConst;
  A(): cannotBeConst = 0;
}
extension type const B(A a) {}

const B b = .new(A());
//               ^^^
// [diag.constWithNonConst] The constructor being called isn't a const constructor.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_enum_constructor_duplicateInitialization_fieldInitializer_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int x = 1;
  const E() : x = 2;
//            ^
// [diag.fieldInitializedInInitializerAndDeclaration] Fields can't be initialized in the constructor if they are final and were already initialized at their declaration.
}

const a = E.v;
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
E
  _name: String v
  index: int 0
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_enum_constructor_duplicateInitialization_fieldInitializer_initializingFormal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(2);
  final int x = 1;
  const E(this.x);
//             ^
// [diag.finalInitializedInDeclarationAndConstructor] 'x' is final and was given a value when it was declared, so it can't be set to a new value.
}

const a = E.v;
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
E
  _name: String v
  index: int 0
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_enum_constructor_duplicateInitialization_initializer_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int x;
  const E() : x = 1, x = 2;
//                   ^
// [diag.fieldInitializedByMultipleInitializers] The field 'x' can't be initialized twice in the same constructor.
}

const a = E.v;
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
E
  _name: String v
  index: int 0
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_enum_constructor_duplicateInitialization_initializingFormal_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(1);
  final int x;
  const E(this.x) : x = 2;
//                  ^
// [diag.fieldInitializedInParameterAndInitializer] Fields can't be initialized in both the parameter list and the initializers.
}

const a = E.v;
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
E
  _name: String v
  index: int 0
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
    positionalArguments
      0: int 1
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_enum_primaryConstructor_duplicateDefinition_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E(final int x) {
//               ^
// [context 1] The first definition of this name.
  v(2);

  final int x = 1;
//          ^
// [diag.duplicateDefinition][context 1] The name 'x' is already defined.
}

const a = E.v;
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
E
  _name: String v
  index: int 0
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
    positionalArguments
      0: int 2
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_enum_primaryConstructor_duplicateInitialization_initializer_initializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  final int x;
  this : x = 1, x = 2;
//              ^
// [diag.fieldInitializedByMultipleInitializers] The field 'x' can't be initialized twice in the same constructor.
}

const a = E.v;
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
E
  _name: String v
  index: int 0
  x: int 2
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_enum_primaryConstructor_fieldInitializer_functionExpression_explicitConst() async {
    await resolveTestCodeWithDiagnostics(r'''
enum const E(int x) {
//   ^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'foo' is initialized with a non-constant value.
  v(0);

  final int Function() foo = () => x;
}
''');
  }

  test_enum_primaryConstructor_fieldInitializer_functionExpression_implicitConst() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(int x) {
//   ^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'foo' is initialized with a non-constant value.
  v(0);

  final int Function() foo = () => x;
}
''');
  }

  test_field_deferred_issue48991() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  const A();
}

const aa = A();
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' deferred as a;

class B {
  const B(Object a);
}

main() {
  print(const B(a.aa));
//                ^^
// [diag.constConstructorConstantFromDeferredLibrary] Constant values from a deferred library can't be used as values in a 'const' constructor.
}
''');
  }

  test_field_imported_staticConst() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static const A instance = const A();
  const A();
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
class B {
  final A v;
  const B(this.v);
}
B f1() => const B(A.instance);
''');
  }

  test_fieldInitializer_functionReference_withTypeParameter() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
void g<U>(U a) {}
class A<T> {
  final void Function(T) f;
  const A(): f = g;
}
const a = const A<int>();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A<int>
  f: void Function(int)
    element: <testLibrary>::@function::g
    typeArguments
      T
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_fieldInitializer_typeParameter() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A<T> {
  final Object f;
  const A(): f = T;
}
const a = const A<int>();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A<int>
  f: Type
    toTypeValue: int
    toTypeValueNotExtensionTypeErased: int
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_fieldInitializer_typeParameter_implicitTypeArgs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A<T> {
  final Object f;
  const A(): f = T;
}
const a = const A();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A<dynamic>
  f: Type
    toTypeValue: dynamic
    toTypeValueNotExtensionTypeErased: dynamic
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: dynamic}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_fieldInitializer_typeParameter_typeAlias() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A<T, U> {
  final Object f, g;
  const A(): f = T, g = U;
}
typedef B<S> = A<int, S>;
const a = const B<String>();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A<int, String>
  f: Type
    toTypeValue: int
    toTypeValueNotExtensionTypeErased: int
  g: Type
    toTypeValue: String
    toTypeValueNotExtensionTypeErased: String
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int, U: String}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_fieldInitializer_typeParameter_withoutConstructorTearoffs() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
// @dart=2.12
class A<T> {
  final Object f;
  const A(): f = T;
//               ^
// [context 1] The error is in the field initializer of 'A', and occurs here.
// [diag.invalidConstant] Invalid constant value.
}
const a = const A<int>();
//        ^^^^^^^^^^^^^^
// [diag.constTypeParameter][context 1] Type parameters can't be used in a constant expression.
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
<null>
''');
  }

  test_fieldInitializer_visitAsExpression_potentialConstType() async {
    await resolveTestCodeWithDiagnostics('''
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
    var result = await resolveTestCodeWithDiagnostics('''
const a = int.fromEnvironment('a');
const b = int.fromEnvironment('b', defaultValue: 42);
''');

    assertDartObjectText(_topLevelVar(result, 'a'), r'''
int 0
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_int_fromEnvironment_declaredVariables() async {
    declaredVariables = {'a': '5', 'b': 'bbb'};

    var result = await resolveTestCodeWithDiagnostics('''
const a = int.fromEnvironment('a');
const b = int.fromEnvironment('b', defaultValue: 42);
''');

    assertDartObjectText(_topLevelVar(result, 'a'), r'''
int 5
  variable: <testLibrary>::@topLevelVariable::a
''');

    var bResult = _topLevelVar(result, 'b');
    assertDartObjectText(bResult, r'''
int 42
  variable: <testLibrary>::@topLevelVariable::b
''');
  }

  test_issue47351() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo {
  final int bar;
  const Foo(this.bar);
}

int bar = 2;
const a = const Foo(bar);
//                  ^^^
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_issue47603() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final void Function() c;
  const C(this.c);
}

void main() {
  const C(() {});
//        ^^^^^
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
}
''');
  }

  test_issue49389() async {
    // TODO(kallentu): Fix [InvalidConstant.genericError] to handle
    // NamedExpressions.
    await resolveTestCodeWithDiagnostics(r'''
class Foo {
  const Foo({required this.bar});
  final Map<String, String> bar;
}

void main() {
  final data = <String, String>{};
  const Foo(bar: data);
//               ^^^^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_listLiteral_expression_nonConstant() async {
    // TODO(scheglov): https://github.com/dart-lang/sdk/issues/55467
    await resolveTestCodeWithDiagnostics('''
var b = 7;
var x = const A([b]);
//               ^
// [diag.invalidConstant] Invalid constant value.

class A {
  const A(List<int> p);
}
''');
  }

  test_redirectingConstructor_typeParameter() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A<T> {
  final Object f;
  const A(): this.named(T);
  const A.named(Object t): f = t;
}
const a = const A<int>();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
A<int>
  f: Type
    toTypeValue: int
    toTypeValueNotExtensionTypeErased: int
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_redirectingFactoryConstructor_chain() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  const factory A.foo(int a) = B<int>.bar;
}

class B<T> implements A {
  final T f;
  const B(this.f);
  const factory B.bar(T f) = C<T>;
}

class C<U> implements B<U> {
  final U f;
  const C(this.f);
}

const x = A.foo(0);
''');
    var result = _topLevelVar(unitResult, 'x');
    assertDartObjectText(result, r'''
C<int>
  f: int 0
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::foo
    positionalArguments
      0: int 0
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_string_fromEnvironment() async {
    var result = await resolveTestCodeWithDiagnostics('''
const a = String.fromEnvironment('a');
''');
    assertDartObjectText(_topLevelVar(result, 'a'), r'''
String <empty>
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_string_fromEnvironment_declaredVariables() async {
    declaredVariables = {'a': 'test'};

    var result = await resolveTestCodeWithDiagnostics('''
const a = String.fromEnvironment('a');
''');

    assertDartObjectText(_topLevelVar(result, 'a'), r'''
String test
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_superInitializer_formalParameter_explicitSuper_hasNamedArgument_requiredNamed() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
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

    var result = _topLevelVar(unitResult, 'x');
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    constructor: SubstitutedConstructorElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 1
      1: int 2
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_superInitializer_formalParameter_implicitSuper_requiredNamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    constructor: SubstitutedConstructorElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var value = _topLevelVar(result, 'x');
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
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 1
      1: int 2
  variable: <testLibrary>::@topLevelVariable::x
''');
  }

  test_superInitializer_paramTypeMismatch_indirect() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  final double d;
  const C(this.d);
}
class D extends C {
  const D(d) : super(d);
//      ^
// [context 1] The evaluated constructor 'C' is called by 'D' and 'D' is defined here.
//                   ^
// [context 3] The exception is 'A value of type 'String' can't be assigned to a parameter of type 'double' in a const constructor.' and occurs here.
}
class E extends D {
  const E(e) : super(e);
//      ^
// [context 2] The evaluated constructor 'D' is called by 'E' and 'E' is defined here.
}
const f = const E('0.0');
//        ^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1][context 2][context 3] Evaluation of this constant expression throws an exception.
''');
  }

  test_superInitializer_typeParameter() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A<T> {
  final Object f;
  const A(Object t): f = t;
}
class B<T> extends A<T> {
  const B(): super(T);
}
const a = const B<int>();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
B<int>
  (super): A<int>
    f: Type
      toTypeValue: int
      toTypeValueNotExtensionTypeErased: int
    constructorInvocation
      constructor: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: Type
          toTypeValue: int
          toTypeValueNotExtensionTypeErased: int
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_superInitializer_typeParameter_superNonGeneric() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  final Object f;
  const A(Object t): f = t;
}
class B<T> extends A {
  const B(): super(T);
}
const a = const B<int>();
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
B<int>
  (super): A
    f: Type
      toTypeValue: int
      toTypeValueNotExtensionTypeErased: int
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: Type
          toTypeValue: int
          toTypeValueNotExtensionTypeErased: int
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_wildcard_regularInitializer() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  final int _;
  const A(this._);
  int x() => _; // Avoid unused field warning.
}
const a = const A(1);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int _;
  final int y;
  const A(this._): y = _;
//                     ^
// [diag.invalidConstant] Invalid constant value.
// [diag.implicitThisReferenceInInitializer] The instance member '_' can't be accessed in an initializer.
}
''');
  }

  test_wildcard_superInitializer() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
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
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
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

  test_wildcard_superInitializer_multiple_optionalPositional() async {
    var unitResult = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int _;
//          ^
// [diag.unusedField] The value of the field '_' isn't used.
  final int y;
  const A([this._ = 1, this.y = 2]);
}
class B extends A {
  const B([super._ = 3, super._ = 4]);
}
const a = const B(10);
''');
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
B
  (super): A
    _: int 10
    y: int 4
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 10
        1: int 4
  constructorInvocation
    constructor: <testLibrary>::@class::B::@constructor::new
    positionalArguments
      0: int 10
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_wildcard_superInitializer_multiple_requiredPositional() async {
    var unitResult = await resolveTestCodeWithDiagnostics('''
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
    var result = _topLevelVar(unitResult, 'a');
    assertDartObjectText(result, r'''
B
  (super): A
    _: int 1
    y: int 2
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 1
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
