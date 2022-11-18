// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantCaseExpressionFromDeferredLibraryTest);
    defineReflectiveTests(
        NonConstantCaseExpressionFromDeferredLibraryTest_Language218);
  });
}

@reflectiveTest
class NonConstantCaseExpressionFromDeferredLibraryTest
    extends PubPackageResolutionTest
    with NonConstantCaseExpressionFromDeferredLibraryTestCases {
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/50502')
  @override
  test_nested() {
    return super.test_nested();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/50502')
  @override
  test_simple() {
    return super.test_simple();
  }
}

@reflectiveTest
class NonConstantCaseExpressionFromDeferredLibraryTest_Language218
    extends PubPackageResolutionTest
    with
        WithLanguage218Mixin,
        NonConstantCaseExpressionFromDeferredLibraryTestCases {}

mixin NonConstantCaseExpressionFromDeferredLibraryTestCases
    on PubPackageResolutionTest {
  test_nested() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await assertErrorsInCode('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case a.c + 1:
      break;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
          72,
          7),
    ]);
  }

  test_simple() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await assertErrorsInCode('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case a.c:
      break;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
          72,
          3),
    ]);
  }
}
