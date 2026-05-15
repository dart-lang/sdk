// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantCaseExpressionFromDeferredLibraryTest);
    defineReflectiveTests(
      NonConstantCaseExpressionFromDeferredLibraryTest_Language219,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantCaseExpressionFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_nested() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case const (a.c + 1):
//                ^
// [diag.patternConstantFromDeferredLibrary] Constant values from a deferred library can't be used in patterns.
      break;
  }
}
''');
  }

  test_simple() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case a.c:
//         ^
// [diag.patternConstantFromDeferredLibrary] Constant values from a deferred library can't be used in patterns.
      break;
  }
}
''');
  }

  test_simple_typeLiteral() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as a;

void f(Object? x) {
  switch (x) {
    case a.A:
//         ^
// [diag.patternConstantFromDeferredLibrary] Constant values from a deferred library can't be used in patterns.
      break;
  }
}
''');
  }
}

@reflectiveTest
class NonConstantCaseExpressionFromDeferredLibraryTest_Language219
    extends PubPackageResolutionTest
    with WithLanguage219Mixin {
  test_nested() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case a.c + 1:
//         ^
// [diag.nonConstantCaseExpressionFromDeferredLibrary] Constant values from a deferred library can't be used as a case expression.
      break;
  }
}
''');
  }

  test_simple() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case a.c:
//         ^
// [diag.nonConstantCaseExpressionFromDeferredLibrary] Constant values from a deferred library can't be used as a case expression.
      break;
  }
}
''');
  }

  test_simple_typeLiteral() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as a;

void f(Object? x) {
  switch (x) {
    case a.A:
//         ^
// [diag.nonConstantCaseExpressionFromDeferredLibrary] Constant values from a deferred library can't be used as a case expression.
      break;
  }
}
''');
  }
}
