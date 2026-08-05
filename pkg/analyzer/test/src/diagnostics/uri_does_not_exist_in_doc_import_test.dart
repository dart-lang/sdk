// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriDoesNotExistInDocImportTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UriDoesNotExistInDocImportTest extends PubPackageResolutionTest {
  test_libraryDocImport_cannotResolve_dart() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:foo';
//             ^^^^^^^^^^
// [diag.uriDoesNotExistInDocImport] Target of URI doesn't exist: 'dart:foo'.
library;
''');
  }

  test_libraryDocImport_cannotResolve_file() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
//             ^^^^^^^^^^
// [diag.uriDoesNotExistInDocImport] Target of URI doesn't exist: 'foo.dart'.
library;
''');
  }

  test_libraryDocImport_canResolve_dart() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:math';
library;
''');
  }

  test_libraryDocImport_canResolve_file() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;
''');
  }
}
