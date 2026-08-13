// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefaultValueOnRequiredParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DefaultValueOnRequiredParameterTest extends PubPackageResolutionTest {
  test_function_notRequired_default() async {
    await resolveTestCodeWithDiagnostics(r'''
void log({String message = 'no message'}) {}
''');
  }

  test_function_notRequired_noDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void log({String? message}) {}
''');
  }

  test_function_required_default() async {
    await resolveTestCodeWithDiagnostics(r'''
void log({required String? message = 'no message'}) {}
//                         ^^^^^^^
// [diag.defaultValueOnRequiredParameter] Required named parameters can't have a default value.
''');
  }

  test_function_required_noDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void log({required String message}) {}
''');
  }

  test_method_abstract_required_default() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  void foo({required int? a = 0});
//                        ^
// [diag.defaultValueOnRequiredParameter] Required named parameters can't have a default value.
}
''');
  }

  test_method_required_default() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void foo({required int? a = 0}) {}
//                        ^
// [diag.defaultValueOnRequiredParameter] Required named parameters can't have a default value.
}
''');
  }
}
