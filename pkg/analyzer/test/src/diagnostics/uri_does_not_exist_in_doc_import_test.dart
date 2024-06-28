// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriDoesNotExistInDocImportTest);
  });
}

@reflectiveTest
class UriDoesNotExistInDocImportTest extends PubPackageResolutionTest {
  test_libraryDocImport_cannotResolve_dart() async {
    await assertErrorsInCode(r'''
/// @docImport 'dart:foo';
library;
''', [
      error(WarningCode.URI_DOES_NOT_EXIST_IN_DOC_IMPORT, 15, 10),
    ]);
  }

  test_libraryDocImport_cannotResolve_file() async {
    await assertErrorsInCode(r'''
/// @docImport 'foo.dart';
library;
''', [
      error(WarningCode.URI_DOES_NOT_EXIST_IN_DOC_IMPORT, 15, 10),
    ]);
  }

  test_libraryDocImport_canResolve_dart() async {
    await assertNoErrorsInCode(r'''
/// @docImport 'dart:math';
library;
''');
  }

  test_libraryDocImport_canResolve_file() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;
''');
  }
}
