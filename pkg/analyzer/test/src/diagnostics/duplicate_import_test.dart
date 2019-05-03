// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateImportTest);
  });
}

@reflectiveTest
class DuplicateImportTest extends DriverResolutionTest {
  test_duplicateImport() async {
    newFile('/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
A a;''');

    newFile('/lib1.dart', content: r'''
library lib1;
class A {}''');

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes([HintCode.DUPLICATE_IMPORT]);
  }

  test_importsHaveIdenticalShowHide() async {
    newFile('/lib2.dart', content: r'''
library L;
import 'lib1.dart' as M show A hide B;
import 'lib1.dart' as M show A hide B;
M.A a;''');

    newFile('/lib1.dart', content: r'''
library lib1;
class A {}
class B {}''');

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes([HintCode.DUPLICATE_IMPORT]);
  }

  test_oneImportHasHide() async {
    newFile('/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
A a;
B b;''');

    newFile('/lib1.dart', content: r'''
library lib1;
class A {}
class B {}''');

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertNoTestErrors();
  }

  test_oneImportHasShow() async {
    newFile('/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart' show A;
A a;
B b;''');

    newFile('/lib1.dart', content: r'''
library lib1;
class A {}
class B {}''');

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertNoTestErrors();
  }

  test_oneImportUsesAs() async {
    newFile('/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
A a;
one.A a2;''');

    newFile('/lib1.dart', content: r'''
library lib1;
class A {}''');

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertNoTestErrors();
  }

  test_twoDuplicateImports() async {
    newFile('/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    newFile('/lib1.dart', content: r'''
library lib1;
class A {}''');

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.DUPLICATE_IMPORT, HintCode.DUPLICATE_IMPORT]);
  }

  /// Resolve the test file at [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveTestFile(String path) async {
    result = await resolveFile(convertPath(path));
  }
}
