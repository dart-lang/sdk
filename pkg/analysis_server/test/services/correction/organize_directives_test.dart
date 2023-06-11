// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/organize_imports.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeDirectivesTest);
  });
}

@reflectiveTest
class OrganizeDirectivesTest extends AbstractSingleUnitTest {
  late List<AnalysisError> testErrors;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_docComment_beforeDirective_hasUnresolvedIdentifier() async {
    await _computeUnitAndErrors(r'''
/// Library documentation comment A
/// Library documentation comment B
import 'a.dart';
import 'b.dart';

B b;
''');
    // validate change
    _assertOrganize(r'''
/// Library documentation comment A
/// Library documentation comment B
import 'a.dart';
import 'b.dart';

B b;
''');
  }

  Future<void> test_ignore_asFirstComment() async {
    // Usually the first comment is treated as a library comment and not moved
    // but if it's an 'ignore:' it should be treated as attached to the import.
    await _computeUnitAndErrors(r'''
// ignore: unused_import
import 'dart:io';
import 'dart:async';

Future a;
''');
    // validate change
    _assertOrganize(r'''
import 'dart:async';
// ignore: unused_import
import 'dart:io';

Future a;
''');
  }

  Future<void> test_ignoreForFile_asFirstComment() async {
    // Unlike 'ignore:', 'ignore_for_file:' still _should_ be kept at the top
    // of the file and not attached to the import.
    await _computeUnitAndErrors(r'''
// ignore_for_file: unused_import
import 'dart:io';
import 'dart:async';

Future a;
''');
    // validate change
    _assertOrganize(r'''
// ignore_for_file: unused_import
import 'dart:async';
import 'dart:io';

Future a;
''');
  }

  Future<void> test_keep_duplicateImports_withDifferentPrefix() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async1;
import 'dart:async' as async2;

void f() {
  async1.Future f;
  async2.Stream s;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async' as async1;
import 'dart:async' as async2;

void f() {
  async1.Future f;
  async2.Stream s;
}''', removeUnused: true);
  }

  Future<void> test_keep_unresolvedDirectives() async {
    var code = r'''
import 'dart:noSuchImportSdkLibrary';

import 'package:noSuchImportPackage/andLib.dart';

export 'dart:noSuchExportSdkLibrary';

export 'package:noSuchExportPackage/andLib.dart';

part 'no_such_part.dart';
''';
    await _computeUnitAndErrors(code);
    _assertOrganize(code);
  }

  Future<void> test_languageVersion_afterLibraryComment() async {
    await _computeUnitAndErrors(r'''
// Copyright

// @dart=2.10

import 'dart:io';
import 'dart:async';

File f;
Future a;
''');
    // validate change
    _assertOrganize(r'''
// Copyright

// @dart=2.10

import 'dart:async';
import 'dart:io';

File f;
Future a;
''');
  }

  Future<void> test_languageVersion_asFirstComment() async {
    await _computeUnitAndErrors(r'''
// @dart=2.10
import 'dart:io';
import 'dart:async';

File f;
Future a;
''');
    // validate change
    _assertOrganize(r'''
// @dart=2.10
import 'dart:async';
import 'dart:io';

File f;
Future a;
''');
  }

  Future<void> test_languageVersion_beforeImportWithoutNewline() async {
    await _computeUnitAndErrors(r'''
// Copyright

// @dart=2.10
import 'dart:io';
import 'dart:async';

File f;
Future a;
''');
    // validate change
    _assertOrganize(r'''
// Copyright

// @dart=2.10
import 'dart:async';
import 'dart:io';

File f;
Future a;
''');
  }

  Future<void> test_remove_duplicateImports() async {
    await _computeUnitAndErrors(r'''
import 'dart:async';
import 'dart:async';

void f() {
  Completer f;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async';

void f() {
  Completer f;
}''', removeUnused: true);
  }

  Future<void> test_remove_duplicateImports_differentText_uri() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async;
import "dart:async" as async;

void f() {
  async.Future f;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async' as async;

void f() {
  async.Future f;
}''', removeUnused: true);
  }

