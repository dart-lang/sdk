// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:test/test.dart';

import 'abstract_refactoring.dart';

/**
 * The base class for all [RenameRefactoring] tests.
 */
class RenameRefactoringTest extends RefactoringTest {
  RenameRefactoring refactoring;

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
    refactoring = new RenameRefactoring(searchEngine, astProvider, element);
    expect(refactoring, isNotNull, reason: "No refactoring for '$element'.");
  }

  /**
   * Returns the [Edit] with the given [id], maybe `null`.
   */
  SourceEdit findEditById(String id) {
    for (SourceFileEdit fileEdit in refactoringChange.edits) {
      for (SourceEdit edit in fileEdit.edits) {
        if (edit.id == id) {
          return edit;
        }
      }
    }
    return null;
  }
}
