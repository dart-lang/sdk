// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportDuplicatedLibraryNamedTest);
  });
}

@reflectiveTest
class ImportDuplicatedLibraryNamedTest extends DriverResolutionTest {
  test_duplicate() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib;
class A {}
''');
    newFile("/test/lib/lib2.dart", content: '''
library lib;
class B {}
''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
class C implements A, B {}
''', [
      error(StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAMED, 20, 19),
    ]);
  }
}
