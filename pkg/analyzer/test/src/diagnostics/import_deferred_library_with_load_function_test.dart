// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportDeferredLibraryWithLoadFunctionTest);
  });
}

@reflectiveTest
class ImportDeferredLibraryWithLoadFunctionTest
    extends PubPackageResolutionTest {
  test_deferredImport_withLoadLibraryFunction() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
loadLibrary() {}
f() {}''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION, 14, 36),
    ]);
  }

  test_deferredImport_withoutLoadLibraryFunction() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
f() {}''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_nonDeferredImport_withLoadLibraryFunction() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
loadLibrary() {}
f() {}''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library root;
import 'lib1.dart' as lib1;
main() { lib1.f(); }''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  /// Resolve the file with the given [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveFile(
    String path, [
    List<ExpectedError> expectedErrors = const [],
  ]) async {
    result = await resolveFile(convertPath(path));
    assertErrorsInResolvedUnit(result, expectedErrors);
  }
}
