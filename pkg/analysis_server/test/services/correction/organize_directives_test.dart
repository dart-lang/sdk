// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/correction/organize_directives.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeDirectivesTest);
  });
}

@reflectiveTest
class OrganizeDirectivesTest extends AbstractSingleUnitTest {
  List<AnalysisError> testErrors;

  test_keep_duplicateImports_withDifferentPrefix() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async1;
import 'dart:async' as async2;

main() {
  async1.Future f;
  async2.Stream s;
}''');
    // validate change
    _assertOrganize(
        r'''
import 'dart:async' as async1;
import 'dart:async' as async2;

main() {
  async1.Future f;
  async2.Stream s;
}''',
        removeUnresolved: true,
        removeUnused: true);
  }

  test_remove_duplicateImports() async {
    await _computeUnitAndErrors(r'''
import 'dart:async';
import 'dart:async';

main() {
  Future f;
}''');
    // validate change
    _assertOrganize(
        r'''
import 'dart:async';

main() {
  Future f;
}''',
        removeUnresolved: true,
        removeUnused: true);
  }

  test_remove_duplicateImports_differentText_uri() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async;
import "dart:async" as async;

main() {
  async.Future f;
}''');
    // validate change
    _assertOrganize(
        r'''
import 'dart:async' as async;

main() {
  async.Future f;
}''',
        removeUnresolved: true,
        removeUnused: true);
  }

  test_remove_duplicateImports_withSamePrefix() async {
    await _computeUnitAndErrors(r'''
import 'dart:async' as async;
import 'dart:async' as async;

main() {
  async.Future f;
}''');
    // validate change
    _assertOrganize(
        r'''
import 'dart:async' as async;

main() {
  async.Future f;
}''',
        removeUnresolved: true,
        removeUnused: true);
  }

  test_remove_unresolvedDirectives() async {
    addSource('/existing_part1.dart', 'part of lib;');
    addSource('/existing_part2.dart', 'part of lib;');
    await _computeUnitAndErrors(r'''
library lib;

import 'dart:async';
import 'dart:noSuchImportSdkLibrary';
import 'dart:math';
import 'package:noSuchImportPackage/andLib.dart';

export 'dart:noSuchExportSdkLibrary';
export 'dart:async';
export 'package:noSuchExportPackage/andLib.dart';
export 'dart:math';

part 'existing_part1.dart';
part 'no_such_part.dart';
part 'existing_part2.dart';

main() {
}
''');
    // validate change
    _assertOrganize(
        r'''
library lib;

import 'dart:async';
import 'dart:math';

export 'dart:async';
export 'dart:math';

part 'existing_part1.dart';
part 'existing_part2.dart';

main() {
}
''',
        removeUnresolved: true);
  }

  test_remove_unusedImports() async {
    await _computeUnitAndErrors(r'''
library lib;

import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:collection';

main() {
  print(PI);
  new HashMap();
}
''');
    // validate change
    _assertOrganize(
        r'''
library lib;

import 'dart:collection';
import 'dart:math';

main() {
  print(PI);
  new HashMap();
}
''',
        removeUnused: true);
  }

  test_remove_unusedImports2() async {
    await _computeUnitAndErrors(r'''
import 'dart:async';
import 'dart:math';

class A {}

main() {
  Future f;
}''');
    // validate change
    _assertOrganize(
        r'''
import 'dart:async';

class A {}

main() {
  Future f;
}''',
        removeUnresolved: true,
        removeUnused: true);
  }

  test_sort() async {
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

  test_sort_hasComments() async {
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

import 'a.dart';
import 'b.dart';
import 'c.dart';
// c
// aa
// bbb

/** doc */
main() {
}
''');
  }

  test_sort_imports_packageAndPath() async {
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

  void _assertOrganize(String expectedCode,
      {bool removeUnresolved: false, bool removeUnused: false}) {
    DirectiveOrganizer organizer = new DirectiveOrganizer(
        testCode, testUnit, testErrors,
        removeUnresolved: removeUnresolved, removeUnused: removeUnused);
    List<SourceEdit> edits = organizer.organize();
    String result = SourceEdit.applySequence(testCode, edits);
    expect(result, expectedCode);
  }

  Future<Null> _computeUnitAndErrors(String code) async {
    addTestSource(code);
    AnalysisResult result = await driver.getResult(testSource.fullName);
    testUnit = result.unit;
    testErrors = result.errors;
  }
}
