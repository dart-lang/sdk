// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorFieldTypeMismatchContextTest);
    defineReflectiveTests(ConstEvalThrowsExceptionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
// [context 1] The error is in the field initializer of 'C.new', and occurs here.
// [context 2] The error is in the field initializer of 'C.new', and occurs here.
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
// [context 1] The error is in the field initializer of 'C.new', and occurs here.
// [context 2] The error is in the field initializer of 'C.new', and occurs here.
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
// [context 1] The evaluated constructor 'A.new' is called by 'B.new' and 'B.new' is defined here.
}
main() {
  print(const B(2)); // (1)
//      ^^^^^^^^^^
// [diag.constEvalThrowsException][context 1][context 2] Evaluation of this constant expression throws an exception.
}
''');
  }

  test_assertInitializer_indirect_inSummary() async {
    enableIndex = false;
    librarySummaryFiles = [
      await buildPackageFooSummary(
        files: {
          'lib/foo.dart': r'''
class A {
  const A(int i) : assert(i == 1);
}

class B extends A {
  const B(int i) : super(i);
}
''',
        },
      ),
    ];
    sdkSummaryFile = await writeSdkSummary();

    // No 'is called by' context message, the location of `B.new` in the
    // summary is not known. The 'occurs here' context message has a wrong
    // location, see `evaluateAndFormatErrorsInConstructorCall`.
    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/foo.dart';
// [context 1][column 1][length 1] The exception is 'The assertion in this constant expression failed.' and occurs here.

void f() {
  print(const B(2));
//      ^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
}
''');
  }

  test_assertInitializer_indirect_mixinApplication() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int i) : assert(i == 1);
//                 ^^^^^^^^^^^^^^
// [context 2] The exception is 'The assertion in this constant expression failed.' and occurs here.
}
mixin M {}
class B = A with M;
//    ^
// [context 1] The evaluated constructor 'A.new' is called by 'B.new' and 'B.new' is defined here.
const b = B(2);
//        ^^^^
// [diag.constEvalThrowsException][context 1][context 2] Evaluation of this constant expression throws an exception.
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

  test_defaultValue_dynamic_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {}
const dynamic a = 0;
const dynamic b = '';
void f([E x = a]) {}
void g([E x = b]) {}
//            ^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
  }

  test_defaultValue_dynamic_extensionType_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E<T>(int it) {}
const dynamic a = 0;
const dynamic b = '';
void f<T>([E<T> x = a]) {}
void g<T>([E<T> x = b]) {}
//                  ^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
  }

  test_defaultValue_dynamic_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic value = '';
void f([int x = value]) {}
//              ^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');
  }

  test_defaultValue_dynamic_invalid_imported() async {
    var other = getFile('$testPackageLibPath/other.dart');

    // Analyze the test file first, so that the default value is computed by
    // the engine; the verifier of `other.dart` would store its own result.
    await resolveFilesWithDiagnostics({
      testFile: r'''
import 'other.dart';

var v = const A();
''',
      other: r'''
const dynamic value = '';
class A {
  const A([int x = value]);
//                 ^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
}
''',
    });
  }

  test_defaultValue_dynamic_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic value = null;
void f([int x = value]) {}
//              ^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
void g([int? x = value]) {}
void h<T>([T? x = value]) {}
''');
  }

  test_defaultValue_dynamic_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic value = 1;
void f([int x = value]) {}
void g({num x = value}) {}
class C {
  const C([int x = value]);
  void f([covariant int x = value]) {}
}
const c = C();
''');
  }

  test_defaultValue_intToDouble() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic value = 1;
void f([double x = value]) {}
//                 ^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
void g([double x = 1]) {}
''');
  }

  test_defaultValue_staticMismatch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f([int x = '']) {}
//              ^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
''');
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
// [context 1] The error is in the field initializer of 'E.new', and occurs here.
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

  test_redirectingFactory_dynamic_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class D<T> {
  const factory D(T x) = D<T>._;
  const D._(Object? x);
}
const dynamic value = '';
const d = D<int>(value);
//        ^^^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
//               ^^^^^
// [context 1] The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here.
''');
  }

  test_redirectingFactory_dynamic_optionalNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class D {
  const factory D({int x}) = D._;
  const D._({Object? x});
}
const dynamic value = '';
const d = D(x: value);
//        ^^^^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
//          ^^^^^^^^
// [context 1] The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here.
''');
  }

  test_redirectingFactory_dynamic_optionalPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class D {
  const factory D([int x]) = D._;
  const D._([Object? x]);
}
const dynamic value = '';
const d = D(value);
//        ^^^^^^^^
// [diag.constEvalThrowsException][context 1] Evaluation of this constant expression throws an exception.
//          ^^^^^
// [context 1] The exception is 'A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.' and occurs here.
''');
  }

  test_redirectingFactory_dynamic_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
class D<T> {
  const factory D(T x) = D<T>._;
  const D._(Object? x);
}
const dynamic value = 1;
const d = D<int>(value);
''');
  }

  test_redirectingFactory_omitted() async {
    await resolveTestCodeWithDiagnostics(r'''
class D {
  const factory D([int x]) = D._;
  const D._([Object? x]);
  const factory D.named({int x}) = D._named;
  const D._named({Object? x});
}
const d = D();
const e = D.named();
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
// [context 1] The evaluated constructor 'C.new' is called by 'D.new' and 'D.new' is defined here.
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
