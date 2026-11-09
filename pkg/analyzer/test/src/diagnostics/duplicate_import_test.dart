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

  test_library_duplicateExport_conditional() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', 'int bar = 2;');
    await resolveTestCodeWithDiagnostics(r'''
export 'lib1.dart' if (dart.library.io) 'lib2.dart';
export 'lib1.dart';
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

  test_part_duplicateExport_conditionalAncestorExport() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', 'int bar = 2;');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
export 'lib1.dart' if (dart.library.io) 'lib2.dart';
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
export 'lib1.dart';
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
// [context 1][column 1][length 6] The previous import that is being duplicated.
import 'package:test/a.dart';
//     ^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateImport][context 1] Duplicate import.

final a = A();
''');
  }

  test_library_duplicateImport_conditional() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', 'int bar = 2;');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' if (dart.library.io) 'lib2.dart';
import 'lib1.dart';
int f() => foo;
''');
  }

  test_library_duplicateImport_relative_absolute() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
// [context 1][column 1][length 6] The previous import that is being duplicated.
import 'package:test/a.dart';
//     ^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateImport][context 1] Duplicate import.

final a = A();
''');
  }

  test_library_duplicateImport_relative_relative() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
// [context 1][column 1][length 6] The previous import that is being duplicated.
import 'a.dart';
//     ^^^^^^^^
// [diag.duplicateImport][context 1] Duplicate import.

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
// [context 1][column 1][length 6] The previous import that is being duplicated.
//                             ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
import 'lib1.dart' as M show A hide B;
//     ^^^^^^^^^^^
// [diag.duplicateImport][context 1] Duplicate import.
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
// [context 1][column 1][length 6] The previous import that is being duplicated.
import 'lib1.dart';
// [context 2][column 1][length 6] The previous import that is being duplicated.
//     ^^^^^^^^^^^
// [diag.duplicateImport][context 1] Duplicate import.
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.duplicateImport][context 2] Duplicate import.
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
// [context 1][column 1][length 6] The previous import that is being duplicated.
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImport][context 1] Duplicate import.
void f(Random _) {}
''',
    });
  }

  test_part_duplicateImport_conditionalAncestorImport() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
int foo = 1;
int common = 0;
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
int common = 0;
''');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart' if (dart.library.io) 'lib2.dart';
part 'b.dart';
int a() => common;
''',
      b: r'''
part of 'a.dart';
import 'lib1.dart';
int b() => foo;
''',
    });
  }

  test_part_duplicateImport_differentResolution_ancestorConflict() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', 'int foo = 2;');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib1.dart'.
import 'lib2.dart';
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib2.dart'.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
import 'lib2.dart';
void f() {
  foo;
}
''',
    });
  }

  test_part_duplicateImport_differentResolution_ancestorConflict_inSubpart() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', 'int foo = 2;');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib1.dart'.
import 'lib2.dart';
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib2.dart'.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
import 'lib2.dart';
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
void f() {
  foo;
}
''',
    });
  }

  test_part_duplicateImport_differentResolution_ancestorConflict_inSubpart_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', 'int foo = 2;');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart' as p;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib1.dart'.
import 'lib2.dart' as p;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib2.dart'.
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
import 'lib2.dart' as p;
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
void f() {
  p.foo;
}
''',
    });
  }

  test_part_duplicateImport_inPartAndAncestor() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a(Random _) {}
''',
      b: r'''
part of 'a.dart';
import 'dart:math';
// [context 2][column 1][length 6] The previous import that is being duplicated.
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImport][context 2] Duplicate import.
void b(Random _) {}
''',
    });
  }

  test_part_duplicateImport_interveningImport_changesResolution() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', "String foo = 'two';");
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart';
part 'b.dart';
int a() => foo;
''',
      b: r'''
part of 'a.dart';
import 'lib2.dart';
part 'c.dart';
String b() => foo;
''',
      c: r'''
part of 'b.dart';
import 'lib1.dart';
int c() => foo;
''',
    });
  }

  test_part_duplicateImport_interveningImport_changesResolution_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', "String foo = 'two';");
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart' as p;
part 'b.dart';
int a() => p.foo;
''',
      b: r'''
part of 'a.dart';
import 'lib2.dart' as p;
part 'c.dart';
String b() => p.foo;
''',
      c: r'''
part of 'b.dart';
import 'lib1.dart' as p;
int c() => p.foo;
''',
    });
  }

  test_part_duplicateImport_interveningImport_conflictInInterveningPart() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', 'int foo = 2;');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
int a() => foo;
''',
      b: r'''
part of 'a.dart';
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
// [diag.unusedImport] Unused import: 'lib1.dart'.
import 'lib2.dart';
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib2.dart'.
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
import 'lib1.dart';
int c() => foo;
''',
    });
  }

  test_part_duplicateImport_interveningImport_doesNotChangeResolution() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', 'int bar = 2;');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
int a() => foo;
''',
      b: r'''
