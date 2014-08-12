// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.refactoring.rename;

import 'dart:async';

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/refactoring/refactoring.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:collection/collection.dart';
import 'package:unittest/unittest.dart';

import 'abstract_refactoring.dart';


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
    return assertRefactoringConditionsOK().then((_) {
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
   * Creates a new [RenameRefactoring] in [refactoring] for the [Element] of
   * the [SimpleIdentifier] at the given [search] pattern.
   */
  void createRenameRefactoringAtString(String search) {
    SimpleIdentifier identifier = findIdentifier(search);
    Element element = identifier.bestElement;
    // TODO(scheglov) uncomment later
//    if (element instanceof PrefixElement) {
//      element = IndexContributor.getImportElement(identifier);
//    }
    createRenameRefactoringForElement(element);
  }

  /**
   * Creates a new [RenameRefactoring] in [refactoring] for [element].
   * Fails if no [RenameRefactoring] can be created.
   */
  void createRenameRefactoringForElement(Element element) {
    refactoring = new RenameRefactoring(searchEngine, element);
    expect(refactoring, isNotNull, reason: "No refactoring for '$element'.");
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
