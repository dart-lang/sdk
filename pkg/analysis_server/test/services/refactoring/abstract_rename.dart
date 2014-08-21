// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename;

import 'dart:async';

import 'package:analysis_server/src/protocol2.dart' show SourceEdit;
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
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
    String actualCode = SourceEdit.applySequence(ini, fileEdit.edits);
    expect(actualCode, expectedCode);
  }

  /**
   * Asserts that [refactoringChange] does not contain a [FileEdit] for the file
   * with the given [path].
   */
  void assertNoFileChange(String path) {
    FileEdit fileEdit = refactoringChange.getFileEdit(path);
    expect(fileEdit, isNull);
  }

  /**
   * Asserts that [refactoring] has potential edits in [testFile] at offset
   * of the given [searches].
   */
  void assertPotentialEdits(List<String> searches) {
    Set<int> expectedOffsets = new Set<int>();
    for (String search in searches) {
      int offset = findOffset(search);
      expectedOffsets.add(offset);
    }
    // remove offset marked as potential
    for (String potentialId in refactoring.potentialEditIds) {
      SourceEdit edit = findEditById(potentialId);
      expect(edit, isNotNull);
      expectedOffsets.remove(edit.offset);
    }
    // all potential offsets are marked as such
    expect(expectedOffsets, isEmpty);
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
   * Creates a new [RenameRefactoring] in [refactoring] for the [Element] of
   * the [SimpleIdentifier] at the given [search] pattern.
   */
  void createRenameRefactoringAtString(String search) {
    SimpleIdentifier identifier = findIdentifier(search);
    Element element = identifier.bestElement;
    if (element is PrefixElement) {
      element = getImportElement(identifier);
    }
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

  /**
   * Returns the [Edit] with the given [id], maybe `null`.
   */
  SourceEdit findEditById(String id) {
    for (FileEdit fileEdit in refactoringChange.fileEdits) {
      for (SourceEdit edit in fileEdit.edits) {
        if (edit.id == id) {
          return edit;
        }
      }
    }
    return null;
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
}
