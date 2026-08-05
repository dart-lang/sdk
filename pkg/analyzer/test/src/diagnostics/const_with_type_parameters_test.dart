// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithTypeParametersConstructorTearoffTest);
    defineReflectiveTests(ConstWithTypeParametersFunctionTearoffTest);
    defineReflectiveTests(ConstWithTypeParametersTest);
  });
}

@reflectiveTest
class ConstWithTypeParametersConstructorTearoffTest
    extends PubPackageResolutionTest {
  test_asExpression_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
void g() {
  const [f as void Function<T>(T, [int])];
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'void Function<T>(T)' can't be assigned to the list type 'void Function<T>(T, [int])'.
}
''');
  }

  test_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void m([fn = A<T>.new]) {}
//               ^
// [diag.constWithTypeParametersConstructorTearoff] A constant constructor tearoff can't use a type parameter as a type argument.
}
''');
  }

  test_defaultValue_fieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A<T> Function() fn;
  A([this.fn = A<T>.new]);
//               ^
// [diag.constWithTypeParametersConstructorTearoff] A constant constructor tearoff can't use a type parameter as a type argument.
}
''');
  }

  test_defaultValue_noTypeVariableInferredFromParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void m([A<T> Function() fn = A.new]) {}
//                             ^^^^^
// [diag.invalidAssignment] A value of type 'A<dynamic> Function()' can't be assigned to a variable of type 'A<T> Function()'.
}
''');
  }

  test_direct() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void m() {
    const c = A<T>.new;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//              ^
// [diag.constWithTypeParametersConstructorTearoff] A constant constructor tearoff can't use a type parameter as a type argument.
  }
}
''');
  }

  test_fieldValue_constClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  final x = A<T>.new;
//            ^
// [diag.constWithTypeParametersConstructorTearoff] A constant constructor tearoff can't use a type parameter as a type argument.
}
''');
  }

  test_indirect() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void m() {
    const c = A<List<T>>.new;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//                   ^
// [diag.constWithTypeParametersConstructorTearoff] A constant constructor tearoff can't use a type parameter as a type argument.
  }
}
''');
  }

  test_isExpression_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void m() {
    const [false is void Function(T)];
//                                ^
// [diag.constWithTypeParameters] A constant creation can't use a type parameter as a type argument.
  }
}
''');
  }

  test_nonConst() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void m() {
    A<T>.new;
  }
}
''');
  }
}

@reflectiveTest
class ConstWithTypeParametersFunctionTearoffTest
    extends PubPackageResolutionTest {
  test_appliedTypeParameter_defaultConstructorValue() async {
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

  test_appliedTypeParameter_defaultFunctionValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

void bar<T>([void Function(T) p = f]) {}
//                                ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
''');
  }

  test_appliedTypeParameter_defaultMethodValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

class C<T> {
  void foo([void Function(T) p = f]) {}
//                               ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
}
''');
  }

  test_appliedTypeParameter_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

void bar<T>([void Function(List<T>) p = f]) {}
//                                      ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
''');
  }

  test_appliedTypeParameter_nestedFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) => t;

void bar<T>([void Function(T Function()) p = f]) {}
//                                           ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
''');
  }

  test_defaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
class A<U> {
  void m([void Function(U) fn = f<U>]) {}
//                                ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
}
''');
  }

  test_direct() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
class A<U> {
  void m() {
    const c = f<U>;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//              ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
  }
}
''');
  }

  test_fieldValue_constClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
class A<U> {
  const A();
//^^^^^
// [diag.constConstructorWithFieldInitializedByNonConst] Can't define the 'const' constructor because the field 'x' is initialized with a non-constant value.
  final x = f<U>;
//            ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
}
''');
  }

  test_fieldValue_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
class A<U> {}
extension<U> on A<U> {
  final x = f<U>;
//      ^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_fieldValue_nonConstClass() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
class A<U> {
  final x = f<U>;
}
''');
  }

  test_indirect() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
class A<U> {
  void m() {
    const c = f<List<U>>;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
//                   ^
// [diag.constWithTypeParametersFunctionTearoff] A constant function tearoff can't use a type parameter as a type argument.
  }
}
''');
  }

  test_nonConst() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {}
class A<U> {
  void m() {
    f<U>;
  }
}
''');
  }
}

@reflectiveTest
class ConstWithTypeParametersTest extends PubPackageResolutionTest {
  test_direct() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<T>();
//          ^
// [diag.constWithTypeParameters] A constant creation can't use a type parameter as a type argument.
  }
}
''');
  }

  test_indirect() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<List<T>>();
//               ^
// [diag.constWithTypeParameters] A constant creation can't use a type parameter as a type argument.
  }
}
''');
  }

  test_indirect_functionType_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<T Function()>();
//          ^
// [diag.constWithTypeParameters] A constant creation can't use a type parameter as a type argument.
  }
}
''');
  }

  test_indirect_functionType_simpleParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<void Function(T)>();
//                        ^
// [diag.constWithTypeParameters] A constant creation can't use a type parameter as a type argument.
  }
}
''');
  }

  test_indirect_functionType_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<void Function<U>()>();
  }
}
''');
  }

  test_indirect_functionType_typeParameter_nestedFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<void Function<U>(void Function<V>(U, V))>();
  }
}
''');
  }

  test_indirect_functionType_typeParameter_referencedDirectly() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<U Function<U>()>();
  }
}
''');
  }

  test_indirect_functionType_typeParameter_typeArgumentOfReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<List<U> Function<U>()>();
  }
}
''');
  }

  test_indirect_functionType_typeParameter_typeParameterBound() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    const A<void Function<U extends T>()>();
//                                  ^
// [diag.constWithTypeParameters] A constant creation can't use a type parameter as a type argument.
  }
}
''');
  }

  test_nonConstContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  const A();
  void m() {
    A<T>();
  }
}
''');
  }
}
