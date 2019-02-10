// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedCatchStackTest);
  });
}

@reflectiveTest
class UnusedCatchStackTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_on_unusedStack() async {
    enableUnusedLocalVariable = true;
    await assertErrorsInCode(r'''
main() {
  try {
  } on String catch (exception, stackTrace) {
  }
}
''', [HintCode.UNUSED_CATCH_STACK]);
  }

  test_on_usedStack() async {
    enableUnusedLocalVariable = true;
    await assertNoErrorsInCode(r'''
main() {
  try {
  } on String catch (exception, stackTrace) {
    print(stackTrace);
  }
}
''');
  }

  test_unusedStack() async {
    enableUnusedLocalVariable = true;
    await assertErrorsInCode(r'''
main() {
  try {
  } catch (exception, stackTrace) {
  }
}
''', [HintCode.UNUSED_CATCH_STACK]);
  }

  test_usedStack() async {
    enableUnusedLocalVariable = true;
    await assertNoErrorsInCode(r'''
main() {
  try {
  } catch (exception, stackTrace) {
    print(stackTrace);
  }
}
''');
  }
}
