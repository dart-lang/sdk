// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnUntypedParameterTest);
  });
}

/// Tests of HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnUntypedParameterTest
    extends StaticTypeAnalyzer2TestShared {
  @override
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strictInference = true;
    resetWith(options: options);
  }

  test_parameter() async {
    String code = r'''
void fn(a) => print(a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_parameter_withVar() async {
    String code = r'''
void fn(var a) => print(a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_parameter_withType() async {
    String code = r'''
void fn(int a) => print(a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_parameter_inGenericFunction_withType() async {
    String code = r'''
void fn<T>(T a) => print(a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_parameter_withVarAndDefault() async {
    String code = r'''
void fn([var a = 7]) => print(a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_parameter_withTypeAndDefault() async {
    String code = r'''
void fn([int a = 7]) => print(a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_namedParameter_withVar() async {
    String code = r'''
void fn({var a}) => print(a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_namedParameter_withType() async {
    String code = r'''
void fn({int a}) => print(a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_parameter_inMethod() async {
    String code = r'''
class C {
  void fn(var a) => print(a);
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_parameter_inMethod_withType() async {
    String code = r'''
class C {
  void fn(String a) => print(a);
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_parameter_inOverridingMethod() async {
    String code = r'''
class C {
  void fn(int a) => print(a);
}

class D extends C {
  @override
  void fn(var a) => print(a);
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_parameter_inOverridingMethod_withType() async {
    String code = r'''
class C {
  void fn(int a) => print(a);
}

class D extends C {
  @override
  void fn(num a) => print(a);
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_parameter_inOverridingMethod_withDefault() async {
    String code = r'''
class C {
  void fn([int a = 7]) => print(a);
}

class D extends C {
  @override
  void fn([var a = 7]) => print(a);
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_parameter_inOverridingMethod_withDefaultAndType() async {
    String code = r'''
class C {
  void fn([int a = 7]) => print(a);
}

class D extends C {
  @override
  void fn([num a = 7]) => print(a);
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_parameter_inConstructor() async {
    String code = r'''
class C {
  C(var a) {}
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_parameter_inConstructor_withType() async {
    String code = r'''
class C {
  C(int a) {}
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_fieldParameter() async {
    String code = r'''
class C {
  int a;
  C(this.a) {}
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_parameter_inFunctionLiteral() async {
    String code = r'''
fn() {
  var f = (var a) {};
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_parameter_inFunctionLiteral_withType() async {
    String code = r'''
fn() {
  var f = (int a) {};
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_functionTypeParameter_withVar() async {
    String code = r'''
void fn(String cb(var x)) => print(cb(7));
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER]);
  }

  test_functionTypeParameter_withType() async {
    String code = r'''
void fn(String cb(int x)) => print(cb(7));
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_parameter_inTypedef_withType() async {
    String code = r'''
typedef cb = void Function(int a);
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }
}