  Future<void> test_remove_duplicateImports_withSamePrefix() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async;
import 'dart:async' as async;

void f() {
  async.Future f;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async' as async;

void f() {
  async.Future f;
}''', removeUnused: true);
  }

  Future<void> test_remove_unnecessaryImports() async {
    newFile(
      convertPath('$testPackageLibPath/declarations.dart'),
      'class A {} class B {}',
    );
    newFile(
      convertPath('$testPackageLibPath/exports.dart'),
      'export "a.dart" show A;',
    );
    await _computeUnitAndErrors(r'''
import 'declarations.dart';
import 'exports.dart';

A? a;
B? b;
''');
    // validate change
    _assertOrganize(r'''
import 'declarations.dart';

A? a;
B? b;
''', removeUnused: true);
  }

  Future<void> test_remove_unusedImports() async {
    await _computeUnitAndErrors(r'''
library lib;

import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:collection';

void f() {
  print(pi);
  new HashMap();
}
''');
    // validate change
    _assertOrganize(r'''
library lib;

import 'dart:collection';
import 'dart:math';

void f() {
  print(pi);
  new HashMap();
}
''', removeUnused: true);
  }

  Future<void> test_remove_unusedImports2() async {
    await _computeUnitAndErrors(r'''
import 'dart:async';
import 'dart:math';

class A {}

void f() {
  Completer f;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async';

class A {}

void f() {
  Completer f;
}''', removeUnused: true);
  }

  Future<void> test_remove_unusedImports_hasUnresolvedError() async {
    Future<void> check(String declaration) async {
      var code = '''
import 'dart:async';
$declaration
''';
      await _computeUnitAndErrors(code);
      _assertOrganize(code, removeUnused: true);
    }

    await check('void f() { Unresolved v; }');
    await check('void f() { new Unresolved(); }');
    await check('void f() { const Unresolved(); }');
    await check('void f() { unresolvedFunction(); }');
    await check('void f() { print(unresolvedVariable); }');
    await check('void f() { unresolvedVariable = 0; }');
    await check('void f() { Unresolved.field = 0; }');
    await check('class A extends Unresolved {}');
    await check('List<Unresolved> v;');
  }

  Future<void> test_sort() async {
    await _computeUnitAndErrors(r'''
library lib;

export 'dart:bbb';
import 'dart:bbb';
export 'package:bbb/bbb.dart';
export 'http://bbb.com';
import 'bbb/bbb.dart';
export 'http://aaa.com';
import 'http://bbb.com';
export 'dart:aaa';
export 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
export 'aaa/aaa.dart';
export 'bbb/bbb.dart';
import 'dart:aaa';
import 'package:aaa/aaa.dart';
import 'aaa/aaa.dart';
import 'http://aaa.com';
part 'bbb/bbb.dart';
part 'aaa/aaa.dart';

void f() {
}
''');
    // validate change
    _assertOrganize(r'''
library lib;

import 'dart:aaa';
import 'dart:bbb';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';

import 'http://aaa.com';
import 'http://bbb.com';

import 'aaa/aaa.dart';
import 'bbb/bbb.dart';

export 'dart:aaa';
export 'dart:bbb';

export 'package:aaa/aaa.dart';
export 'package:bbb/bbb.dart';

export 'http://aaa.com';
export 'http://bbb.com';

export 'aaa/aaa.dart';
export 'bbb/bbb.dart';

part 'aaa/aaa.dart';
part 'bbb/bbb.dart';

void f() {
}
''');
  }

  Future<void> test_sort_commentsAnnotations_library() async {
    await _computeUnitAndErrors(r'''
// Library docs 1
// Library docs 2
library foo;

// Import c comment
@annotation
import 'c.dart'; // Trailing comment C
// Import b comment
@annotation
import 'b.dart'; // Trailing comment B
// Import a comment
@annotation
import 'a.dart'; // Trailing comment A

/** doc */
void f() {
}
''');
    // validate change
    _assertOrganize(r'''
// Library docs 1
// Library docs 2
library foo;

// Import a comment
@annotation
import 'a.dart'; // Trailing comment A
// Import b comment
@annotation
import 'b.dart'; // Trailing comment B
// Import c comment
@annotation
import 'c.dart'; // Trailing comment C

/** doc */
void f() {
}
''');
  }

  Future<void> test_sort_commentsAnnotations_noLibrary() async {
    await _computeUnitAndErrors(r'''
// Library docs 1
// Library docs 2
@annotation
import 'c.dart'; // Trailing comment C
// Import b comment
@annotation
import 'b.dart'; // Trailing comment B
// Import a comment
@annotation
import 'a.dart'; // Trailing comment A

/** doc */
void f() {
}
''');
    // validate change
    _assertOrganize(r'''
// Library docs 1
// Library docs 2
// Import a comment
@annotation
import 'a.dart'; // Trailing comment A
// Import b comment
@annotation
import 'b.dart'; // Trailing comment B
@annotation
import 'c.dart'; // Trailing comment C

/** doc */
void f() {
}
''');
  }

  Future<void> test_sort_documentationAnnotations_library() async {
    await _computeUnitAndErrors(r'''
/// Library docs 1
/// Library docs 2
library foo;

/// Import c docs
@annotation
import 'c.dart'; // Trailing comment C
/// Import b docs
@annotation
import 'b.dart'; // Trailing comment B
/// Import a docs
@annotation
import 'a.dart'; // Trailing comment A

/** doc */
void f() {
}
''');
    // validate change
    _assertOrganize(r'''
/// Library docs 1
/// Library docs 2
library foo;

/// Import a docs
@annotation
import 'a.dart'; // Trailing comment A
/// Import b docs
@annotation
import 'b.dart'; // Trailing comment B
/// Import c docs
@annotation
import 'c.dart'; // Trailing comment C

/** doc */
void f() {
}
''');
  }

  Future<void> test_sort_documentationAnnotations_noLibrary() async {
    await _computeUnitAndErrors(r'''
/// Library docs 1
/// Library docs 2
@annotation
import 'c.dart'; // Trailing comment C
/// Import b docs
@annotation
import 'b.dart'; // Trailing comment B
/// Import a docs
@annotation
import 'a.dart'; // Trailing comment A

/** doc */
void f() {
}
''');
    // validate change
    _assertOrganize(r'''
/// Library docs 1
/// Library docs 2
/// Import a docs
@annotation
import 'a.dart'; // Trailing comment A
/// Import b docs
@annotation
import 'b.dart'; // Trailing comment B
@annotation
import 'c.dart'; // Trailing comment C

/** doc */
void f() {
}
''');
  }

  Future<void> test_sort_hasComments() async {
    await _computeUnitAndErrors(r'''
// header
library lib;

import 'c.dart';// c
import 'a.dart';// aa
import 'b.dart';// bbb

/** doc */
void f() {
}
''');
    // validate change
    _assertOrganize(r'''
// header
library lib;

import 'a.dart';// aa
import 'b.dart';// bbb
import 'c.dart';// c

/** doc */
void f() {
}
''');
  }

  Future<void> test_sort_imports_blankLinesInImportComments() async {
    // Only the blank line in the first import is treated specially and split.
    await _computeUnitAndErrors(r'''
// Import 1 comment 1

// Import 1 comment 2
import 'package:b/a.dart';
// Import 2 comment 1

// Import 2 comment 2
import 'package:a/b.dart';''');
    _assertOrganize(r'''
// Import 1 comment 1

// Import 2 comment 1

// Import 2 comment 2
import 'package:a/b.dart';
// Import 1 comment 2
import 'package:b/a.dart';''');
  }

  Future<void> test_sort_imports_keepFirstCommentUntouched() async {
    await _computeUnitAndErrors(r'''
// Copyright
// Copyright2
// Copyright3
import 'package:b/a.dart';
import 'package:a/b.dart';''');

    _assertOrganize(r'''
// Copyright
// Copyright2
// Copyright3
import 'package:a/b.dart';
import 'package:b/a.dart';''');
  }

  Future<void> test_sort_imports_keepSubsequentComments() async {
    await _computeUnitAndErrors(r'''
/// Copyright...
library lib;

import 'package:b/a.dart'; // We are keeping this because ...
import 'package:a/b.dart';''');
    _assertOrganize(r'''
/// Copyright...
library lib;

import 'package:a/b.dart';
import 'package:b/a.dart'; // We are keeping this because ...''');
  }

  Future<void> test_sort_imports_packageAndPath() async {
    await _computeUnitAndErrors(r'''
library lib;

import 'package:product.ui.api.bbb/manager1.dart';
import 'package:product.ui.api/entity2.dart';
import 'package:product.ui/entity.dart';
import 'package:product.ui.api.aaa/manager2.dart';
import 'package:product.ui.api/entity1.dart';
import 'package:product2.client/entity.dart';
''');
    // validate change
    _assertOrganize(r'''
library lib;

import 'package:product.ui/entity.dart';
import 'package:product.ui.api/entity1.dart';
import 'package:product.ui.api/entity2.dart';
import 'package:product.ui.api.aaa/manager2.dart';
import 'package:product.ui.api.bbb/manager1.dart';
import 'package:product2.client/entity.dart';
''');
  }

  Future<void> test_sort_imports_splits_comments() async {
    // Here, the comments "b" and "ccc1" will be part of the same list
    // of comments so need to be split.
    await _computeUnitAndErrors(r'''
// copyright
import 'b.dart'; // b
// ccc1
// ccc2
import 'c.dart'; // c
// aaa1
// aaa2
import 'a.dart'; // a
''');

    _assertOrganize(r'''
// copyright
// aaa1
// aaa2
import 'a.dart'; // a
import 'b.dart'; // b
// ccc1
// ccc2
import 'c.dart'; // c
''');
  }

  Future<void>
      test_sort_imports_with_library_blankLineInImportComments() async {
    await _computeUnitAndErrors(r'''
/// Copyright...
library lib;

// Test comment

// We are keeping this because ... l1
// We are keeping this because ... l2
// We are keeping this because ... l3
import 'package:b/a.dart';
// Comment for a

import 'package:a/b.dart';''');

    _assertOrganize(r'''
/// Copyright...
library lib;

// Comment for a

import 'package:a/b.dart';
// Test comment

// We are keeping this because ... l1
// We are keeping this because ... l2
// We are keeping this because ... l3
import 'package:b/a.dart';''');
  }

  Future<void> test_sort_libraryAnnotation_movedDirective() async {
    await _addAnnotationsFile();
    await _computeUnitAndErrors(r'''
@libraryAnnotation
@LibraryAnnotation()

// annotations
import 'annotations.dart';

// io
import 'dart:io';
''');
    // Validate annotation is not moved with import.
    _assertOrganize(r'''
@libraryAnnotation
@LibraryAnnotation()

// io
import 'dart:io';

// annotations
import 'annotations.dart';
''');
  }

  Future<void> test_sort_libraryAnnotation_removedDirective() async {
    await _addAnnotationsFile();
    await _computeUnitAndErrors(r'''
@libraryAnnotation
@LibraryAnnotation()

// io
import 'dart:io'; // unused
// annotations
import 'annotations.dart'; // used
''');
    // Validate annotation is not removed with import.
    _assertOrganize(r'''
@libraryAnnotation
@LibraryAnnotation()

// annotations
import 'annotations.dart'; // used
''', removeUnused: true);
  }

  Future<void> test_sort_multipleAnnotation_movedDirective() async {
    await _addAnnotationsFile();
    await _computeUnitAndErrors(r'''
@libraryAnnotation
@LibraryAnnotation()

@nonLibraryAnnotation
import 'annotations.dart';
@nonLibraryAnnotation
import 'dart:io';
''');
    // Validate only the non-library annotation is moved with import.
    _assertOrganize(r'''
@libraryAnnotation
@LibraryAnnotation()

@nonLibraryAnnotation
import 'dart:io';

@nonLibraryAnnotation
import 'annotations.dart';
''');
  }

  Future<void> test_sort_multipleAnnotation_removedDirective() async {
    await _addAnnotationsFile();
    await _computeUnitAndErrors(r'''
@libraryAnnotation
@LibraryAnnotation()

@nonLibraryAnnotation
import 'dart:io';
@nonLibraryAnnotation
import 'annotations.dart';
''');
    // Validate only the non-library annotation is removed with import.
    _assertOrganize(r'''
@libraryAnnotation
@LibraryAnnotation()

@nonLibraryAnnotation
import 'annotations.dart';
''', removeUnused: true);
  }

  Future<void> test_sort_multipleAnnotationWithComments_movedDirective() async {
    await _addAnnotationsFile();
    await _computeUnitAndErrors(r'''
// lib1
@libraryAnnotation // lib1
// lib2
@LibraryAnnotation() // lib2

// nonLib on annotations import
@nonLibraryAnnotation // nonLib on annotations import
// annotations import
import 'annotations.dart'; // annotations import
// nonLib on io import
@nonLibraryAnnotation // nonLib on io import
// io import
import 'dart:io'; // io import
''');
    // Validate only the non-library annotation is moved with import.
    _assertOrganize(r'''
// lib1
@libraryAnnotation // lib1
// lib2
@LibraryAnnotation() // lib2

// nonLib on io import
@nonLibraryAnnotation // nonLib on io import
// io import
import 'dart:io'; // io import

// nonLib on annotations import
@nonLibraryAnnotation // nonLib on annotations import
// annotations import
import 'annotations.dart'; // annotations import
''');
  }

  Future<void>
      test_sort_multipleAnnotationWithComments_removedDirective() async {
    await _addAnnotationsFile();
    await _computeUnitAndErrors(r'''
// lib1
@libraryAnnotation // lib1
// lib2
@LibraryAnnotation() // lib2

// nonLib on io import
@nonLibraryAnnotation // nonLib on io import
// io import
import 'dart:io'; // io import
// nonLib on annotations import
@nonLibraryAnnotation // nonLib on annotations import
// annotations import
import 'annotations.dart'; // annotations import
''');
    // Validate only the non-library annotation is removed with import.
    _assertOrganize(r'''
// lib1
@libraryAnnotation // lib1
// lib2
@LibraryAnnotation() // lib2

// nonLib on annotations import
@nonLibraryAnnotation // nonLib on annotations import
// annotations import
import 'annotations.dart'; // annotations import
''', removeUnused: true);
  }

  Future<void> test_sort_nonLibraryAnnotation_movedDirective() async {
    await _addAnnotationsFile();
    await _computeUnitAndErrors(r'''
@nonLibraryAnnotation
import 'annotations.dart';

import 'dart:io';
''');
    // Validate annotation is moved with import.
    _assertOrganize(r'''
import 'dart:io';

@nonLibraryAnnotation
import 'annotations.dart';
''');
  }

  Future<void> test_sort_nonLibraryAnnotation_removedDirective() async {
    await _addAnnotationsFile();
    await _computeUnitAndErrors(r'''
@nonLibraryAnnotation
// io
import 'dart:io'; // unused
// annotations
import 'annotations.dart'; // used
''');
    // Validate annotation is removed with import.
    _assertOrganize(r'''
// annotations
import 'annotations.dart'; // used
''', removeUnused: true);
  }

  Future<void> _addAnnotationsFile() async {
    final annotationsFile = convertPath('$testPackageLibPath/annotations.dart');
    const annotationsContent = '''
import 'package:meta/meta_meta.dart';

const libraryAnnotation = LibraryAnnotation();
const nonLibraryAnnotation = NonLibraryAnnotation();

@Target({TargetKind.library})
class LibraryAnnotation {
  const LibraryAnnotation();
}

@Target({TargetKind.classType})
class NonLibraryAnnotation {
  const NonLibraryAnnotation();
}
    ''';
    newFile(annotationsFile, annotationsContent);
  }

  void _assertOrganize(String expectedCode, {bool removeUnused = false}) {
    var organizer = ImportOrganizer(testCode, testUnit, testErrors,
        removeUnused: removeUnused);
    var edits = organizer.organize();
    var result = SourceEdit.applySequence(testCode, edits);
    expect(result, expectedCode);
  }

  Future<void> _computeUnitAndErrors(String code) async {
    addTestSource(code);
    verifyNoTestUnitErrors = false;
    var result = await getResolvedUnit(testFile);
    testUnit = result.unit;
    testErrors = result.errors;
  }
}
