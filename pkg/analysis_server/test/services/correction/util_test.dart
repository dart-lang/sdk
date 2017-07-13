// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UtilTest);
  });
}

@reflectiveTest
class UtilTest extends AbstractSingleUnitTest {
  test_addLibraryImports_dart_hasImports_between() async {
    await resolveTestUnit('''
import 'dart:async';
import 'dart:math';
''');
    Source newLibrary = _getDartSource('dart:collection');
    _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_first() async {
    await resolveTestUnit('''
import 'dart:collection';
import 'dart:math';
''');
    Source newLibrary = _getDartSource('dart:async');
    _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_last() async {
    await resolveTestUnit('''
import 'dart:async';
import 'dart:collection';
''');
    Source newLibrary = _getDartSource('dart:math');
    _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_multiple() async {
    await resolveTestUnit('''
import 'dart:collection';
import 'dart:math';
''');
    Source newLibrary1 = _getDartSource('dart:async');
    Source newLibrary2 = _getDartSource('dart:html');
    _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_multiple_first() async {
    await resolveTestUnit('''
import 'dart:html';
import 'dart:math';
''');
    Source newLibrary1 = _getDartSource('dart:async');
    Source newLibrary2 = _getDartSource('dart:collection');
    _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasImports_multiple_last() async {
    await resolveTestUnit('''
import 'dart:async';
import 'dart:collection';
''');
    Source newLibrary1 = _getDartSource('dart:html');
    Source newLibrary2 = _getDartSource('dart:math');
    _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''');
  }

  test_addLibraryImports_dart_hasLibraryDirective() async {
    await resolveTestUnit('''
library test;

class A {}
''');
    Source newLibrary1 = _getDartSource('dart:math');
    Source newLibrary2 = _getDartSource('dart:async');
    _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
library test;

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  test_addLibraryImports_dart_noDirectives_hasComment() async {
    await resolveTestUnit('''
/// Comment.

class A {}
''');
    Source newLibrary1 = _getDartSource('dart:math');
    Source newLibrary2 = _getDartSource('dart:async');
    _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
/// Comment.

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  test_addLibraryImports_dart_noDirectives_hasShebang() async {
    await resolveTestUnit('''
#!/bin/dart

class A {}
''');
    Source newLibrary1 = _getDartSource('dart:math');
    Source newLibrary2 = _getDartSource('dart:async');
    _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
#!/bin/dart

import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  test_addLibraryImports_dart_noDirectives_noShebang() async {
    await resolveTestUnit('''
class A {}
''');
    Source newLibrary1 = _getDartSource('dart:math');
    Source newLibrary2 = _getDartSource('dart:async');
    _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'dart:async';
import 'dart:math';

class A {}
''');
  }

  test_addLibraryImports_package_hasDart_hasPackages_insertAfter() async {
    addPackageSource('aaa', 'aaa.dart', '');
    await resolveTestUnit('''
import 'dart:async';

import 'package:aaa/aaa.dart';
''');
    Source newLibrary = _getSource('/lib/bbb.dart', 'package:bbb/bbb.dart');
    _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''');
  }

  test_addLibraryImports_package_hasDart_hasPackages_insertBefore() async {
    addPackageSource('bbb', 'bbb.dart', '');
    await resolveTestUnit('''
import 'dart:async';

import 'package:bbb/bbb.dart';
''');
    Source newLibrary = _getSource('/lib/aaa.dart', 'package:aaa/aaa.dart');
    _assertAddLibraryImport(<Source>[newLibrary], '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''');
  }

  test_addLibraryImports_package_hasImports_between() async {
    addPackageSource('aaa', 'aaa.dart', '');
    addPackageSource('ddd', 'ddd.dart', '');
    await resolveTestUnit('''
import 'package:aaa/aaa.dart';
import 'package:ddd/ddd.dart';
''');
    Source newLibrary1 = _getSource('/lib/bbb.dart', 'package:bbb/bbb.dart');
    Source newLibrary2 = _getSource('/lib/ccc.dart', 'package:ccc/ccc.dart');
    _assertAddLibraryImport(<Source>[newLibrary1, newLibrary2], '''
import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
import 'package:ddd/ddd.dart';
''');
  }

  void _assertAddLibraryImport(List<Source> newLibraries, String expectedCode) {
    SourceChange change = new SourceChange('');
    addLibraryImports(change, testLibraryElement, newLibraries.toSet());
    SourceFileEdit testEdit = change.getFileEdit(testFile);
    expect(testEdit, isNotNull);
    String resultCode = SourceEdit.applySequence(testCode, testEdit.edits);
    expect(resultCode, expectedCode);
  }

  Source _getDartSource(String uri) {
    String path = removeStart(uri, 'dart:');
    return new _SourceMock('/sdk/lib/$path.dart', Uri.parse(uri));
  }

  Source _getSource(String path, String uri) {
    return new _SourceMock(path, Uri.parse(uri));
  }
}

class _SourceMock implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _SourceMock(this.fullName, this.uri);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
