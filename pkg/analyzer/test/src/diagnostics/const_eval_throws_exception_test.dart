// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorFieldTypeMismatchContextTest);
    defineReflectiveTests(ConstEvalThrowsExceptionTest);
  });
}

@reflectiveTest
class ConstConstructorFieldTypeMismatchContextTest
    extends PubPackageResolutionTest {
  test_generic_string_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  final T x = y;
//            ^
// [context 1] The exception is 'In a const constructor, a value of type 'int' can't be assigned to the field 'x', which has type 'String'.' and occurs here.
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'T'.
  const C();
}
const int y = 1;
var v = const C<String>();
//      ^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_notGeneric_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(x) : y = x;
//                 ^
// [context 1] The exception is 'In a const constructor, a value of type 'String' can't be assigned to the field 'y', which has type 'int'.' and occurs here.
  final int y;
}
var v = const A('foo');
//      ^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_notGeneric_int_null() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(x) : y = x;
//                 ^
// [context 1] The exception is 'In a const constructor, a value of type 'Null' can't be assigned to the field 'y', which has type 'int'.' and occurs here.
  final int y;
}
var v = const A(null);
//      ^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_notGeneric_null_forNonNullable_fromNullSafe() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final int f;
  const C(a) : f = a;
//                 ^
// [context 1] The exception is 'In a const constructor, a value of type 'Null' can't be assigned to the field 'f', which has type 'int'.' and occurs here.
}

const a = const C(null);
//        ^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }
}

@reflectiveTest
class ConstEvalThrowsExceptionTest extends PubPackageResolutionTest {
  test_asExpression_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  final t;
  const C(dynamic x) : t = x as T;
//                         ^^^^^^
// [context 1] The error is in the field initializer of 'C', and occurs here.
// [context 2] The error is in the field initializer of 'C', and occurs here.
}

main() {
  const C<int>(0);
  const C<int>('foo');
//^^^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
  const C<int>(null);
//^^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 2] Evaluation of this constant expression throws an exception.
}
''');
  }

  test_asExpression_typeParameter_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  final t;
  const C(dynamic x) : t = x as List<T>;
//                         ^^^^^^^^^^^^
// [context 1] The error is in the field initializer of 'C', and occurs here.
// [context 2] The error is in the field initializer of 'C', and occurs here.
}

main() {
  const C<int>(<int>[]);
  const C<int>(<num>[]);
//^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
  const C<int>(null);
//^^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 2] Evaluation of this constant expression throws an exception.
}
''');
  }

  test_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int x, int y) : assert(x < y);
//                        ^^^^^^^^^^^^^
// [context 1] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
var v = const A(3, 2);
//      ^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
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

  test_assertInitializer_withMessage() async {
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

  test_assertInitializer_withMessage_cannotCompute() async {
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

  test_binaryMinus_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic D = null;
const C = D - 5;
//        ^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');

    await resolveTestCodeWithDiagnostics(r'''
const dynamic D = null;
const C = 5 - D;
//        ^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
  }

  test_binaryPlus_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic D = null;
const C = D + 5;
//        ^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');

    await resolveTestCodeWithDiagnostics(r'''
const dynamic D = null;
const C = 5 + D;
//        ^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
  }

  test_CastError_intToDouble_constructor_importAnalyzedAfter() async {
    // See dartbug.com/35993
    var other = getFile('$testPackageLibPath/other.dart');

    await resolveFilesWithDiagnostics({
      testFile: r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''',
      other: r'''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}
''',
    });
  }

  test_CastError_intToDouble_constructor_importAnalyzedBefore() async {
    // See dartbug.com/35993
    var other = getFile('$testPackageLibPath/other.dart');

    await resolveFilesWithDiagnostics({
      other: r'''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}
''',
      testFile: r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''',
    });
  }

  test_default_constructor_arg_empty_map_import() async {
    var other = getFile('$testPackageLibPath/other.dart');

    await resolveFilesWithDiagnostics({
      other: r'''
class C {
  final Map<String, int> m;
  const C({this.m = const <String, int>{}})
    : assert(m != null);
//             ^^^^^^^
// [diag.unnecessaryNullComparisonNeverNullTrue] The operand can't be 'null', so the condition is always 'true'.
}
''',
      testFile: r'''
import 'other.dart';

main() {
  var c = const C();
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
}
''',
    });
  }

  test_enum_constructor_initializer_asExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v();
