// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'abstract_refactoring.dart';

/// The base class for all [RenameRefactoring] tests.
class RenameRefactoringTest extends RefactoringTest {
  @override
  late RenameRefactoring refactoring;

  /// Asserts that [refactoring] has potential edits in [testFile] at offset
  /// of the given [searches].
  ///
  /// If [searches] is `null`, it will use the positions/ranges marked in
  /// [parsedTestCode] to determine the offsets.
  void assertPotentialEdits({List<String>? searches, List<int>? indexes}) {
    var expectedOffsets = <int>{};
    if (searches != null) {
      for (var search in searches) {
        var offset = findOffset(search);
        expectedOffsets.add(offset);
      }
    } else if (parsedTestCode.positions.isNotEmpty) {
      for (var position in parsedTestCode.positions.whereIndexed(
        (index, _) => indexes?.contains(index) ?? true,
      )) {
        expectedOffsets.add(position.offset);
      }
    } else if (parsedTestCode.ranges.isNotEmpty) {
      for (var range in parsedTestCode.ranges.whereIndexed(
        (index, _) => indexes?.contains(index) ?? true,
      )) {
        expectedOffsets.add(range.sourceRange.offset);
      }
    } else {
      fail('No searches or positions provided for potential edits.');
    }
    // remove offset marked as potential
    for (var potentialId in refactoring.potentialEditIds) {
      var edit = findEditById(potentialId);
      expect(edit, isNotNull);
      expectedOffsets.remove(edit.offset);
    }
    // all potential offsets are marked as such
    expect(expectedOffsets, isEmpty);
  }

  /// Creates a refactoring and sets the offset and length from the
  /// [parsedTestCode] position/range at the given [index].
  void createRenameRefactoring([int index = 0]) {
    setPositionOrRange(index);
    var unit = testAnalysisResult.unit;
    var node = unit.select(length: length, offset: offset)?.coveringNode;
    if (node == null) {
      fail('No node found at offset $offset with length $length.');
    }
    createRenameRefactoringForNode(node);
  }

  /// Creates a new [RenameRefactoring] in [refactoring] for the element of
  /// the [SimpleIdentifier] at the given [search] pattern.
  void createRenameRefactoringAtString(String search) {
    var node = findNode.any(search);

    if (node is ImportDirective) {
      return createRenameRefactoringForElement2(
        MockLibraryImportElement(node.libraryImport!),
      );
    }
    var element = ElementLocator.locate(node);
    if (node is! SimpleIdentifier || element is! PrefixElement) {
      return createRenameRefactoringForElement2(element);
    }
    createRenameRefactoringForElement2(
      MockLibraryImportElement(getImportElement(node)!),
    );
  }

  /// Creates a new [RenameRefactoring] in [refactoring] for [element].
  /// Fails if no [RenameRefactoring] can be created.
  void createRenameRefactoringForElement2(Element? element) {
    var workspace = RefactoringWorkspace([driverFor(testFile)], searchEngine);
    var refactoring = RenameRefactoring.create(
      workspace,
      testAnalysisResult,
      element,
    );
    if (refactoring == null) {
      fail("No refactoring for '$element'.");
    }
    this.refactoring = refactoring;
  }

  void createRenameRefactoringForNode(AstNode node) {
    Element? element;
    switch (node) {
      case ImportDirective():
        element = MockLibraryImportElement(node.libraryImport!);
      default:
        element = ElementLocator.locate(node);
    }

    if (node is SimpleIdentifier && element is PrefixElement) {
      element = MockLibraryImportElement(getImportElement(node)!);
    }

    createRenameRefactoringForElement2(element);
  }

  /// Returns the [SourceEdit] with the given [id], maybe `null`.
  SourceEdit findEditById(String id) {
    for (var fileEdit in refactoringChange.edits) {
      for (var edit in fileEdit.edits) {
        if (edit.id == id) {
          return edit;
        }
      }
    }
    fail('No edit with id: $id');
  }
}
