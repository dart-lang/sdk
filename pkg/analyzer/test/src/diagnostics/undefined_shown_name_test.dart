// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedShownNameTest);
  });
}

@reflectiveTest
class UndefinedShownNameTest extends DriverResolutionTest {
  test_export() async {
    newFile('/test/lib/lib1.dart');
    await assertErrorsInCode(r'''
export 'lib1.dart' show a;
''', [HintCode.UNDEFINED_SHOWN_NAME]);
  }

  test_import() async {
    newFile('/test/lib/lib1.dart');
    await assertErrorsInCode(r'''
import 'lib1.dart' show a;
''', [HintCode.UNUSED_IMPORT, HintCode.UNDEFINED_SHOWN_NAME]);
  }
}
