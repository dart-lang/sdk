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
    await resolveTestCodeWithDiagnostics(r'''
class C(final a);
//            ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
''');
  }

  test_declaringParameter_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C(final int a);
''');
  }

  test_fieldParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int a;
  C(this.a);
}
''');
  }

  test_functionTypedFormalParameter_withoutType() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn(String cb(x)) => print(cb(7));
//                ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'x' can't be inferred; a type must be explicitly provided.
''');
  }

  test_functionTypedFormalParameter_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn(String cb(int x)) => print(cb(7));
''');
  }

  test_namedParameter_withoutType() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn({a}) => print(a);
//       ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
''');
  }

  test_namedParameter_withoutType_unreferenced() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn({a}) {}
''');
  }

  test_namedParameter_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn({int a = 0}) => print(a);
''');
  }

  test_parameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn(a) => print(a);
//      ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
''');
  }

  test_parameter_inConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C(a) {
//  ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
    a;
  }
}
''');
  }

  test_parameter_inConstructor_fieldFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int a;
  C(this.a) {
    a;
  }
}
''');
  }

  test_parameter_inConstructor_fieldFormal_withoutType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int a;
  C(this.a) {
    a;
  }
}
''');
  }

  test_parameter_inConstructor_referencedInInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C(a) : assert(a != null);
//  ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
}
''');
  }

  test_parameter_inConstructor_unreferenced() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C(a);
}
''');
  }

  test_parameter_inConstructor_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C(int a) {}
}
''');
  }

  test_parameter_inFunctionLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn() {
  var f = (a) => a;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'f' isn't used.
//         ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
}
''');
  }

  test_parameter_inFunctionLiteral_inferredType() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn() {
  g((a, b) => print('$a$b'));
}

void g(void cb(int a, dynamic b)) => cb(7, "x");
''');
  }

  test_parameter_inFunctionLiteral_inferredType_viaReturn() async {
    await resolveTestCodeWithDiagnostics(r'''
void Function(int, dynamic) fn() {
  return (a, b) => print('$a$b');
}
''');
  }

  test_parameter_inFunctionLiteral_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
var f = (int a) => false;
''');
  }

  test_parameter_inGenericFunction_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn<T>(T a) => print(a);
''');
  }

  test_parameter_inMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void fn(a) => print(a);
//        ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
}
''');
  }

  test_parameter_inMethod_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  void fn(a);
//        ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
}
''');
  }

  test_parameter_inMethod_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void fn(String a) => print(a);
}
''');
  }

  test_parameter_inOverridingMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
typedef void cb(a);
//              ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
''');
  }

  test_parameter_inTypedef_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef cb = void Function(int a);
''');
  }

  test_parameter_withoutKeyword() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn(a) => print(a);
//      ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
''');
  }

  test_parameter_withoutType() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn(a) => print(a);
//      ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
''');
  }

  test_parameter_withoutTypeAndDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn([a = 7]) => print(a);
//       ^
// [diag.inferenceFailureOnUntypedParameter] The type of 'a' can't be inferred; a type must be explicitly provided.
''');
  }

  test_parameter_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn(int a) => print(a);
''');
  }

  test_parameter_withTypeAndDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void fn([int a = 7]) => print(a);
''');
  }

  test_superParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
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
