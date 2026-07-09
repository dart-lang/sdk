// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriDoesNotExistTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UriDoesNotExistTest extends PubPackageResolutionTest {
  @SkippedTest(issue: 'https://github.com/dart-lang/sdk/issues/51407')
  test_doubleSlash() async {
    newFolder('$testPackageLibPath/c');
    newFile('$testPackageLibPath/c/d.dart', '''''
class D {}
''');
    newFile('$testPackageLibPath/b.dart', '''
import 'c/d.dart';
void g(D d) {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';
import 'c//d.dart';

void f() {
  g(D());
}
''');
  }

  test_libraryExport() async {
    await resolveTestCodeWithDiagnostics('''
export 'unknown.dart';
//     ^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'unknown.dart'.
''');
  }

  test_libraryExport_cannotResolve() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:foo';
//     ^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'dart:foo'.
''');
  }

  test_libraryExport_dart() async {
    await resolveTestCodeWithDiagnostics('''
export 'dart:math/bar.dart';
//     ^^^^^^^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'dart:math/bar.dart'.
''');
  }

  test_libraryImport() async {
    await resolveTestCodeWithDiagnostics('''
import 'unknown.dart';
//     ^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'unknown.dart'.
''');
  }

  test_libraryImport_appearsAfterDeletingTarget() async {
    String filePath = newFile('$testPackageLibPath/target.dart', '').path;

    await resolveTestCodeWithDiagnostics('''
import 'target.dart';
//     ^^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'target.dart'.
''');

    // Remove the overlay in the same way as AnalysisServer.
    deleteFile(filePath);

    var analysisDriver = driverFor(testFile);
    analysisDriver.removeFile(filePath);
    await analysisDriver.applyPendingFileChanges();

    await resolveFileWithDiagnostics(testFile, '''
import 'target.dart';
//     ^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'target.dart'.
''');
  }

  test_libraryImport_cannotResolve() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:foo';
//     ^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'dart:foo'.
''');
  }

  test_libraryImport_dart() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:math/bar.dart';
//     ^^^^^^^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'dart:math/bar.dart'.
''');
  }

  test_libraryImport_deferredWithInvalidUri() async {
    await resolveTestCodeWithDiagnostics(r'''
import '[invalid uri]' deferred as p;
//     ^^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: '[invalid uri]'.
main() {
  p.loadLibrary();
}
''');
  }

  test_libraryImport_disappears_when_fixed() async {
    await resolveTestCodeWithDiagnostics('''
import 'target.dart';
//     ^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'target.dart'.
''');

    var targetFile = newFile('$testPackageLibPath/target.dart', '');

    var analysisDriver = driverFor(testFile);
    analysisDriver.changeFile2(targetFile);
    await analysisDriver.applyPendingFileChanges();

    await resolveFileWithDiagnostics(testFile, '''
import 'target.dart';
//     ^^^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'target.dart'.
''');
  }

  test_part() async {
    await resolveTestCodeWithDiagnostics(r'''
library lib;
part 'unknown.dart';
//   ^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/unknown.dart'.
''');
  }

  test_part_cannotResolve() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'dart:foo';
//   ^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'dart:foo'.
''');
  }
}
