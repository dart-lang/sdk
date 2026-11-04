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
// [context 1][column 1][length 6] The previous export that is being duplicated.
export 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.duplicateExport][context 1] Duplicate export.
''');
  }

  test_library_duplicateExport_differentHide() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart' hide A;
export 'lib1.dart' hide B;
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

  test_library_duplicateExport_sameHide() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart' hide A;
// [context 1][column 1][length 6] The previous export that is being duplicated.
export 'lib1.dart' hide A;
//     ^^^^^^^^^^^
// [diag.duplicateExport][context 1] Duplicate export.
''');
  }

  test_library_duplicateExport_sameShow() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart' show A;
// [context 1][column 1][length 6] The previous export that is being duplicated.
export 'lib1.dart' show A;
//     ^^^^^^^^^^^
// [diag.duplicateExport][context 1] Duplicate export.
''');
  }

  test_library_twoDuplicateExports() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:math';
// [context 1][column 1][length 6] The previous export that is being duplicated.
export 'dart:math';
// [context 2][column 1][length 6] The previous export that is being duplicated.
//     ^^^^^^^^^^^
// [diag.duplicateExport][context 1] Duplicate export.
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExport][context 2] Duplicate export.
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
// [context 1][column 1][length 6] The previous export that is being duplicated.
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExport][context 1] Duplicate export.
''',
    });
  }

  test_part_duplicateExport_inPartAndAncestor() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math';
// [context 1][column 1][length 6] The previous export that is being duplicated.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math';
// [context 2][column 1][length 6] The previous export that is being duplicated.
//     ^^^^^^^^^^^
// [diag.duplicateExportInPart][context 1] Duplicate of export in 'a.dart'.
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExport][context 2] Duplicate export.
''',
    });
  }

  test_part_duplicateExport_libraryAndPart() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math';
// [context 1][column 1][length 6] The previous export that is being duplicated.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExportInPart][context 1] Duplicate of export in 'a.dart'.
''',
    });
  }

  test_part_duplicateExport_libraryAndPart_differentHide() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math' hide min;
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math' hide max;
''',
    });
  }

  test_part_duplicateExport_libraryAndPart_differentShow() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math' show min;
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math' show max;
''',
    });
  }

  test_part_duplicateExport_libraryAndPart_sameHide() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math' hide min;
// [context 1][column 1][length 6] The previous export that is being duplicated.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math' hide min;
//     ^^^^^^^^^^^
// [diag.duplicateExportInPart][context 1] Duplicate of export in 'a.dart'.
''',
    });
  }

  test_part_duplicateExport_libraryAndPart_sameShow() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math' show min;
// [context 1][column 1][length 6] The previous export that is being duplicated.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math' show min;
//     ^^^^^^^^^^^
// [diag.duplicateExportInPart][context 1] Duplicate of export in 'a.dart'.
''',
    });
  }

  test_part_duplicateExport_multipleInAncestor() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math' show min;
export 'dart:math';
// [context 1][column 1][length 6] The previous export that is being duplicated.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExportInPart][context 1] Duplicate of export in 'a.dart'.
''',
    });
  }

  test_part_duplicateExport_relative_absolute() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'lib1.dart';
// [context 1][column 1][length 6] The previous export that is being duplicated.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'package:test/lib1.dart';
//     ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateExportInPart][context 1] Duplicate of export in 'a.dart'.
''',
    });
  }

  test_part_generatedPart_matchesAncestor() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.g.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math';
part 'b.g.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math';
''',
    });
  }

  test_part_nested_ancestorGeneratedPart() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.g.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.g.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math';
part 'c.dart';
''',
      c: r'''
part of 'b.g.dart';
export 'dart:math';
''',
    });
  }

  test_part_nested_duplicateExport() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
export 'dart:math';
// [context 1][column 1][length 6] The previous export that is being duplicated.
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExport][context 1] Duplicate export.
''',
    });
  }

  test_part_nested_duplicateExport_ancestorInterrupted() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math';
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math' show min;
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
export 'dart:math';
''',
    });
  }

  test_part_nested_duplicateExport_libraryAndNestedPart() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'dart:math';
// [context 1][column 1][length 6] The previous export that is being duplicated.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExportInPart][context 1] Duplicate of export in 'a.dart'.
''',
    });
  }

  test_part_nested_duplicateExport_parentPartAndNestedPart() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math';
// [context 1][column 1][length 6] The previous export that is being duplicated.
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
export 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateExportInPart][context 1] Duplicate of export in 'b.dart'.
''',
    });
  }

  test_part_siblingParts_duplicateExport() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
part 'c.dart';
''',
      b: r'''
part of 'a.dart';
export 'dart:math';
''',
      c: r'''
part of 'a.dart';
export 'dart:math';
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
//                             ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
import 'lib1.dart' as M show A hide B;
//     ^^^^^^^^^^^
// [diag.duplicateImport] Duplicate import.
//                             ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
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

  test_part_nested_duplicateImport() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
import 'dart:math';
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImport] Duplicate import.
void f(Random _) {}
''',
    });
  }
}
