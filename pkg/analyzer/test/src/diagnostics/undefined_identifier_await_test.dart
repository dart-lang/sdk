// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedIdentifierAwaitTest);
  });
}

@reflectiveTest
class UndefinedIdentifierAwaitTest extends DriverResolutionTest {
  test_function() async {
    await assertErrorsInCode('''
void a() { await; }
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT, 11, 5),
    ]);
  }
}
