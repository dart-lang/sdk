// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryQuestionMarkTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryQuestionMarkTest extends PubPackageResolutionTest {
  test_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
dynamic a;
''');
  }

  test_dynamicQuestionMark() async {
    await resolveTestCodeWithDiagnostics('''
dynamic? a;
//     ^
// [diag.unnecessaryQuestionMark] The '?' is unnecessary because 'dynamic' is nullable without it.
''');
  }

  test_dynamicQuestionMark_inVariableDeclarationPattern() async {
    await resolveTestCodeWithDiagnostics('''
void f(List<Object> a) {
  var [dynamic? _] = a;
//            ^
// [diag.unnecessaryQuestionMark] The '?' is unnecessary because 'dynamic' is nullable without it.
}
''');
  }

  test_Null() async {
    await resolveTestCodeWithDiagnostics('''
Null a;
''');
  }

  test_NullQuestionMark() async {
    await resolveTestCodeWithDiagnostics('''
Null? a;
//  ^
// [diag.unnecessaryQuestionMark] The '?' is unnecessary because 'Null' is nullable without it.
''');
  }

  test_NullQuestionMark_inCastPattern() async {
    await resolveTestCodeWithDiagnostics('''
void f(Object a) {
  switch (a) {
    case var _ as Null?:
//                ^^^^^
// [diag.patternNeverMatchesValueType] The matched value type 'Object' can never match the required type 'Null'.
//                    ^
// [diag.unnecessaryQuestionMark] The '?' is unnecessary because 'Null' is nullable without it.
  }
}
''');
  }

  test_typeAliasQuestionMark() async {
    await resolveTestCodeWithDiagnostics('''
typedef n = Null;
n? a;
''');
  }
}
