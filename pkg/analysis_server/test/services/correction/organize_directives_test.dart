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
  List<AnalysisError> testErrors;

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

  Future<void> test_keep_duplicateImports_withDifferentPrefix() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async1;
import 'dart:async' as async2;

main() {
  async1.Future f;
  async2.Stream s;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async' as async1;
import 'dart:async' as async2;

main() {
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

  Future<void> test_remove_duplicateImports() async {
    await _computeUnitAndErrors(r'''
import 'dart:async';
import 'dart:async';

main() {
  Completer f;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async';

main() {
  Completer f;
}''', removeUnused: true);
  }

  Future<void> test_remove_duplicateImports_differentText_uri() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async;
import "dart:async" as async;

main() {
  async.Future f;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async' as async;

main() {
  async.Future f;
}''', removeUnused: true);
  }

  Future<void> test_remove_duplicateImports_withSamePrefix() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async;
import 'dart:async' as async;

main() {
  async.Future f;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async' as async;

main() {
  async.Future f;
}''', removeUnused: true);
  }

  Future<void> test_remove_unusedImports() async {
    await _computeUnitAndErrors(r'''
library lib;

import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:collection';

main() {
  print(pi);
  new HashMap();
}
''');
    // validate change
    _assertOrganize(r'''
library lib;

import 'dart:collection';
import 'dart:math';

main() {
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

main() {
  Completer f;
}''');
    // validate change
    _assertOrganize(r'''
import 'dart:async';

class A {}

main() {
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

    await check('main() { Unresolved v; }');
    await check('main() { new Unresolved(); }');
    await check('main() { const Unresolved(); }');
    await check('main() { unresolvedFunction(); }');
    await check('main() { print(unresolvedVariable); }');
    await check('main() { unresolvedVariable = 0; }');
    await check('main() { Unresolved.field = 0; }');
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

main() {
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

main() {
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
main() {
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
main() {
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
main() {
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
main() {
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
main() {
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
main() {
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
main() {
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
main() {
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
main() {
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
main() {
}
''');
  }

  Future<void>
      test_sort_imports_dontConnectFirstCommentsWithBlankLinesBetween() async {
    await _computeUnitAndErrors(r'''
// Copyright...

// Some comment related to the line below
import 'package:b/a.dart';
import 'package:a/b.dart';''');
    _assertOrganize(r'''
// Copyright...

import 'package:a/b.dart';
// Some comment related to the line below
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

  Future<void> test_sort_imports_with_library_keepPrecedingComments() async {
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

// Test comment

// Comment for a

import 'package:a/b.dart';
// We are keeping this because ... l1
// We are keeping this because ... l2
// We are keeping this because ... l3
import 'package:b/a.dart';''');
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
    var result = await session.getResolvedUnit(testFile);
    testUnit = result.unit;
    testErrors = result.errors;
  }
}
