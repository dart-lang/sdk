// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnFunctionReturnTypeTest);
  });
}

/// Tests of WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnFunctionReturnTypeTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments, strictInference: true),
    );
  }

  test_classInstanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  get f => 7;
//    ^
// [diag.inferenceFailureOnFunctionReturnType] The return type of 'f' can't be inferred.
}
''');
  }

  test_classInstanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  f() => 7;
//^
// [diag.inferenceFailureOnFunctionReturnType] The return type of 'f' can't be inferred.
}
''');
  }

  test_classInstanceMethod_overriding() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class C {
  int f() => 7;
}

class D extends C {
  f() => 9;
}

class E implements C {
  f() => 9;
}

class F with C {
  f() => 9;
}

mixin M on C {
  f() => 9;
}

mixin N {
  int g() => 7;
}

class G with N {
  g() => 9;
}
''');
  }

  test_classInstanceMethod_withReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  Object f() => 7;
}
''');
  }

  test_classInstanceOperator() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  operator +(int x) => print(x);
//         ^
// [diag.inferenceFailureOnFunctionReturnType] The return type of '+' can't be inferred.
}
''');
  }

  test_classInstanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  set f(int x) => print(x);
}
''');
  }

  test_classStaticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static f() => 7;
//       ^
// [diag.inferenceFailureOnFunctionReturnType] The return type of 'f' can't be inferred.
}
''');
  }

  test_classStaticMethod_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int f() => 7;
}
''');
  }

  test_extensionMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on List {
  e() {
//^
// [diag.inferenceFailureOnFunctionReturnType] The return type of 'e' can't be inferred.
    return 7;
  }
}
''');
  }

  test_functionTypedParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(callback()) {
//     ^^^^^^^^^^
// [diag.inferenceFailureOnFunctionReturnType] The return type of 'callback' can't be inferred.
  callback();
}
''');
  }

  test_functionTypedParameter_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void callback(callback2())) {
//                   ^^^^^^^^^^^
// [diag.inferenceFailureOnFunctionReturnType] The return type of 'callback2' can't be inferred.
  callback(() => print('hey'));
}
''');
  }

  test_functionTypedParameter_withReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int callback()) {
  callback();
}
''');
  }

  test_genericFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
Function(int) f = (int n) {
// [diag.inferenceFailureOnFunctionReturnType][column 1][length 13] The return type of ' Function(int)' can't be inferred.
  print(n);
};
''');
  }

  test_genericFunctionType_withReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void Function(int) f = (int n) {
  print(n);
};
''');
  }

  test_localFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void f() {
    g() => 7;
//  ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
  }
}
''');
  }

  test_mixinInstanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin C {
  f() => 7;
//^
// [diag.inferenceFailureOnFunctionReturnType] The return type of 'f' can't be inferred.
}
''');
  }

  test_setter_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
set f(int x) => print(x);
''');
  }

  test_topLevelArrowFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => 7;
// [diag.inferenceFailureOnFunctionReturnType][column 1][length 1] The return type of 'f' can't be inferred.
''');
  }

  test_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
// [diag.inferenceFailureOnFunctionReturnType][column 1][length 1] The return type of 'f' can't be inferred.
  return 7;
}
''');
  }

  test_topLevelFunction_async() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
// [diag.inferenceFailureOnFunctionReturnType][column 1][length 1] The return type of 'f' can't be inferred.
  return 7;
}
''');
  }

  test_topLevelFunction_withReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic f() => 7;
''');
  }

  test_typedef_classic() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Callback(int i);
// [diag.inferenceFailureOnFunctionReturnType][column 1][length 24] The return type of 'Callback' can't be inferred.
''');
  }

  test_typedef_classic_withReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void Callback(int i);
''');
  }

  test_typedef_modern() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Callback = Function(int i);
// [diag.inferenceFailureOnFunctionReturnType][column 1][length 35] The return type of 'Callback' can't be inferred.
''');
  }

  test_typedef_modern_withReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Callback = void Function(int i);
''');
  }
}