//^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
  final int x;
  const E({int? x}) : x = x as int;
//                        ^^^^^^^^
// [context 1] The error is in the field initializer of 'E', and occurs here.
}
''');
  }

  test_enum_int_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = null;

enum E {
  v(a);
//^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
//  ^
// [context 1] The exception is 'A value of type 'Null' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here.
  const E(int a);
}
''');
  }

  test_enum_int_String() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic a = '0';

enum E {
  v(a);
//^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
//  ^
// [context 1] The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here.
  const E(int a);
}
''');
  }

  test_eqEq_nonPrimitiveRightOperand() async {
    await resolveTestCodeWithDiagnostics(r'''
const c = const T.eq(1, const Object());
class T {
  final Object value;
  const T.eq(Object o1, Object o2) : value = o1 == o2;
}
''');
  }

  test_fromEnvironment_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
var b1 = const bool.fromEnvironment(1);
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
//                                  ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
var b2 = const bool.fromEnvironment('x', defaultValue: 1);
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
//                                                     ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'bool'.
''');
  }

  test_fromEnvironment_bool_badDefault_whenDefined() async {
    // The type of the defaultValue needs to be correct even when the default
    // value isn't used (because the variable is defined in the environment).
    declaredVariables = {'x': 'true'};
    await resolveTestCodeWithDiagnostics(r'''
var b = const bool.fromEnvironment('x', defaultValue: 1);
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
//                                                    ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'bool'.
''');
  }

  test_fromEnvironment_ifElement() async {
    await resolveTestCodeWithDiagnostics(r'''
const b = bool.fromEnvironment('foo');

main() {
  const l1 = [1, 2, 3];
  const l2 = [if (b) ...l1];
  print(l2);
}
''');
  }

  test_ifElement_false_thenNotEvaluated() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic nil = null;
const c = [if (1 < 0) nil + 1];
''');
  }

  test_ifElement_true_elseNotEvaluated() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic nil = null;
const c = [if (0 < 1) 3 else nil + 1];
''');
  }

  test_redirectingConstructor_paramTypeMismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.a1(x) : this.a2(x);
//                        ^
// [context 1] The exception is 'A value of type 'int' can't be assigned to a parameter of type 'String' in a const constructor.' and occurs here.
  const A.a2(String x);
}
var v = const A.a1(0);
//      ^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
''');
  }

  test_superConstructor_paramTypeMismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final double d;
  const C(this.d);
}
class D extends C {
  const D(d) : super(d);
//      ^
// [context 1] The evaluated constructor 'C' is called by 'D' and 'D' is defined here.
//                   ^
// [context 2] The exception is 'A value of type 'String' can't be assigned to a parameter of type 'double' in a const constructor.' and occurs here.
}
const f = const D('0.0');
//        ^^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1][context 2] Evaluation of this constant expression throws an exception.
''');
  }

  test_symbolConstructor_nonStringArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
var s2 = const Symbol(3);
//       ^^^^^^^^^^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
//                    ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
''');
  }

  test_symbolConstructor_string_digit() async {
    await resolveTestCodeWithDiagnostics(r'''
var s = const Symbol('3');
''');
  }

  test_symbolConstructor_string_underscore() async {
    await resolveTestCodeWithDiagnostics(r'''
var s = const Symbol('_');
''');
  }

  test_unaryBitNot_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic D = null;
const C = ~D;
//        ^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
  }

  test_unaryNegated_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic D = null;
const C = -D;
//        ^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
  }

  test_unaryNot_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic D = null;
const C = !D;
//        ^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
  }
}
