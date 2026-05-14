// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CouldNotInferTest);
  });
}

// TODO(scheglov): Add tests with non-function typedefs.
// https://github.com/dart-lang/sdk/issues/44078)
@reflectiveTest
class CouldNotInferTest extends PubPackageResolutionTest {
  test_constructors_inferenceFBounded() async {
    // Skipped migration to resolveTestCodeWithDiagnostics due to multi-line
    // error messages for couldNotInfer which are not supported well by the tool.
    await assertErrorsInCode(
      '''
class C<T> {}

class P<T extends C<T>, U extends C<U>> {
  T t;
  U u;
  P(this.t, this.u);
  P._();
  P<U, T> get reversed => new P(u, t);
}

main() {
  P._();
}
''',
      [
        error(diag.notInitializedNonNullableInstanceFieldConstructor, 94, 3),
        error(diag.notInitializedNonNullableInstanceFieldConstructor, 94, 3),
        error(diag.couldNotInfer, 154, 3),
        error(diag.couldNotInfer, 154, 3),
        error(
          diag.typeArgumentNotMatchingBounds,
          154,
          1,
          contextMessages: [message(testFile, 154, 1)],
        ),
        error(
          diag.typeArgumentNotMatchingBounds,
          154,
          1,
          contextMessages: [message(testFile, 154, 1)],
        ),
      ],
    );
  }

  test_constructors_inferFromArguments_argumentNotAssignable() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

typedef T F<T>();

class C<T extends A> {
  C(F<T> f);
}

class NotA {}
NotA myF() => null;
//            ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'myF' because it has a return type of 'NotA'.

main() {
  var x = C(myF);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//          ^^^
// [diag.argumentTypeNotAssignable] The argument type 'NotA Function()' can't be assigned to the parameter type 'F<A>'.
}
''');
  }

  test_downwardInference_fixes_noUpwardsErrors() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math';
// T max<T extends num>(T x, T y);
main() {
  num x;
  dynamic y;

  num a = max(x, y);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//            ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
  Object b = max(x, y);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
//               ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
  dynamic c = max(x, y);
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//                ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
  var d = max(x, y);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
//            ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
}
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics(r'''
T f<T>(T t) => null;
//             ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
main() { f(<S>(S s) => s); }
''');
  }

  test_function_argument_invalidType() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo<T extends num>(T t) {}

void f(X x) {
//     ^
// [diag.undefinedClass] Undefined class 'X'.
  foo(x);
}
''');
  }

  test_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<X>() {}

main() {
  [f];
}
''');
  }

  test_functionType_allSameSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
external T f<T extends num>(T a, T b);
void g(int cb(int a, int b)) {}
void main() {
  g(f);
}
''');
  }

  test_functionType_instantiatedToBounds() async {
    // Skipped migration to resolveTestCodeWithDiagnostics due to multi-line
    // error messages for couldNotInfer which are not supported well by the tool.
    await assertErrorsInCode(
      r'''
class A<X extends A<X>> {}

void foo<X extends Y, Y extends A<X>>() {}

void f() {
  foo();
}
''',
      [error(diag.couldNotInfer, 85, 3)],
    );
  }

  test_functionType_optOutOfGenericMetadata() async {
    newFile('$testPackageLibPath/a.dart', '''
void f<X>() {}
''');
    // Skipped migration to resolveTestCodeWithDiagnostics due to multi-line
    // error messages for couldNotInfer which are not supported well by the tool.
    await assertErrorsInCode(
      '''
// @dart=2.12
import 'a.dart';
main() {
  [f];
}
''',
      [error(diag.couldNotInfer, 42, 3)],
    );
  }

  test_functionType_parameterIsBound_returnIsBound() async {
    await resolveTestCodeWithDiagnostics(r'''
external T f<T extends num>(T a, T b);
void g(num cb(num a, num b)) {}
void main() {
  g(f);
}
''');
  }

  test_functionType_parameterIsObject_returnIsBound() async {
    await resolveTestCodeWithDiagnostics(r'''
external T f<T extends num>(T a, T b);
void g(num cb(Object a, Object b)) {}
void main() {
  g(f);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'num Function(num, num)' can't be assigned to the parameter type 'num Function(Object, Object)'.
}
''');
  }

  test_functionType_parameterIsObject_returnIsBound_prefixedFunction() async {
    newFile('$testPackageLibPath/a.dart', '''
external T f<T extends num>(T a, T b);
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as a;
void g(num cb(Object a, Object b)) {}
void main() {
  g(a.f);
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'num Function(num, num)' can't be assigned to the parameter type 'num Function(Object, Object)'.
}
''');
  }

  test_functionType_parameterIsObject_returnIsSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
