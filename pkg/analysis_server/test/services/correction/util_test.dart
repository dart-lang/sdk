// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';
import '../../src/services/correction/assist/assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UtilTest);
  });
}

@reflectiveTest
class UtilTest extends AbstractSingleUnitTest {
  Future<void> assert_invertCondition(String expr, String expected) async {
    await resolveTestCode('''
main() {
  int v1, v2, v3, v4, v5;
  bool b1, b2, b3, b4, b5;
  if ($expr) {
    0;
  } else {
    1;
  }
}
''');
    IfStatement ifStatement = findNodeAtString('if (');
    var condition = ifStatement.condition;
    var result = CorrectionUtils(testAnalysisResult).invertCondition(condition);
    expect(result, expected);
    // For compactness we put multiple cases into one test method.
    // Prepare for resolving the test file one again.
    changeFile(testFile);
  }

  Future<void> test_addLibraryImports_dart_hasImports_between() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:math';
''');
    var newLibrary = _getDartSource('dart:collection');
    await _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  Future<void> test_addLibraryImports_dart_hasImports_first() async {
    await resolveTestCode('''
import 'dart:collection';
import 'dart:math';
''');
    var newLibrary = _getDartSource('dart:async');
    await _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  Future<void> test_addLibraryImports_dart_hasImports_last() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:collection';
''');
    var newLibrary = _getDartSource('dart:math');
    await _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  Future<void> test_addLibraryImports_dart_hasImports_multiple() async {
    await resolveTestCode('''
import 'dart:collection';
import 'dart:math';
''');
    var newLibrary1 = _getDartSource('dart:async');
    var newLibrary2 = _getDartSource('dart:html');
    await _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  Future<void> test_addLibraryImports_dart_hasImports_multiple_first() async {
    await resolveTestCode('''
import 'dart:html';
import 'dart:math';
''');
    var newLibrary1 = _getDartSource('dart:async');
    var newLibrary2 = _getDartSource('dart:collection');
    await _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  Future<void> test_addLibraryImports_dart_hasImports_multiple_last() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:collection';
''');
    var newLibrary1 = _getDartSource('dart:html');
    var newLibrary2 = _getDartSource('dart:math');
    await _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  Future<void> test_addLibraryImports_dart_hasLibraryDirective() async {
    await resolveTestCode('''
library test;

class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
library test;

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  Future<void> test_addLibraryImports_dart_noDirectives_hasComment() async {
    await resolveTestCode('''
/// Comment.

class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
/// Comment.

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  Future<void> test_addLibraryImports_dart_noDirectives_hasShebang() async {
    await resolveTestCode('''
#!/bin/dart

class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
#!/bin/dart

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  Future<void> test_addLibraryImports_dart_noDirectives_noShebang() async {
    await resolveTestCode('''
class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  Future<void>
      test_addLibraryImports_package_hasDart_hasPackages_insertAfter() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa')
        ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb'),
    );

    await resolveTestCode('''
import 'dart:async';

import 'package:aaa/aaa.dart';
''');
    var newLibrary = _getSource('/lib/bbb.dart', 'package:bbb/bbb.dart');
    await _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''');
  }

  Future<void>
      test_addLibraryImports_package_hasDart_hasPackages_insertBefore() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa')
        ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb'),
    );

    await resolveTestCode('''
import 'dart:async';

import 'package:bbb/bbb.dart';
''');
    var newLibrary = _getSource('/lib/aaa.dart', 'package:aaa/aaa.dart');
    await _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''');
  }

  Future<void> test_addLibraryImports_package_hasImports_between() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart');
    newFile('$workspaceRootPath/ccc/lib/ccc.dart');
    newFile('$workspaceRootPath/ddd/lib/ddd.dart');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa')
        ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb')
        ..add(name: 'ccc', rootPath: '$workspaceRootPath/ccc')
        ..add(name: 'ddd', rootPath: '$workspaceRootPath/ddd'),
    );

    await resolveTestCode('''
import 'package:aaa/aaa.dart';
import 'package:ddd/ddd.dart';
''');
    var newLibrary1 = _getSource('/lib/bbb.dart', 'package:bbb/bbb.dart');
    var newLibrary2 = _getSource('/lib/ccc.dart', 'package:ccc/ccc.dart');
    await _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
import 'package:ddd/ddd.dart';
''');
  }

  Future<void> test_invertCondition_binary_compare() async {
    await assert_invertCondition('0 < 1', '0 >= 1');
    await assert_invertCondition('0 > 1', '0 <= 1');
    await assert_invertCondition('0 <= 1', '0 > 1');
    await assert_invertCondition('0 >= 1', '0 < 1');
    await assert_invertCondition('0 == 1', '0 != 1');
    await assert_invertCondition('0 != 1', '0 == 1');
  }

  Future<void> test_invertCondition_binary_compare_boolean() async {
    await assert_invertCondition('b1 == null', 'b1 != null');
    await assert_invertCondition('b1 != null', 'b1 == null');
  }

  Future<void> test_invertCondition_binary_logical() async {
    await assert_invertCondition('b1 && b2', '!b1 || !b2');
    await assert_invertCondition('!b1 && !b2', 'b1 || b2');
    await assert_invertCondition('b1 || b2', '!b1 && !b2');
    await assert_invertCondition('!b1 || !b2', 'b1 && b2');
  }

  Future<void> test_invertCondition_complex() async {
    await assert_invertCondition('b1 && b2 || b3', '(!b1 || !b2) && !b3');
    await assert_invertCondition('b1 || b2 && b3', '!b1 && (!b2 || !b3)');
    await assert_invertCondition('(!b1 || !b2) && !b3', 'b1 && b2 || b3');
    await assert_invertCondition('!b1 && (!b2 || !b3)', 'b1 || b2 && b3');
  }

  Future<void> test_invertCondition_is() async {
    await assert_invertCondition('v1 is int', 'v1 is! int');
    await assert_invertCondition('v1 is! int', 'v1 is int');
  }

  Future<void> test_invertCondition_literal() async {
    await assert_invertCondition('true', 'false');
    await assert_invertCondition('false', 'true');
  }

  Future<void> test_invertCondition_not() async {
    await assert_invertCondition('b1', '!b1');
    await assert_invertCondition('!b1', 'b1');
    await assert_invertCondition('!((b1))', 'b1');
    await assert_invertCondition('(((b1)))', '!b1');
  }

  Future<void> _assertAddLibraryImport(
      List<Source> newLibraries, String expectedCode) async {
    var change = SourceChange('');
    await addLibraryImports(testAnalysisResult.session, change,
        testLibraryElement, newLibraries.toSet());
    var testEdit = change.getFileEdit(testFile);
    expect(testEdit, isNotNull);
    var resultCode = SourceEdit.applySequence(testCode, testEdit.edits);
    expect(resultCode, expectedCode);
  }

  Source _getDartSource(String uri) {
    var path = removeStart(uri, 'dart:');
    return _SourceMock('/sdk/lib/$path.dart', Uri.parse(uri));
  }

  Source _getSource(String path, String uri) {
    return _SourceMock(path, Uri.parse(uri));
  }
}

class _SourceMock implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _SourceMock(this.fullName, this.uri);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
