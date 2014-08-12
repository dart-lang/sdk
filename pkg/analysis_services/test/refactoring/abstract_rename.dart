// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.refactoring.rename;

import 'dart:async';

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/status.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/refactoring/refactoring.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:collection/collection.dart';
import 'package:unittest/unittest.dart';


/**
 * The base class for all [Refactoring] tests.
 */
abstract class RefactoringTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  Change refactoringChange;

  Refactoring get refactoring;

  /**
   * Asserts that [status] has expected severity and message.
   */
  void assertRefactoringStatus(RefactoringStatus status,
      RefactoringStatusSeverity expectedSeverity, {String expectedMessage,
      SourceRange expectedContextRange,
      String expectedContextSearch}) {
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
  Future assertRefactoringStatusOK() {
    return refactoring.checkInitialConditions().then((status) {
      assertRefactoringStatus(status, RefactoringStatusSeverity.OK);
      return refactoring.checkFinalConditions().then((status) {
        assertRefactoringStatus(status, RefactoringStatusSeverity.OK);
      });
    });
//    assertRefactoringStatus(
//        refactoring.checkInitialConditions(),
//        RefactoringStatusSeverity.OK);
//    assertRefactoringStatus(
//        refactoring.checkFinalConditions(),
//        RefactoringStatusSeverity.OK);
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


/**
 * The base class for all [RenameRefactoring] tests.
 */
class RenameRefactoringTest extends RefactoringTest {
  RenameRefactoring refactoring;

  /**
   * Asserts that [refactoringChange] contains a [FileEdit] for the file
   * with the given [path], and it results the [expectedCode].
   */
  void assertFileChangeResult(String path, String expectedCode) {
    // prepare FileEdit
    FileEdit fileEdit = refactoringChange.getFileEdit(path);
    expect(fileEdit, isNotNull);
    // validate resulting code
    File file = provider.getResource(path);
    Source source = file.createSource();
    String ini = context.getContents(source).data;
    String actualCode = _applyEdits(ini, fileEdit.edits);
    expect(actualCode, expectedCode);
  }

  /**
   * Checks that all conditions are OK and the result of applying the [Change]
   * to [testUnit] is [expectedCode].
   */
  Future assertSuccessfulRename(String expectedCode) {
    return assertRefactoringStatusOK().then((_) {
      return refactoring.createChange().then((Change refactoringChange) {
        this.refactoringChange = refactoringChange;
        assertTestChangeResult(expectedCode);
      });
    });
  }

  /**
   * Asserts that [refactoringChange] contains a [FileEdit] for [testFile], and
   * it results the [expectedCode].
   */
  void assertTestChangeResult(String expectedCode) {
    // prepare FileEdit
    FileEdit fileEdit = refactoringChange.getFileEdit(testFile);
    expect(fileEdit, isNotNull);
    // validate resulting code
    String actualCode = _applyEdits(testCode, fileEdit.edits);
    expect(actualCode, expectedCode);
  }

  /**
   * Creates a new [RenameRefactoring] in [refactoringC] for the [Element] of
   * the [SimpleIdentifier] at the given [search] pattern.
   */
  void createRenameRefactoringAtString(String search) {
    SimpleIdentifier identifier = findIdentifier(search);
    Element element = identifier.bestElement;
    // TODO(scheglov) uncomment later
//    if (element instanceof PrefixElement) {
//      element = IndexContributor.getImportElement(identifier);
//    }
    refactoring = new RenameRefactoring(searchEngine, element);
    expect(refactoring, isNotNull);
  }

//  /**
//   * Asserts result of applying [change] to [testCode].
//   */
//  void assertTestChangeResult(Change change, String expected)
//      {
//    assertChangeResult(change, testSource, expected);
//  }
//
//  /**
//   * Asserts result of applying [change] to [source].
//   */
//  void assertChangeResult(Change change, Source source, String expected)
//       {
//    SourceChange sourceChange = getSourceChange(compositeChange, source);
//    assertNotNull("No change for: " + source.toString(), sourceChange);
//    String sourceResult = getChangeResult(context, source, sourceChange);
//    assertEquals(expected, sourceResult);
////    AnalysisContext context = getAnalysisContext();
////    assertChangeResult(context, compositeChange, source, expected);
//  }

  String _applyEdits(String code, List<Edit> edits) {
    // TODO(scheglov) extract and reuse in assists and fixes tests
    mergeSort(edits, compare: (a, b) => a.offset - b.offset);
    edits.reversed.forEach((Edit edit) {
      code = code.substring(0, edit.offset) +
          edit.replacement +
          code.substring(edit.end);
    });
    return code;
  }
}

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
