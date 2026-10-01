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
  test_libraryDirective_cannotResolve_dart() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:foo';
//             ^^^^^^^^^^
// [diag.uriDoesNotExistInDocImport] Target of URI doesn't exist: 'dart:foo'.
library;
''');
  }

  test_libraryDirective_cannotResolve_file() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
//             ^^^^^^^^^^
// [diag.uriDoesNotExistInDocImport] Target of URI doesn't exist: 'foo.dart'.
library;
''');
  }

  test_libraryDirective_canResolve_dart() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:math';
library;
''');
  }

  test_libraryDirective_canResolve_file() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;
''');
  }

  test_libraryDirective_multiple_firstHasMoreDocImports() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:async';
/// @docImport 'dart:math';
library;
/// @docImport 'dart:collection';
library;
// [diag.multipleLibraryDirectives][column 1][length 7] Only one library directive may be declared in a file.
''');
  }

  test_libraryDirective_multiple_firstHasNoDocImports() async {
    await resolveTestCodeWithDiagnostics(r'''
library;
/// @docImport 'missing.dart';
library;
// [diag.multipleLibraryDirectives][column 1][length 7] Only one library directive may be declared in a file.
''');
  }

  test_libraryDirective_multiple_firstUriDoesNotExist() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'missing.dart';
//             ^^^^^^^^^^^^^^
// [diag.uriDoesNotExistInDocImport] Target of URI doesn't exist: 'missing.dart'.
library;
/// @docImport 'dart:async';
library;
// [diag.multipleLibraryDirectives][column 1][length 7] Only one library directive may be declared in a file.
''');
  }

  test_libraryDirective_multiple_secondHasNoDocImports() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:async';
library;
library;
// [diag.multipleLibraryDirectives][column 1][length 7] Only one library directive may be declared in a file.
''');
  }

  test_libraryDirective_multiple_secondUriDoesNotExist() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'dart:async';
library;
/// @docImport 'missing.dart';
library;
// [diag.multipleLibraryDirectives][column 1][length 7] Only one library directive may be declared in a file.
''');
  }

  test_partOfUriDirective_cannotResolve_file() async {
    var part = getFile('$testPackageLibPath/part.dart');
    await resolveFilesWithDiagnostics({
      testFile: r'''
part 'part.dart';
''',
      part: r'''
/// @docImport 'foo.dart';
//             ^^^^^^^^^^
// [diag.uriDoesNotExistInDocImport] Target of URI doesn't exist: 'foo.dart'.
part of 'test.dart';
''',
    });
  }
}
