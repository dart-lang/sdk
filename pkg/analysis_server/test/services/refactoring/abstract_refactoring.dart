// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_single_unit.dart';

int findIdentifierLength(String search) {
  int length = 0;
  while (length < search.length) {
    int c = search.codeUnitAt(length);
    if (!(c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0) ||
        c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0) ||
        c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0))) {
      break;
    }
    length++;
  }
  return length;
}

/**
 * The base class for all [Refactoring] tests.
 */
abstract class RefactoringTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  SourceChange refactoringChange;

  Refactoring get refactoring;

  /**
   * Asserts that [refactoringChange] contains a [FileEdit] for the file
   * with the given [path], and it results the [expectedCode].
   */
  void assertFileChangeResult(String path, String expectedCode) {
    // prepare FileEdit
    SourceFileEdit fileEdit = refactoringChange.getFileEdit(path);
    expect(fileEdit, isNotNull, reason: 'No file edit for $path');
    // validate resulting code
    File file = provider.getResource(path);
    Source source = file.createSource();
    String ini = context.getContents(source).data;
    String actualCode = SourceEdit.applySequence(ini, fileEdit.edits);
    expect(actualCode, expectedCode);
  }

  /**
   * Asserts that [refactoringChange] does not contain a [FileEdit] for the file
   * with the given [path].
   */
  void assertNoFileChange(String path) {
    SourceFileEdit fileEdit = refactoringChange.getFileEdit(path);
    expect(fileEdit, isNull);
  }

  /**
   * Asserts that [refactoring] initial/final conditions status is OK.
   */
  Future assertRefactoringConditionsOK() async {
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatusOK(status);
    status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  /**
   * Asserts that [refactoring] final conditions status is OK.
   */
  Future assertRefactoringFinalConditionsOK() async {
    RefactoringStatus status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
  }

  /**
   * Asserts that [status] has expected severity and message.
   */
  void assertRefactoringStatus(
      RefactoringStatus status, RefactoringProblemSeverity expectedSeverity,
      {String expectedMessage,
      SourceRange expectedContextRange,
      String expectedContextSearch}) {
    expect(status.severity, expectedSeverity, reason: status.toString());
    if (expectedSeverity != null) {
      RefactoringProblem problem = status.problem;
      expect(problem.severity, expectedSeverity);
      if (expectedMessage != null) {
        expect(problem.message, expectedMessage);
      }
      if (expectedContextRange != null) {
        expect(problem.location.offset, expectedContextRange.offset);
        expect(problem.location.length, expectedContextRange.length);
      }
      if (expectedContextSearch != null) {
        int expectedOffset = findOffset(expectedContextSearch);
        int expectedLength = findIdentifierLength(expectedContextSearch);
        expect(problem.location.offset, expectedOffset);
        expect(problem.location.length, expectedLength);
      }
    }
  }

  /**
   * Asserts that [refactoring] status is OK.
   */
  void assertRefactoringStatusOK(RefactoringStatus status) {
    assertRefactoringStatus(status, null);
  }

  /**
   * Checks that all conditions of [refactoring] are OK and the result of
   * applying the [Change] to [testUnit] is [expectedCode].
   */
  Future assertSuccessfulRefactoring(String expectedCode) async {
    await assertRefactoringConditionsOK();
    SourceChange change = await refactoring.createChange();
    this.refactoringChange = change;
    assertTestChangeResult(expectedCode);
  }

  /**
   * Asserts that [refactoringChange] contains a [FileEdit] for [testFile], and
   * it results the [expectedCode].
   */
  void assertTestChangeResult(String expectedCode) {
    // prepare FileEdit
    SourceFileEdit fileEdit = refactoringChange.getFileEdit(testFile);
    expect(fileEdit, isNotNull);
    // validate resulting code
    String actualCode = SourceEdit.applySequence(testCode, fileEdit.edits);
    expect(actualCode, expectedCode);
  }

  void indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(testUnit);
  }

  void indexUnit(String file, String code) {
    Source source = addSource(file, code);
    CompilationUnit unit = resolveLibraryUnit(source);
    index.indexUnit(unit);
  }

  void setUp() {
    super.setUp();
    index = createMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
  }
}
