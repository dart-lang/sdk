// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportResolutionTest);
    defineReflectiveTests(ImportResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class ImportResolutionTest extends DriverResolutionTest {
  test_overrideCoreType_Never() async {
    newFile('/test/lib/declares_never.dart', content: '''
class Never {}
''');
    await assertNoErrorsInCode(r'''
import 'declares_never.dart';

Never f() => throw 'foo';
''');
  }
}

@reflectiveTest
class ImportResolutionWithNullSafetyTest extends ImportResolutionTest
    with WithNullSafetyMixin {}
