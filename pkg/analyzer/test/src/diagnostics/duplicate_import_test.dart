// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateExportTest);
    defineReflectiveTests(DuplicateImportTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DuplicateExportTest extends PubPackageResolutionTest {
  test_library_duplicateExport() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart';
export 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.duplicateExport] Duplicate export.
''');
  }

  test_library_duplicateExport_differentShow() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart' show A;
export 'lib1.dart' show B;
''');
  }

  test_library_duplicateExport_sameShow() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart' show A;
export 'lib1.dart' show A;
//     ^^^^^^^^^^^
// [diag.duplicateExport] Duplicate export.
''');
  }

  test_part_duplicateExport() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math';
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExport] Duplicate export.
''',
    });
  }
}

@reflectiveTest
class DuplicateImportTest extends PubPackageResolutionTest {
  test_library_duplicateImport_absolute_absolute() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:test/a.dart';
import 'package:test/a.dart';
//     ^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateImport] Duplicate import.

final a = A();
''');
  }

  test_library_duplicateImport_relative_absolute() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'package:test/a.dart';
//     ^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateImport] Duplicate import.

final a = A();
''');
  }

  test_library_duplicateImport_relative_relative() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'a.dart';
//     ^^^^^^^^
// [diag.duplicateImport] Duplicate import.

final a = A();
''');
  }

  test_library_importsHaveIdenticalShowHide() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
library lib1;
class A {}
class B {}
''');

    await resolveFileWithDiagnostics(lib2, r'''
library L;
import 'lib1.dart' as M show A hide B;
//                      ^^^^^^^^^^^^^
// [diag.multipleCombinators] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
import 'lib1.dart' as M show A hide B;
//     ^^^^^^^^^^^
// [diag.duplicateImport] Duplicate import.
//                      ^^^^^^^^^^^^^
// [diag.multipleCombinators] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
M.A a = M.A();
''');
  }

  test_library_oneImportHasHide() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
library lib1;
class A {}
class B {}''');

    await resolveFileWithDiagnostics(lib2, r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
B b = B();
''');
  }

  test_library_oneImportHasShow() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
library lib1;
class A {}
class B {}
''');

    await resolveFileWithDiagnostics(lib2, r'''
library L;
import 'lib1.dart';
import 'lib1.dart' show A; // ignore: unnecessary_import
A a = A();
B b = B();
''');
  }

  test_library_oneImportUsesAs() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
library lib1;
class A {}''');

    await resolveFileWithDiagnostics(lib2, r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
A a = A();
one.A a2 = one.A();
''');
  }

  test_library_twoDuplicateImports() async {
    var lib1 = getFile('$testPackageLibPath/lib1.dart');
    var lib2 = getFile('$testPackageLibPath/lib2.dart');

    await resolveFileWithDiagnostics(lib1, r'''
library lib1;
class A {}''');

    await resolveFileWithDiagnostics(lib2, r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.duplicateImport] Duplicate import.
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.duplicateImport] Duplicate import.
A a = A();
''');
  }

  test_part_duplicateImport() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
import 'dart:math';
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImport] Duplicate import.
void f(Random _) {}
''',
    });
  }
}
