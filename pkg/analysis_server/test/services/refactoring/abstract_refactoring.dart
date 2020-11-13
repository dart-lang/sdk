// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show RefactoringProblemSeverity, SourceChange, SourceEdit;
import 'package:test/test.dart';

import '../../abstract_single_unit.dart';

int findIdentifierLength(String search) {
  var length = 0;
  while (length < search.length) {
    var c = search.codeUnitAt(length);
    if (!(c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0) ||
        c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0) ||
        c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0))) {
      break;
    }
    length++;
  }
  return length;
}

/// The base class for all [Refactoring] tests.
abstract class RefactoringTest extends AbstractSingleUnitTest {
  SearchEngine searchEngine;

  SourceChange refactoringChange;

  Refactoring get refactoring;

  /// Asserts that [refactoringChange] contains a [FileEdit] for the file
  /// with the given [path], and it results the [expectedCode].
  void assertFileChangeResult(String path, String expectedCode) {
    if (useLineEndingsForPlatform) {
      expectedCode = normalizeNewlinesForPlatform(expectedCode);
    }
    // prepare FileEdit
    var fileEdit = refactoringChange.getFileEdit(convertPath(path));
    expect(fileEdit, isNotNull, reason: 'No file edit for $path');
    // validate resulting code
    var file = getFile(path);
    var ini = file.readAsStringSync();
    var actualCode = SourceEdit.applySequence(ini, fileEdit.edits);
    expect(actualCode, expectedCode);
  }

  /// Asserts that [refactoringChange] does not contain a [FileEdit] for the
  /// file with the given [path].
  void assertNoFileChange(String path) {
    var fileEdit = refactoringChange.getFileEdit(path);
    expect(fileEdit, isNull);
  }

  /// Asserts that [refactoring] initial/final conditions status is OK.
  Future assertRefactoringConditionsOK() async {
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatusOK(status);
    status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  /// Asserts that [refactoring] final conditions status is OK.
  Future assertRefactoringFinalConditionsOK() async {
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  /// Asserts that [status] has expected severity and message.
  void assertRefactoringStatus(
      RefactoringStatus status, RefactoringProblemSeverity expectedSeverity,
      {String expectedMessage,
      SourceRange expectedContextRange,
      String expectedContextSearch}) {
    expect(status.severity, expectedSeverity, reason: status.toString());
    if (expectedSeverity != null) {
      var problem = status.problem;
      expect(problem.severity, expectedSeverity);
      if (expectedMessage != null) {
        expect(problem.message, expectedMessage);
      }
      if (expectedContextRange != null) {
        expect(problem.location.offset, expectedContextRange.offset);
        expect(problem.location.length, expectedContextRange.length);
      }
      if (expectedContextSearch != null) {
        var expectedOffset = findOffset(expectedContextSearch);
        var expectedLength = findIdentifierLength(expectedContextSearch);
        expect(problem.location.offset, expectedOffset);
        expect(problem.location.length, expectedLength);
      }
    }
  }

  /// Asserts that [refactoring] status is OK.
  void assertRefactoringStatusOK(RefactoringStatus status) {
    assertRefactoringStatus(status, null);
  }

  /// Checks that all conditions of [refactoring] are OK and the result of
  /// applying the [Change] to [testUnit] is [expectedCode].
  Future assertSuccessfulRefactoring(String expectedCode) async {
    await assertRefactoringConditionsOK();
    var change = await refactoring.createChange();
    refactoringChange = change;
    assertTestChangeResult(expectedCode);
  }

  /// Asserts that [refactoringChange] contains a [FileEdit] for [testFile], and
  /// it results the [expectedCode].
  void assertTestChangeResult(String expectedCode) {
    if (useLineEndingsForPlatform) {
      expectedCode = normalizeNewlinesForPlatform(expectedCode);
    }
    // prepare FileEdit
    var fileEdit = refactoringChange.getFileEdit(testFile);
    expect(fileEdit, isNotNull);
    // validate resulting code
    var actualCode = SourceEdit.applySequence(testCode, fileEdit.edits);
    expect(actualCode, expectedCode);
  }

  Future<void> indexTestUnit(String code) async {
    await resolveTestCode(code);
  }

  Future<void> indexUnit(String file, String code) async {
    addSource(file, code);
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    // TODO(dantup): Get these tests passing with either line ending and change this to true.
    useLineEndingsForPlatform = false;
    searchEngine = SearchEngineImpl([
      driverFor(testPackageRootPath),
    ]);
  }
}
