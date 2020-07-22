// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';
import '../dart/resolution/with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNonNullAssertionTest);
  });
}

@reflectiveTest
class UnnecessaryNonNullAssertionTest extends DriverResolutionTest
    with WithNullSafetyMixin {
  test_legacy() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.5
var x = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  x!;
}
''');
  }

  test_nonNull() async {
    await assertErrorsInCode('''
f(int x) {
  x!;
}
''', [
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 14, 1),
    ]);
  }

  test_nullable() async {
    await assertNoErrorsInCode('''
f(int? x) {
  x!;
}
''');
  }
}
