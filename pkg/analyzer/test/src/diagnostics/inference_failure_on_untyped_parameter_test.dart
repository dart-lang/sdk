// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnUntypedParameterTest);
  });
}

/// Tests of [diag.inferenceFailureOnUntypedParameter] with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnUntypedParameterTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments, strictInference: true),
    );
  }

  test_declaringParameter() async {
    await assertErrorsInCode(
      r'''
class C(final a);
''',
      [error(diag.inferenceFailureOnUntypedParameter, 8, 7)],
    );
  }

  test_declaringParameter_withType() async {
    await assertNoErrorsInCode(r'''
class C(final int a);
''');
  }

  test_fieldParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  int a;
  C(this.a);
}
''');
  }

  test_functionTypedFormalParameter_withoutType() async {
    await assertErrorsInCode(
      r'''
void fn(String cb(x)) => print(cb(7));
''',
      [error(diag.inferenceFailureOnUntypedParameter, 18, 1)],
    );
  }

  test_functionTypedFormalParameter_withType() async {
    await assertNoErrorsInCode(r'''
void fn(String cb(int x)) => print(cb(7));
''');
  }

  test_namedParameter_withoutType() async {
    await assertErrorsInCode(
      r'''
void fn({a}) => print(a);
''',
      [error(diag.inferenceFailureOnUntypedParameter, 9, 1)],
    );
  }

  test_namedParameter_withoutType_unreferenced() async {
    await assertNoErrorsInCode(r'''
void fn({a}) {}
''');
  }

  test_namedParameter_withType() async {
    await assertNoErrorsInCode(r'''
void fn({int a = 0}) => print(a);
''');
  }

  test_parameter() async {
    await assertErrorsInCode(
      r'''
void fn(a) => print(a);
''',
      [error(diag.inferenceFailureOnUntypedParameter, 8, 1)],
    );
  }

  test_parameter_inConstructor() async {
    await assertErrorsInCode(
      r'''
class C {
  C(a) {
    a;
  }
}
''',
      [error(diag.inferenceFailureOnUntypedParameter, 14, 1)],
    );
  }

  test_parameter_inConstructor_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class C {
  int a;
  C(this.a) {
    a;
  }
}
''');
  }

  test_parameter_inConstructor_fieldFormal_withoutType() async {
    await assertNoErrorsInCode(r'''
class C {
  int a;
  C(this.a) {
    a;
  }
}
''');
  }

  test_parameter_inConstructor_referencedInInitializer() async {
    await assertErrorsInCode(
      r'''
class C {
  C(a) : assert(a != null);
}
''',
      [error(diag.inferenceFailureOnUntypedParameter, 14, 1)],
    );
  }

  test_parameter_inConstructor_unreferenced() async {
    await assertNoErrorsInCode(r'''
class C {
  C(a);
}
''');
  }

  test_parameter_inConstructor_withType() async {
    await assertNoErrorsInCode(r'''
class C {
  C(int a) {}
}
''');
  }

  test_parameter_inFunctionLiteral() async {
    await assertErrorsInCode(
      r'''
void fn() {
  var f = (a) => a;
}
''',
      [
        error(diag.unusedLocalVariable, 18, 1),
        error(diag.inferenceFailureOnUntypedParameter, 23, 1),
      ],
    );
  }

  test_parameter_inFunctionLiteral_inferredType() async {
    await assertNoErrorsInCode(r'''
void fn() {
  g((a, b) => print('$a$b'));
}

void g(void cb(int a, dynamic b)) => cb(7, "x");
''');
  }

  test_parameter_inFunctionLiteral_inferredType_viaReturn() async {
    await assertNoErrorsInCode(r'''
void Function(int, dynamic) fn() {
  return (a, b) => print('$a$b');
}
''');
  }

  test_parameter_inFunctionLiteral_withType() async {
    await assertNoErrorsInCode(r'''
var f = (int a) => false;
''');
  }

  test_parameter_inGenericFunction_withType() async {
    await assertNoErrorsInCode(r'''
void fn<T>(T a) => print(a);
''');
  }

  test_parameter_inMethod() async {
    await assertErrorsInCode(
      r'''
class C {
  void fn(a) => print(a);
}
''',
      [error(diag.inferenceFailureOnUntypedParameter, 20, 1)],
    );
  }

  test_parameter_inMethod_abstract() async {
    await assertErrorsInCode(
      r'''
abstract class C {
  void fn(a);
}
''',
      [error(diag.inferenceFailureOnUntypedParameter, 29, 1)],
    );
  }

  test_parameter_inMethod_withType() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn(String a) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn(int a) => print(a);
}

class D extends C {
  @override
  void fn(a) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod_withDefault() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn([int a = 7]) => print(a);
}

class D extends C {
  @override
  void fn([a = 7]) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod_withDefaultAndType() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn([int a = 7]) => print(a);
}

class D extends C {
  @override
  void fn([num a = 7]) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod_withoutType() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn(int a) => print(a);
}

class D extends C {
  @override
  void fn(a) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod_withType() async {
    await assertNoErrorsInCode(r'''
class C {
  void fn(int a) => print(a);
}

class D extends C {
  @override
  void fn(num a) => print(a);
}
''');
  }

  test_parameter_inTypedef_withoutType() async {
    await assertErrorsInCode(
      r'''
typedef void cb(a);
''',
      [error(diag.inferenceFailureOnUntypedParameter, 16, 1)],
    );
  }

  test_parameter_inTypedef_withType() async {
    await assertNoErrorsInCode(r'''
typedef cb = void Function(int a);
''');
  }

  test_parameter_withoutKeyword() async {
    await assertErrorsInCode(
      r'''
void fn(a) => print(a);
''',
      [error(diag.inferenceFailureOnUntypedParameter, 8, 1)],
    );
  }

  test_parameter_withoutType() async {
    await assertErrorsInCode(
      r'''
void fn(a) => print(a);
''',
      [error(diag.inferenceFailureOnUntypedParameter, 8, 1)],
    );
  }

  test_parameter_withoutTypeAndDefault() async {
    await assertErrorsInCode(
      r'''
void fn([a = 7]) => print(a);
''',
      [error(diag.inferenceFailureOnUntypedParameter, 9, 1)],
    );
  }

  test_parameter_withType() async {
    await assertNoErrorsInCode(r'''
void fn(int a) => print(a);
''');
  }

  test_parameter_withTypeAndDefault() async {
    await assertNoErrorsInCode(r'''
void fn([int a = 7]) => print(a);
''');
  }

  test_superParameter() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  int a;
  C(this.a);
}
class D extends C {
  D(super.a);
}
''');
  }
}
