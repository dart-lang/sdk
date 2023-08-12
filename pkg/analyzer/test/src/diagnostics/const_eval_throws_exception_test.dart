// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorFieldTypeMismatchContextTest);
    defineReflectiveTests(ConstConstructorParamTypeMismatchContextTest);
    defineReflectiveTests(ConstEvalThrowsExceptionTest);
    defineReflectiveTests(ConstEvalThrowsExceptionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ConstConstructorFieldTypeMismatchContextTest
    extends PubPackageResolutionTest {
  test_generic_string_int() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<String>();
''',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 27, 1),
        error(
          CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
          70,
          17,
          contextMessages: [
            ExpectedContextMessage(testFile.path, 70, 17,
                text:
                    "The exception is 'In a const constructor, a value of type 'int' can't be assigned to the field 'x', which has type 'String'.' and occurs here."),
          ],
        ),
      ],
    );
  }

  test_notGeneric_int_int() async {
    await assertErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A('foo');
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        57,
        14,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 29, 1,
              text:
                  "The exception is 'In a const constructor, a value of type 'String' can't be assigned to the field 'y', which has type 'int'.' and occurs here."),
        ],
      ),
    ]);
  }

  test_notGeneric_int_null() async {
    var errors = expectedErrorsByNullability(nullable: [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        57,
        13,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 29, 1,
              text:
                  "The exception is 'In a const constructor, a value of type 'Null' can't be assigned to the field 'y', which has type 'int'.' and occurs here."),
        ],
      ),
    ], legacy: []);
    await assertErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A(null);
''', errors);
  }

  test_notGeneric_null_forNonNullable_fromNullSafe() async {
    await assertErrorsInCode('''
class C {
  final int f;
  const C(a) : f = a;
}

const a = const C(null);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        60,
        13,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 44, 1,
              text:
                  "The exception is 'In a const constructor, a value of type 'Null' can't be assigned to the field 'f', which has type 'int'.' and occurs here."),
        ],
      ),
    ]);
  }
}

@reflectiveTest
class ConstConstructorParamTypeMismatchContextTest
    extends PubPackageResolutionTest {
  test_assignable_fieldFormal_typedef() async {
    // foo has the type dynamic -> dynamic, so it is not assignable to A.f.
    await assertErrorsInCode(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
foo(x) => 1;
var v = const A(foo);
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 116, 3),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        108,
        12,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 116, 3,
              text:
                  "The exception is 'A value of type 'dynamic Function(dynamic)' can't be assigned to a parameter of type 'String Function(int)' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }

  test_enum_int_null() async {
    await assertErrorsInCode(r'''
const dynamic a = null;

enum E {
  v(a);
  const E(int a);
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        36,
        4,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 38, 1,
              text:
                  "The exception is 'A value of type 'Null' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }

  test_enum_int_String() async {
    await assertErrorsInCode(r'''
const dynamic a = '0';

enum E {
  v(a);
  const E(int a);
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        35,
        4,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 37, 1,
              text:
                  "The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }

  test_notAssignable_fieldFormal_optional() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A([this.x = 'foo']);
}
var v = const A();
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 45, 5),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        64,
        9,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 64, 9,
              text:
                  "The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }

  test_notAssignable_fieldFormal_supertype() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final B b;
  const C(this.b);
}
const A u = const A();
var v = const C(u);
''', [
      // TODO(srawlins): It would be best to report only the first one.
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        135,
        10,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 143, 1,
              text:
                  "The exception is 'A value of type 'A' can't be assigned to a parameter of type 'B' in a const constructor.' and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 143, 1),
    ]);
  }

  test_notAssignable_fieldFormal_typedef() async {
    // foo has type String -> int, so it is not assignable to A.f
    // (A.f requires it to be int -> String).
    await assertErrorsInCode(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
int foo(String x) => 1;
var v = const A(foo);
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 127, 3),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        119,
        12,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 127, 3,
              text:
                  "The exception is 'A value of type 'int Function(String)' can't be assigned to a parameter of type 'String Function(int)' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }

  test_notAssignable_fieldFormal_unrelated() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        54,
        14,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 62, 5,
              text:
                  "The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 62, 5),
    ]);
  }

  test_notAssignable_typeSubstitution() async {
    await assertErrorsInCode(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>('foo');
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 52, 5),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        39,
        19,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 52, 5,
              text:
                  "The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }

  test_notAssignable_unrelated() async {
    await assertErrorsInCode(r'''
class A {
  const A(int x);
}
var v = const A('foo');
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        38,
        14,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 46, 5,
              text:
                  "The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 46, 5),
    ]);
  }
}

@reflectiveTest
class ConstEvalThrowsExceptionTest extends PubPackageResolutionTest
    with ConstEvalThrowsExceptionTestCases {
  test_asExpression_typeParameter() async {
    await assertErrorsInCode('''
class C<T> {
  final t;
  const C(dynamic x) : t = x as T;
}

main() {
  const C<int>(0);
  const C<int>('foo');
  const C<int>(null);
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        92,
        19,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 51, 6,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        115,
        18,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 51, 6,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
    ]);
  }

  test_asExpression_typeParameter_nested() async {
    await assertErrorsInCode('''
class C<T> {
  final t;
  const C(dynamic x) : t = x as List<T>;
}

main() {
  const C<int>(<int>[]);
  const C<int>(<num>[]);
  const C<int>(null);
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        104,
        21,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 51, 12,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        129,
        18,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 51, 12,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
    ]);
  }

  test_enum_constructor_initializer_asExpression() async {
    await assertErrorsInCode(r'''
enum E {
  v();
  final int x;
  const E({int? x}) : x = x as int;
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        11,
        3,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 57, 8,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
    ]);
  }

  test_invalid_constructorFieldInitializer_fromSeparateLibrary() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A<T> {
  final int f;
  const A() : f = T.foo;
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';
const a = const A();
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        29,
        9,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 46, 5,
              text:
                  "The exception is 'Invalid constant value.' and occurs here."),
        ],
      ),
    ]);
  }

  test_property_length_invalidTarget() async {
    await assertErrorsInCode('''
void main() {
  const RequiresNonEmptyList([1]);
}

class RequiresNonEmptyList {
  const RequiresNonEmptyList(List<int> numbers) : assert(numbers.length > 0);
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        16,
        31,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 138, 14,
              text:
                  "The exception is 'The property 'length' can't be accessed on the type 'List<int>' in a constant expression.' and occurs here."),
        ],
      ),
    ]);
  }

  test_redirectingConstructor_paramTypeMismatch() async {
    await assertErrorsInCode(r'''
class A {
  const A.a1(x) : this.a2(x);
  const A.a2(String x);
}
var v = const A.a1(0);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        74,
        13,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 36, 1,
              text:
                  "The exception is 'A value of type 'int' can't be assigned to a parameter of type 'String' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }

  test_superConstructor_paramTypeMismatch() async {
    await assertErrorsInCode(r'''
class C {
  final double d;
  const C(this.d);
}
class D extends C {
  const D(d) : super(d);
}
const f = const D('0.0');
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        106,
        14,
        contextMessages: [
          ExpectedContextMessage('/home/test/lib/test.dart', 77, 1,
              text:
                  "The evaluated constructor 'C' is called by 'D' and 'D' is defined here."),
          ExpectedContextMessage('/home/test/lib/test.dart', 90, 1,
              text:
                  "The exception is 'A value of type 'String' can't be assigned to a parameter of type 'double' in a const constructor.' and occurs here."),
        ],
      ),
    ]);
  }
}

@reflectiveTest
mixin ConstEvalThrowsExceptionTestCases on PubPackageResolutionTest {
  test_assertInitializerThrows() async {
    await assertErrorsInCode(r'''
class A {
  const A(int x, int y) : assert(x < y);
}
var v = const A(3, 2);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        61,
        13,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 36, 13,
              text:
                  "The exception is 'The assertion in this constant expression failed.' and occurs here."),
        ],
      ),
    ]);
  }

  test_assertion_indirect() async {
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

  test_CastError_intToDouble_constructor_importAnalyzedAfter() async {
    // See dartbug.com/35993
    newFile('$testPackageLibPath/other.dart', '''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}''');
    await assertNoErrorsInCode(r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''');
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_CastError_intToDouble_constructor_importAnalyzedBefore() async {
    // See dartbug.com/35993
    newFile('$testPackageLibPath/other.dart', '''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}''');
    await assertNoErrorsInCode(r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''');
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_default_constructor_arg_empty_map_import() async {
    newFile('$testPackageLibPath/other.dart', '''
class C {
  final Map<String, int> m;
  const C({this.m = const <String, int>{}})
    : assert(m != null);
}
''');
    await assertErrorsInCode('''
import 'other.dart';

main() {
  var c = const C();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 37, 1),
    ]);
    var otherFileResult =
        await resolveFile(convertPath('$testPackageLibPath/other.dart'));
    assertErrorsInList(
      otherFileResult.errors,
      expectedErrorsByNullability(
        nullable: [
          error(WarningCode.UNNECESSARY_NULL_COMPARISON_TRUE, 97, 7),
        ],
        legacy: [],
      ),
    );
  }

  test_finalAlreadySet_initializer() async {
    // If a final variable has an initializer at the site of its declaration,
    // and at the site of the constructor, then invoking that constructor would
    // produce a runtime error; hence invoking that constructor via the "const"
    // keyword results in a compile-time error.
    await assertErrorsInCode('''
class C {
  final x = 1;
  const C() : x = 2;
}
var x = const C();
''', [
      error(
          CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
          39,
          1),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        56,
        9,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 43, 1,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
    ]);
  }

  test_finalAlreadySet_initializing_formal() async {
    // If a final variable has an initializer at the site of its declaration,
    // and it is initialized using an initializing formal at the site of the
    // constructor, then invoking that constructor would produce a runtime
    // error; hence invoking that constructor via the "const" keyword results
    // in a compile-time error.
    await assertErrorsInCode('''
class C {
  final x = 1;
  const C(this.x);
}
var x = const C(2);
''', [
      error(
          CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
          40,
          1),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        54,
        10,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 54, 10,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
    ]);
  }

  test_fromEnvironment_assertInitializer() async {
    await assertNoErrorsInCode('''
class A {
  const A(int x) : assert(x >= 0);
}

main() {
  var c = const A(int.fromEnvironment('x'));
  print(c);
}
''');
  }

  test_fromEnvironment_bool_badArgs() async {
    await assertErrorsInCode(r'''
var b1 = const bool.fromEnvironment(1);
var b2 = const bool.fromEnvironment('x', defaultValue: 1);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        9,
        29,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 9, 29,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 36, 1),
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        49,
        48,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 49, 48,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 95, 1),
    ]);
  }

  test_fromEnvironment_bool_badDefault_whenDefined() async {
    // The type of the defaultValue needs to be correct even when the default
    // value isn't used (because the variable is defined in the environment).
    declaredVariables = {'x': 'true'};
    await assertErrorsInCode('''
var b = const bool.fromEnvironment('x', defaultValue: 1);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        8,
        48,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 8, 48,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 54, 1),
    ]);
  }

  test_ifElement_false_thenNotEvaluated() async {
    await assertNoErrorsInCode('''
const dynamic nil = null;
const c = [if (1 < 0) nil + 1];
''');
  }

  test_ifElement_true_elseNotEvaluated() async {
    await assertNoErrorsInCode('''
const dynamic nil = null;
const c = [if (0 < 1) 3 else nil + 1];
''');
  }

  test_symbolConstructor_nonStringArgument() async {
    await assertErrorsInCode(r'''
var s2 = const Symbol(3);
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        9,
        15,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 9, 15,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 22, 1),
    ]);
  }

  test_symbolConstructor_string_digit() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [], legacy: [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        8,
        17,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 8, 17,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
    ]);
    await assertErrorsInCode(r'''
var s = const Symbol('3');
''', expectedErrors);
  }

  test_symbolConstructor_string_underscore() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [], legacy: [
      error(
        CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
        8,
        17,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 8, 17,
              text:
                  "The exception is 'Evaluation of this constant expression throws an exception.' and occurs here."),
        ],
      ),
    ]);
    await assertErrorsInCode(r'''
var s = const Symbol('_');
''', expectedErrors);
  }

  test_unaryBitNot_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = ~D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_unaryNegated_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = -D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_unaryNot_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = !D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }
}

@reflectiveTest
class ConstEvalThrowsExceptionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, ConstEvalThrowsExceptionTestCases {
  test_binaryMinus_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = D - 5;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);

    await assertErrorsInCode('''
const dynamic D = null;
const C = 5 - D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);
  }

  test_binaryPlus_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = D + 5;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);

    await assertErrorsInCode('''
const dynamic D = null;
const C = 5 + D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);
  }

  test_eqEq_nonPrimitiveRightOperand() async {
    await assertNoErrorsInCode('''
const c = const T.eq(1, const Object());
class T {
  final Object value;
  const T.eq(Object o1, Object o2) : value = o1 == o2;
}
''');
  }

  test_fromEnvironment_ifElement() async {
    await assertNoErrorsInCode('''
const b = bool.fromEnvironment('foo');

main() {
  const l1 = [1, 2, 3];
  const l2 = [if (b) ...l1];
  print(l2);
}
''');
  }
}
