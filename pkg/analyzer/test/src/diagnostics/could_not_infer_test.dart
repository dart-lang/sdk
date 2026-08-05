// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CouldNotInferTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

// TODO(scheglov): Add tests with non-function typedefs.
// https://github.com/dart-lang/sdk/issues/44078)
@reflectiveTest
class CouldNotInferTest extends PubPackageResolutionTest {
  test_constructors_inferenceFBounded() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}

class P<T extends C<T>, U extends C<U>> {
  T t;
  U u;
  P(this.t, this.u);
  P._();
//^^^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 't' must be initialized.
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 'u' must be initialized.
  P<U, T> get reversed => new P(u, t);
}

main() {
  P._();
//^
// [context 1] The raw type was instantiated as 'P<C<Object?>, C<Object?>>', and is not regular-bounded.
// [context 2] The raw type was instantiated as 'P<C<Object?>, C<Object?>>', and is not regular-bounded.
//^^^
// [diag.couldNotInfer] Couldn't infer type parameter 'T'.\n\nTried to infer 'C<Object?>' for 'T' which doesn't work:\n  Type parameter 'T' is declared to extend 'C<T>' producing 'C<C<Object?>>'.\n\nConsider passing explicit type argument(s) to the generic.
// [diag.couldNotInfer] Couldn't infer type parameter 'U'.\n\nTried to infer 'C<Object?>' for 'U' which doesn't work:\n  Type parameter 'U' is declared to extend 'C<U>' producing 'C<C<Object?>>'.\n\nConsider passing explicit type argument(s) to the generic.
//^
// [diag.typeArgumentNotMatchingBounds][context 1] 'C<Object?>' doesn't conform to the bound 'C<C<Object?>>' of the type parameter 'T'.
// [diag.typeArgumentNotMatchingBounds][context 2] 'C<Object?>' doesn't conform to the bound 'C<C<Object?>>' of the type parameter 'U'.
}
''');
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
    await resolveTestCodeWithDiagnostics(r'''
class A<X extends A<X>> {}

void foo<X extends Y, Y extends A<X>>() {}

void f() {
  foo();
//^^^
// [diag.couldNotInfer] Couldn't infer type parameter 'Y'.\n'A<Object?>' doesn't conform to the bound 'A<A<Object?>>', instantiated from 'A<X>' using type arguments [A<Object?>, A<Object?>].
}
''');
  }

  test_functionType_optOutOfGenericMetadata() async {
    newFile('$testPackageLibPath/a.dart', '''
void f<X>() {}
''');
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
import 'a.dart';
main() {
  [f];
//^^^
// [diag.couldNotInfer] Couldn't infer type parameter 'E'. Inferred candidate type void Function<X>() has type parameters [X], but a function with type parameters cannot be used as a type argument.
}
''');
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
    await resolveTestCodeWithDiagnostics(r'''
external T f<T extends num>(T a, T b);
void g(int cb(int a, double b)) {}
void main() {
  g(f);
//  ^
// [diag.couldNotInfer] Couldn't infer type parameter 'T'.\n\nTried to infer 'num' for 'T' which doesn't work:\n  Function type declared as 'T Function<T extends num>(T, T)'\n                used where  'int Function(int, double)' is required.\n\nConsider passing explicit type argument(s) to the generic.
// [diag.argumentTypeNotAssignable] The argument type 'num Function(num, num)' can't be assigned to the parameter type 'int Function(int, double)'.
}
''');
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
    await resolveTestCodeWithDiagnostics(r'''
class C<X> {
  C();
  factory C.foo() => C();
  factory C.bar() = C;
}
typedef G<X> = X Function(X);
typedef A<X extends G<C<X>>> = C<X>;

void f() {
  A(); // Error.
//^
// [diag.couldNotInfer] Couldn't infer type parameter 'X'.\n\nTried to infer 'C<Object?> Function(C<Never>)' for 'X' which doesn't work:\n  Type parameter 'X' is declared to extend 'C<X> Function(C<X>)' producing 'C<C<Object?> Function(C<Never>)> Function(C<C<Object?> Function(C<Never>)>)'.\n\nConsider passing explicit type argument(s) to the generic.
  A.foo(); // Error.
//^^^^^
// [diag.couldNotInfer] Couldn't infer type parameter 'X'.\n\nTried to infer 'C<Object?> Function(C<Never>)' for 'X' which doesn't work:\n  Type parameter 'X' is declared to extend 'C<X> Function(C<X>)' producing 'C<C<Object?> Function(C<Never>)> Function(C<C<Object?> Function(C<Never>)>)'.\n\nConsider passing explicit type argument(s) to the generic.
  A.bar(); // Error.
//^^^^^
// [diag.couldNotInfer] Couldn't infer type parameter 'X'.\n\nTried to infer 'C<Object?> Function(C<Never>)' for 'X' which doesn't work:\n  Type parameter 'X' is declared to extend 'C<X> Function(C<X>)' producing 'C<C<Object?> Function(C<Never>)> Function(C<C<Object?> Function(C<Never>)>)'.\n\nConsider passing explicit type argument(s) to the generic.
}
''');
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
