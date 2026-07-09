// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnUninitializedVariableTest);
  });
}

/// Tests of WarningCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnUninitializedVariableTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments, strictInference: true),
    );
  }

  test_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  var a;
//    ^
// [diag.inferenceFailureOnUninitializedVariable] The type of 'a' can't be inferred without either a type or initializer.
}
''');
  }

  test_field_withInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static var c = 3;
  static final d = 5;

  var a = 7;
  final b = 9;
}
''');
  }

  test_field_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int c = 0;
  static final int d = 5;

  int a = 0;
  final int b;

  C(this.b);
}
''');
  }

  test_finalField() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final a;
//      ^
// [diag.inferenceFailureOnUninitializedVariable] The type of 'a' can't be inferred without either a type or initializer.
  C(this.a);
}
''');
  }

  test_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a;
//    ^
// [diag.inferenceFailureOnUninitializedVariable] The type of 'a' can't be inferred without either a type or initializer.
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_localVariable_withInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var a = 7;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_localVariable_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int a = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  dynamic b;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  Object c = Object();
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
  Null d;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
}
''');
  }

  test_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static var a;
//           ^
// [diag.inferenceFailureOnUninitializedVariable] The type of 'a' can't be inferred without either a type or initializer.
}
''');
  }

  test_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
var a;
//  ^
// [diag.inferenceFailureOnUninitializedVariable] The type of 'a' can't be inferred without either a type or initializer.
''');
  }

  test_topLevelVariable_withInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
var a = 7;
''');
  }

  test_topLevelVariable_withType() async {
    await resolveTestCodeWithDiagnostics(r'''
int a = 0;
dynamic b;
Object c = Object();
Null d;
''');
  }
}
