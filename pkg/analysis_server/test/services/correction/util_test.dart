// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.util;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_single_unit.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(UtilTest);
}

@reflectiveTest
class UtilTest extends AbstractSingleUnitTest {
  test_addLibraryImports_dart_hasImports_between() {
    resolveTestUnit('''
import 'dart:async';
import 'dart:math';
''');
    LibraryElement newLibrary = _getDartLibrary('dart:collection');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary],
        '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_first() {
    resolveTestUnit('''
import 'dart:collection';
import 'dart:math';
''');
    LibraryElement newLibrary = _getDartLibrary('dart:async');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary],
        '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_last() {
    resolveTestUnit('''
import 'dart:async';
import 'dart:collection';
''');
    LibraryElement newLibrary = _getDartLibrary('dart:math');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary],
        '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_multiple() {
    resolveTestUnit('''
import 'dart:collection';
import 'dart:math';
''');
    LibraryElement newLibrary1 = _getDartLibrary('dart:async');
    LibraryElement newLibrary2 = _getDartLibrary('dart:html');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary1, newLibrary2],
        '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_multiple_first() {
    resolveTestUnit('''
import 'dart:html';
import 'dart:math';
''');
    LibraryElement newLibrary1 = _getDartLibrary('dart:async');
    LibraryElement newLibrary2 = _getDartLibrary('dart:collection');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary1, newLibrary2],
        '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_multiple_last() {
    resolveTestUnit('''
import 'dart:async';
import 'dart:collection';
''');
    LibraryElement newLibrary1 = _getDartLibrary('dart:html');
    LibraryElement newLibrary2 = _getDartLibrary('dart:math');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary1, newLibrary2],
        '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasLibraryDirective() {
    resolveTestUnit('''
library test;

class A {}
''');
    LibraryElement newLibrary1 = _getDartLibrary('dart:math');
    LibraryElement newLibrary2 = _getDartLibrary('dart:async');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary1, newLibrary2],
        '''
library test;

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  test_addLibraryImports_dart_noDirectives_hasComment() {
    resolveTestUnit('''
/// Comment.

class A {}
''');
    LibraryElement newLibrary1 = _getDartLibrary('dart:math');
    LibraryElement newLibrary2 = _getDartLibrary('dart:async');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary1, newLibrary2],
        '''
/// Comment.

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  test_addLibraryImports_dart_noDirectives_hasShebang() {
    resolveTestUnit('''
#!/bin/dart

class A {}
''');
    LibraryElement newLibrary1 = _getDartLibrary('dart:math');
    LibraryElement newLibrary2 = _getDartLibrary('dart:async');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary1, newLibrary2],
        '''
#!/bin/dart

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  test_addLibraryImports_dart_noDirectives_noShebang() {
    resolveTestUnit('''
class A {}
''');
    LibraryElement newLibrary1 = _getDartLibrary('dart:math');
    LibraryElement newLibrary2 = _getDartLibrary('dart:async');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary1, newLibrary2],
        '''
import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  test_addLibraryImports_package_hasDart_hasPackages_insertAfter() {
    resolveTestUnit('''
import 'dart:async';

import 'package:aaa/aaa.dart';
''');
    LibraryElement newLibrary =
        _mockLibraryElement('/lib/bbb.dart', 'package:bbb/bbb.dart');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary],
        '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''');
  }

  test_addLibraryImports_package_hasDart_hasPackages_insertBefore() {
    resolveTestUnit('''
import 'dart:async';

import 'package:bbb/bbb.dart';
''');
    LibraryElement newLibrary =
        _mockLibraryElement('/lib/aaa.dart', 'package:aaa/aaa.dart');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary],
        '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''');
  }

  test_addLibraryImports_package_hasImports_between() {
    resolveTestUnit('''
import 'package:aaa/aaa.dart';
import 'package:ddd/ddd.dart';
''');
    LibraryElement newLibrary1 =
        _mockLibraryElement('/lib/bbb.dart', 'package:bbb/bbb.dart');
    LibraryElement newLibrary2 =
        _mockLibraryElement('/lib/ccc.dart', 'package:ccc/ccc.dart');
    _assertAddLibraryImport(
        <LibraryElement>[newLibrary1, newLibrary2],
        '''
import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
import 'package:ddd/ddd.dart';
''');
  }

  void _assertAddLibraryImport(
      List<LibraryElement> newLibraries, String expectedCode) {
    SourceChange change = new SourceChange('');
    addLibraryImports(change, testLibraryElement, newLibraries.toSet());
    SourceFileEdit testEdit = change.getFileEdit(testFile);
    expect(testEdit, isNotNull);
    String resultCode = SourceEdit.applySequence(testCode, testEdit.edits);
    expect(resultCode, expectedCode);
  }

  LibraryElement _getDartLibrary(String uri) {
    String path = removeStart(uri, 'dart:');
    Source newSource = new _SourceMock('/sdk/lib/$path.dart', Uri.parse(uri));
    return new _LibraryElementMock(newSource);
  }

  LibraryElement _mockLibraryElement(String path, String uri) {
    Source newSource = new _SourceMock(path, Uri.parse(uri));
    return new _LibraryElementMock(newSource);
  }
}

class _LibraryElementMock implements LibraryElement {
  @override
  final Source source;

  _LibraryElementMock(this.source);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SourceMock implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _SourceMock(this.fullName, this.uri);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
