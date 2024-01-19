// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';
import '../../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UtilTest);
    defineReflectiveTests(CorrectionUtilsTest);
  });
}

@reflectiveTest
class CorrectionUtilsTest extends AbstractSingleUnitTest {
  Future<void> assertReplacedIndentation(
    String source,
    String expected, {
    String indentOld = '  ',
    String indentNew = '    ',
    bool includeLeading = false,
    bool ensureTrailingNewline = false,
  }) async {
    // Use strings as-is, because tests are explicit and cover both kinds of eols.
    useLineEndingsForPlatform = false;
    await parseTestCode(source);
    final util = CorrectionUtils(testParsedResult);
    final actual = util.replaceSourceIndent(
      testCode,
      indentOld,
      indentNew,
      includeLeading: includeLeading,
      ensureTrailingNewline: ensureTrailingNewline,
    );
    expect(actual, expected);
  }

  Future<void> test_replaceSourceIndent_leading_empty_crlf() async {
    await assertReplacedIndentation(
      includeLeading: true,
      indentOld: '',
      indentNew: '  ',
      'a\r\nb\r\nc',
      '  a\r\n  b\r\n  c',
    );
  }

  Future<void> test_replaceSourceIndent_leading_empty_lf() async {
    await assertReplacedIndentation(
      includeLeading: true,
      indentOld: '',
      indentNew: '  ',
      'a\nb\nc',
      '  a\n  b\n  c',
    );
  }

  Future<void> test_replaceSourceIndent_leading_nonEmpty_crlf() async {
    await assertReplacedIndentation(
      includeLeading: true,
      '  a\r\n  b\r\n  c',
      '    a\r\n    b\r\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_leading_nonEmpty_lf() async {
    await assertReplacedIndentation(
      includeLeading: true,
      '  a\n  b\n  c',
      '    a\n    b\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_noLeading_empty_crlf() async {
    await assertReplacedIndentation(
      indentOld: '',
      indentNew: '  ',
      'a\r\nb\r\nc',
      'a\r\n  b\r\n  c',
    );
  }

  Future<void> test_replaceSourceIndent_noLeading_empty_lf() async {
    await assertReplacedIndentation(
      indentOld: '',
      indentNew: '  ',
      'a\nb\nc',
      'a\n  b\n  c',
    );
  }

  Future<void> test_replaceSourceIndent_noLeading_nonEmpty_crlf() async {
    await assertReplacedIndentation(
      '  a\r\n  b\r\n  c',
      '  a\r\n    b\r\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_noLeading_nonEmpty_lf() async {
    await assertReplacedIndentation(
      '  a\n  b\n  c',
      '  a\n    b\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_noTrailing_crlf() async {
    await assertReplacedIndentation(
      '  a\r\n  b\r\n  c',
      '  a\r\n    b\r\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_noTrailing_lf() async {
    await assertReplacedIndentation(
      '  a\n  b\n  c',
      '  a\n    b\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_trailing_added_crlf() async {
    await assertReplacedIndentation(
      ensureTrailingNewline: true,
      '  a\r\n  b\r\n  c',
      '  a\r\n    b\r\n    c\r\n',
    );
  }

  Future<void> test_replaceSourceIndent_trailing_added_lf() async {
    await assertReplacedIndentation(
      ensureTrailingNewline: true,
      '  a\n  b\n  c',
      '  a\n    b\n    c\n',
    );
  }

  Future<void> test_replaceSourceIndent_trailing_existing_added_lf() async {
    await assertReplacedIndentation(
      ensureTrailingNewline: true,
      '  a\n  b\n  c\n',
      '  a\n    b\n    c\n',
    );
  }

  Future<void> test_replaceSourceIndent_trailing_existing_crlf() async {
    await assertReplacedIndentation(
      ensureTrailingNewline: true,
      '  a\r\n  b\r\n  c\r\n',
      '  a\r\n    b\r\n    c\r\n',
    );
  }
}

@reflectiveTest
class UtilTest extends AbstractSingleUnitTest {
  Future<void> assert_invertCondition(String expr, String expected) async {
    await resolveTestCode('''
void f(bool? b4, bool? b5) {
  int? v1, v2, v3, v4, v5;
  bool b1 = true, b2 = true, b3 = true;
  if ($expr) {
    0;
  } else {
    1;
  }
}
''');
    var ifStatement = findNode.ifStatement('if (');
    var condition = ifStatement.expression;
    var result = CorrectionUtils(testAnalysisResult).invertCondition(condition);
    expect(result, expected);
    // For compactness we put multiple cases into one test method.
    // Prepare for resolving the test file one again.
    changeFile(testFile);
  }

  Future<void> test_addLibraryImports_dart_doubleQuotes() async {
    registerLintRules();
    var config = AnalysisOptionsFileConfig(
      lints: ['prefer_double_quotes'],
    );
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      config.toContent(),
    );

    await resolveTestCode('''
/// Comment.

class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
/// Comment.

import "dart:async";
import "dart:math";

class A {}
''');
  }

  Future<void> test_addLibraryImports_dart_hasImports_between() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:math';
''');
    var newLibrary = _getDartSource('dart:collection');
    await _assertAddLibraryImport([newLibrary], '''
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
    await _assertAddLibraryImport([newLibrary], '''
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
    await _assertAddLibraryImport([newLibrary], '''
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
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
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
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
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
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
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
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
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
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
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
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
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
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  Future<void>
      test_addLibraryImports_package_hasDart_hasPackages_insertAfter() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart', '');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart', '');

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
    await _assertAddLibraryImport([newLibrary], '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''');
  }

  Future<void>
      test_addLibraryImports_package_hasDart_hasPackages_insertBefore() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart', '');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart', '');

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
    await _assertAddLibraryImport([newLibrary], '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''');
  }

  Future<void> test_addLibraryImports_package_hasImports_between() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart', '');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart', '');
    newFile('$workspaceRootPath/ccc/lib/ccc.dart', '');
    newFile('$workspaceRootPath/ddd/lib/ddd.dart', '');

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
    await _assertAddLibraryImport([newLibrary1, newLibrary2], '''
import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
import 'package:ddd/ddd.dart';
''');
  }

  Future<void> test_findSimplePrintInvocation() async {
    await resolveTestCode('''
void f() {
  print('hi');
}
''');
    var printIdentifier = findNode.simple('print');
    var expected = findNode.expressionStatement('print');
    var result = CorrectionUtils(testAnalysisResult)
        .findSimplePrintInvocation(printIdentifier);
    expect(result, expected);
  }

  Future<void> test_findSimplePrintInvocation_custom_print() async {
    await resolveTestCode('''
void print(String toPrint) {
}

void f() {
  print('hi');
}
''');
    var printIdentifier = findNode.simple('print(\'hi\'');
    var result = CorrectionUtils(testAnalysisResult)
        .findSimplePrintInvocation(printIdentifier);
    expect(result, null);
  }

  Future<void> test_findSimplePrintInvocation_negative() async {
    await resolveTestCode('''
void f() {
  true ? print('hi') : print('false');
}
''');
    var printIdentifier = findNode.simple('print(\'false');
    var result = CorrectionUtils(testAnalysisResult)
        .findSimplePrintInvocation(printIdentifier);
    expect(result, null);
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
    await assert_invertCondition('b4 == null', 'b4 != null');
    await assert_invertCondition('b4 != null', 'b4 == null');
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
    var testEdit = change.getFileEdit(testFile.path);
    var resultCode = SourceEdit.applySequence(testCode, testEdit!.edits);
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
