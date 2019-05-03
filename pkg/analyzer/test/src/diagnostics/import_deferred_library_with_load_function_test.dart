// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportDeferredLibraryWithLoadFunctionTest);
  });
}

@reflectiveTest
class ImportDeferredLibraryWithLoadFunctionTest extends DriverResolutionTest {
  test_deferredImport_withLoadLibraryFunction() async {
    newFile('/pkg1/lib/lib1.dart', content: r'''
library lib1;
loadLibrary() {}
f() {}''');

    newFile('/pkg1/lib/lib2.dart', content: r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }''');

    await _resolveTestFile('/pkg1/lib/lib1.dart');
    await _resolveTestFile('/pkg1/lib/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION]);
  }

  test_deferredImport_withoutLoadLibraryFunction() async {
    newFile('/pkg1/lib/lib1.dart', content: r'''
library lib1;
f() {}''');

    newFile('/pkg1/lib/lib2.dart', content: r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }''');

    await _resolveTestFile('/pkg1/lib/lib1.dart');
    await _resolveTestFile('/pkg1/lib/lib2.dart');
    assertNoTestErrors();
  }

  test_nonDeferredImport_withLoadLibraryFunction() async {
    newFile('/pkg1/lib/lib1.dart', content: r'''
library lib1;
loadLibrary() {}
f() {}''');

    newFile('/pkg1/lib/lib2.dart', content: r'''
library root;
import 'lib1.dart' as lib1;
main() { lib1.f(); }''');

    await _resolveTestFile('/pkg1/lib/lib1.dart');
    await _resolveTestFile('/pkg1/lib/lib2.dart');
    assertNoTestErrors();
  }

  /// Resolve the test file at [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveTestFile(String path) async {
    result = await resolveFile(convertPath(path));
  }
}
