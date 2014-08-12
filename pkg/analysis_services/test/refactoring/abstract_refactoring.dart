// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename;

import 'dart:async';

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/status.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/refactoring/refactoring.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';


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

  Change refactoringChange;

  Refactoring get refactoring;

  /**
   * Asserts that [refactoring] initial/final conditions status is OK.
   */
  Future assertRefactoringConditionsOK() {
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatusOK(status);
      return refactoring.checkFinalConditions().then((status) {
        assertRefactoringStatusOK(status);
      });
    });
  }

  /**
   * Asserts that [status] has expected severity and message.
   */
  void assertRefactoringStatus(RefactoringStatus status,
      RefactoringStatusSeverity expectedSeverity, {String expectedMessage,
      SourceRange expectedContextRange, String expectedContextSearch}) {
    expect(status.severity, expectedSeverity, reason: status.message);
    if (expectedSeverity != RefactoringStatusSeverity.OK) {
      RefactoringStatusEntry entry = status.entryWithHighestSeverity;
      expect(entry.severity, expectedSeverity);
      if (expectedMessage != null) {
        expect(entry.message, expectedMessage);
      }
      if (expectedContextRange != null) {
        expect(entry.context.range, expectedContextRange);
      }
      if (expectedContextSearch != null) {
        SourceRange contextRange = entry.context.range;
        int expectedOffset = findOffset(expectedContextSearch);
        int expectedLength = findIdentifierLength(expectedContextSearch);
        expect(contextRange.offset, expectedOffset);
        expect(contextRange.length, expectedLength);
      }
    }
  }

  /**
   * Asserts that [refactoring] status is OK.
   */
  void assertRefactoringStatusOK(RefactoringStatus status) {
    assertRefactoringStatus(status, RefactoringStatusSeverity.OK);
  }

  void indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(context, testUnit);
  }

  void indexUnit(String file, String code) {
    Source source = addSource(file, code);
    CompilationUnit unit = resolveLibraryUnit(source);
    index.indexUnit(context, unit);
  }

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
  }
}
