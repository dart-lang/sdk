// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedCatchClauseTest);
  });
}

@reflectiveTest
class UnusedCatchClauseTest extends PubPackageResolutionTest {
  test_on_unusedException() async {
    await assertErrorsInCode(r'''
f() {
  try {
  } on String catch (exception) {
  }
}
''', [
      error(WarningCode.UNUSED_CATCH_CLAUSE, 35, 9),
    ]);
  }

  test_on_unusedStack_underscores() async {
    await assertErrorsInCode(r'''
f() {
  try {
  } on String catch (exception, __) {
  }
}
''', [
      error(WarningCode.UNUSED_CATCH_STACK, 46, 2),
    ]);
  }

  test_on_unusedStack_wildcard() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } on String catch (exception, _) {
  }
}
''');
  }

  test_on_usedException() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } on String catch (exception) {
    print(exception);
  }
}
''');
  }

  test_unusedException() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } catch (exception) {
  }
}
''');
  }

  test_unusedException_underscores() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } catch (__) {
  }
}
''');
  }

  test_unusedException_wildcard() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } catch (_) {
  }
}
''');
  }

  test_usedException() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } catch (exception) {
    print(exception);
  }
}
''');
  }
}
