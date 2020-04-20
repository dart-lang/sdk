// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportDuplicatedLibraryNamedTest);
  });
}

@reflectiveTest
class ExportDuplicatedLibraryNamedTest extends DriverResolutionTest {
  test_no_duplication() async {
    newFile("/test/lib/lib1.dart");
    newFile("/test/lib/lib2.dart");
    await assertNoErrorsInCode(r'''
library test;
export 'lib1.dart';
export 'lib2.dart';
''');
  }

  test_sameNames() async {
    newFile("/test/lib/lib1.dart", content: "library lib;");
    newFile("/test/lib/lib2.dart", content: "library lib;");
    await assertErrorsInCode('''
export 'lib1.dart';
export 'lib2.dart';
''', [
      error(StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAMED, 20, 19),
    ]);
  }
}