part of 'a.dart';
import 'lib2.dart';
part 'c.dart';
int b() => bar;
''',
      c: r'''
part of 'b.dart';
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
int c() => foo;
''',
    });
  }

  test_part_duplicateImport_libraryAndPart() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a(Random _) {}
''',
      b: r'''
part of 'a.dart';
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void b(Random _) {}
''',
    });
  }

  test_part_duplicateImport_libraryAndPart_differentHide() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math' hide min;
part 'b.dart';
void a(Random _) {}
''',
      b: r'''
part of 'a.dart';
import 'dart:math' hide max;
void b(Random _) {}
''',
    });
  }

  test_part_duplicateImport_libraryAndPart_differentShow() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math' show min;
part 'b.dart';
void a() {
  min(1, 2);
}
''',
      b: r'''
part of 'a.dart';
import 'dart:math' show max;
void b() {
  max(1, 2);
}
''',
    });
  }

  test_part_duplicateImport_libraryAndPart_sameHide() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math' hide min;
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a(Random _) {}
''',
      b: r'''
part of 'a.dart';
import 'dart:math' hide min;
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void b(Random _) {}
''',
    });
  }

  test_part_duplicateImport_libraryAndPart_sameShow() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math' show min;
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a() {
  min(1, 2);
}
''',
      b: r'''
part of 'a.dart';
import 'dart:math' show min;
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void b() {
  min(1, 2);
}
''',
    });
  }

  test_part_duplicateImport_multipleInAncestor() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math' show min; // ignore: unnecessary_import
import 'dart:math';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a(Random _) {
  min(1, 2);
}
''',
      b: r'''
part of 'a.dart';
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void b(Random _) {}
''',
    });
  }

  test_part_duplicateImport_prefixed_differentPrefix() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math' as m1;
part 'b.dart';
void a(m1.Random _) {}
''',
      b: r'''
part of 'a.dart';
import 'dart:math' as m2;
void b(m2.Random _) {}
''',
    });
  }

  test_part_duplicateImport_prefixed_libraryAndPart() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math' as m;
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a(m.Random _) {}
''',
      b: r'''
part of 'a.dart';
import 'dart:math' as m;
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void b(m.Random _) {}
''',
    });
  }

  test_part_duplicateImport_relative_absolute() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a(A _) {}
''',
      b: r'''
part of 'a.dart';
import 'package:test/lib1.dart';
//     ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void b(A _) {}
''',
    });
  }

  test_part_duplicateImport_sameResolution_ancestorDeclaresTopLevelMember() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void max() {}
void a(Random _) {}
''',
      b: r'''
part of 'a.dart';
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void b() {
  min(1, 2);
}
''',
    });
  }

  test_part_duplicateImport_sameResolution_ancestorHasNonConflictingConflict() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    newFile('$testPackageLibPath/lib2.dart', '''
int foo = 2;
int bar = 3;
''');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib1.dart'.
import 'lib2.dart';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a() {
  bar;
}
''',
      b: r'''
part of 'a.dart';
import 'lib2.dart';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void b() {
  bar;
}
''',
    });
  }

  test_part_duplicateImport_sameResolution_subpartUses() async {
    newFile('$testPackageLibPath/lib1.dart', 'int foo = 1;');
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'lib1.dart';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a() {
  foo;
}
''',
      b: r'''
part of 'a.dart';
import 'lib1.dart';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
void c() {
  foo;
}
''',
    });
  }

  test_part_generatedPart_matchesAncestor() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.g.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math';
part 'b.g.dart';
void a(Random _) {}
''',
      b: r'''
part of 'a.dart';
import 'dart:math';
void b(Random _) {}
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
import 'dart:math';
part 'c.dart';
void b(Random _) {}
''',
      c: r'''
part of 'b.g.dart';
import 'dart:math';
void c(Random _) {}
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
// [context 1][column 1][length 6] The previous import that is being duplicated.
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImport][context 1] Duplicate import.
void c(Random _) {}
''',
    });
  }

  test_part_nested_duplicateImport_libraryAndNestedPart() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
import 'dart:math';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'b.dart';
void a(Random _) {}
''',
      b: r'''
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
part of 'b.dart';
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'a.dart'.
void c(Random _) {}
''',
    });
  }

  test_part_nested_duplicateImport_parentPartAndNestedPart() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
import 'dart:math';
// [context 1][column 1][length 6] The previous import that is being duplicated.
part 'c.dart';
void b(Random _) {}
''',
      c: r'''
part of 'b.dart';
import 'dart:math';
//     ^^^^^^^^^^^
// [diag.duplicateImportInPart][context 1] Duplicate of import in 'b.dart'.
void c(Random _) {}
''',
    });
  }

  test_part_siblingParts_duplicateImport() async {
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
import 'dart:math';
void b(Random _) {}
''',
      c: r'''
part of 'a.dart';
import 'dart:math';
void c(Random _) {}
''',
    });
  }
}
