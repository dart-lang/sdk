// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfCovariantTest);
  });
}

@reflectiveTest
class InvalidUseOfCovariantTest extends PubPackageResolutionTest {
  test_class_primaryConstructor() async {
    await resolveTestCodeWithDiagnostics('''
class A(covariant var int a);
''');
  }

  test_functionExpression() async {
    await resolveTestCodeWithDiagnostics('''
Function f = (covariant int x) {};
//            ^^^^^^^^^
// [diag.invalidUseOfCovariant] The 'covariant' keyword can only be used for parameters in instance methods or before non-final instance fields.
''');
  }

  test_functionType_inFunctionTypedParameterOfInstanceMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void m(void p(covariant int)) {}
//              ^^^^^^^^^
// [diag.invalidUseOfCovariant] The 'covariant' keyword can only be used for parameters in instance methods or before non-final instance fields.
}
''');
  }

  test_functionType_inParameterOfInstanceMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void m(void Function(covariant int) p) {}
//                     ^^^^^^^^^
// [diag.invalidUseOfCovariant] The 'covariant' keyword can only be used for parameters in instance methods or before non-final instance fields.
}
''');
  }

  test_functionType_inTypeAlias() async {
    await resolveTestCodeWithDiagnostics('''
typedef F = void Function(covariant int);
//                        ^^^^^^^^^
// [diag.invalidUseOfCovariant] The 'covariant' keyword can only be used for parameters in instance methods or before non-final instance fields.
''');
  }

  test_functionType_inTypeArgument() async {
    // TODO(srawlins): Recover better from this situation (`covariant` in
    // parameter in type argument).
    await resolveTestCodeWithDiagnostics('''
List<void Function(covariant int)> a = [];
//                 ^^^^^^^^^
// [diag.invalidUseOfCovariant] The 'covariant' keyword can only be used for parameters in instance methods or before non-final instance fields.
}
// [diag.expectedExecutable][column 1][length 1] Expected a method, getter, setter or operator declaration.
''');
  }

  test_functionType_inTypeParameterBound() async {
    // TODO(srawlins): Recover better from this situation (`covariant` in
    // parameter in bound).
    await resolveTestCodeWithDiagnostics('''
void foo<T extends void Function(covariant int)>() {}
//                               ^^^^^^^^^
// [diag.invalidUseOfCovariant] The 'covariant' keyword can only be used for parameters in instance methods or before non-final instance fields.
}
// [diag.expectedExecutable][column 1][length 1] Expected a method, getter, setter or operator declaration.
''');
  }

  test_localFunction() async {
    await resolveTestCodeWithDiagnostics('''
void foo() {
  void f(covariant int x) {}
//     ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
//       ^^^^^^^^^
// [diag.invalidUseOfCovariant] The 'covariant' keyword can only be used for parameters in instance methods or before non-final instance fields.
}
''');
  }

  test_staticFunction() async {
    // INVALID_USE_OF_COVARIANT is not reported here; it would be redundant.
    await resolveTestCodeWithDiagnostics('''
class C {
  static void m(covariant int x) {}
//              ^^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'covariant' here.
}
''');
  }

  test_staticFunction_onMixin() async {
    // INVALID_USE_OF_COVARIANT is not reported here; it would be redundant.
    await resolveTestCodeWithDiagnostics('''
mixin M {
  static void m(covariant int x) {}
//              ^^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'covariant' here.
}
''');
  }

  test_topLevelFunction() async {
    // INVALID_USE_OF_COVARIANT is not reported here; it would be redundant.
    await resolveTestCodeWithDiagnostics('''
void f(covariant int x) {}
//     ^^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'covariant' here.
''');
  }
}
