// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnUninitializedVariableTest);
  });
}

/// Tests of HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnUninitializedVariableTest
    extends StaticTypeAnalyzer2TestShared {
  @override
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strictInference = true;
    resetWith(options: options);
  }

  test_localVariable() async {
    String code = r'''
f() {
  var a;
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE]);
  }

  test_localVariable_withInitializer() async {
    String code = r'''
f() {
  var a = 7;
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_localVariable_withType() async {
    String code = r'''
f() {
  int a;
  dynamic b;
  Object c;
  Null d;
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_topLevelVariable() async {
    String code = r'''
var a;
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE]);
  }

  test_topLevelVariable_withInitializer() async {
    String code = r'''
var a = 7;
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_topLevelVariable_withType() async {
    String code = r'''
int a;
dynamic b;
Object c;
Null d;
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_field() async {
    String code = r'''
class C {
  var a;
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE]);
  }

  test_finalField() async {
    String code = r'''
class C {
  final a;
  C(this.a);
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE]);
  }

  test_staticField() async {
    String code = r'''
class C {
  static var a;
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertErrorsInCode(
        code, [HintCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE]);
  }

  test_field_withInitializer() async {
    String code = r'''
class C {
  static var c = 3;
  static final d = 5;

  var a = 7;
  final b = 9;
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }

  test_field_withType() async {
    String code = r'''
class C {
  static int c;
  static final int d = 5;

  int a;
  final int b;

  C(this.b);
}
''';
    await resolveTestUnit(code, noErrors: false);
    await assertNoErrorsInCode(code);
  }
}