external T f<T extends num>(T a, T b);
void g(int cb(Object a, Object b)) {}
void main() {
  g(f);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'num Function(num, num)' can't be assigned to the parameter type 'int Function(Object, Object)'.
}
''');
  }

  test_functionType_parameterIsObject_returnIsSubtype_tearOff() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T m<T extends num>(T x, T y) {
    throw 'error';
  }
}
void g(int cb(Object a, Object b)) {}
void main() {
  g(C().m);
//  ^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'num Function(num, num)' can't be assigned to the parameter type 'int Function(Object, Object)'.
}
''');
  }

  test_functionType_parameterIsSubtype_returnIsBound() async {
    await resolveTestCodeWithDiagnostics(r'''
external T f<T extends num>(T a, T b);
void g(num cb(int a, int b)) {}
void main() {
  g(f);
}
''');
  }

  test_functionType_parameterIsSubtype_returnIsObject() async {
    await resolveTestCodeWithDiagnostics(r'''
external T f<T extends num>(T a, T b);
void g(Object cb(int a, int b)) {}
void main() {
  g(f);
}
''');
  }

  test_functionType_parametersAreSubtypes_returnIsBound() async {
    await resolveTestCodeWithDiagnostics(r'''
external T f<T extends num>(T a, T b);
void g(num cb(int a, double b)) {}
void main() {
  g(f);
}
''');
  }

  test_functionType_parametersAreSubtypes_returnIsOne() async {
    // Skipped migration to resolveTestCodeWithDiagnostics due to multi-line
    // error messages for couldNotInfer which are not supported well by the tool.
    await assertErrorsInCode(
      '''
external T f<T extends num>(T a, T b);
void g(int cb(int a, double b)) {}
void main() {
  g(f);
}
''',
      [
        error(diag.couldNotInfer, 92, 1),
        error(diag.argumentTypeNotAssignable, 92, 1),
      ],
    );
  }

  test_genericMethods_correctlyRecognizeGenericUpperBound() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.
    await resolveTestCodeWithDiagnostics(r'''
class Foo<T extends Pattern> {
  U method<U extends T>(U u) => u;
}
main() {
  new Foo<String>().method(42);
//                         ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}
''');
  }

  test_instanceCreation_viaTypeAlias_notWellBounded() async {
    // Skipped migration to resolveTestCodeWithDiagnostics due to multi-line
    // error messages for couldNotInfer which are not supported well by the tool.
    await assertErrorsInCode(
      '''
class C<X> {
  C();
  factory C.foo() => C();
  factory C.bar() = C;
}
typedef G<X> = X Function(X);
typedef A<X extends G<C<X>>> = C<X>;

void f() {
  A(); // Error.
  A.foo(); // Error.
  A.bar(); // Error.
}
''',
      [
        error(diag.couldNotInfer, 152, 1),
        error(diag.couldNotInfer, 169, 5),
        error(diag.couldNotInfer, 190, 5),
      ],
    );
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  T f<T>(T t) => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'T'.
}
main() { new C().f(<S>(S s) => s); }
''');
  }

  test_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<P extends num> {
  factory C(Iterable<P> p) => C._();
  C._();
}

var c = C([]);
//        ^^
// [diag.argumentTypeNotAssignable] The argument type 'List<dynamic>' can't be assigned to the parameter type 'Iterable<num>'.
''');
  }
}
