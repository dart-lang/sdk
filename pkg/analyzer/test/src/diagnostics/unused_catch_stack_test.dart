// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedCatchStackTest);
  });
}

@reflectiveTest
class UnusedCatchStackTest extends DriverResolutionTest {
  @override
  bool get enableUnusedLocalVariable => true;

  test_on_unusedStack() async {
    await assertErrorsInCode(r'''
main() {
  try {
  } on String catch (exception, stackTrace) {
  }
}
''', [HintCode.UNUSED_CATCH_STACK]);
  }

  test_on_usedStack() async {
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
    await assertErrorsInCode(r'''
main() {
  try {
  } catch (exception, stackTrace) {
  }
}
''', [HintCode.UNUSED_CATCH_STACK]);
  }

  test_usedStack() async {
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
