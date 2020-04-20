// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithNonTypeTest);
  });
}

@reflectiveTest
class NewWithNonTypeTest extends DriverResolutionTest {
  test_imported() async {
    newFile("/test/lib/lib.dart", content: "class B {}");
    await assertErrorsInCode('''
import 'lib.dart' as lib;
void f() {
  new lib.A();
}
lib.B b;
''', [
      error(StaticWarningCode.NEW_WITH_NON_TYPE, 47, 1),
    ]);
  }

  test_local() async {
    await assertErrorsInCode('''
var A = 0;
void f() {
  new A();
}
''', [
      error(StaticWarningCode.NEW_WITH_NON_TYPE, 28, 1),
    ]);
  }
}
