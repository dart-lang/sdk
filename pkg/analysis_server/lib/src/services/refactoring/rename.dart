// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Helper for renaming one or more [Element]s.
class RenameProcessor {
  final RefactoringWorkspace workspace;
  final SourceChange change;
  final String newName;

  RenameProcessor(this.workspace, this.change, this.newName);

  /// Add the edit that updates the [element] declaration.
  void addDeclarationEdit(Element element) {
    if (element != null && workspace.containsElement(element)) {
      var edit = newSourceEdit_range(range.elementName(element), newName);
      doSourceChange_addElementEdit(change, element, edit);
    }
  }

  /// Add edits that update [matches].
  void addReferenceEdits(List<SearchMatch> matches) {
    var references = getSourceReferences(matches);
    for (var reference in references) {
      if (!workspace.containsElement(reference.element)) {
        continue;
      }
      reference.addEdit(change, newName);
    }
  }

  /// Update the [element] declaration and reference to it.
  Future<void> renameElement(Element element) {
    addDeclarationEdit(element);
    return workspace.searchEngine
        .searchReferences(element)
        .then(addReferenceEdits);
  }
}

/// An abstract implementation of [RenameRefactoring].
abstract class RenameRefactoringImpl extends RefactoringImpl
    implements RenameRefactoring {
  final RefactoringWorkspace workspace;
  final SearchEngine searchEngine;
  final Element _element;
  @override
  final String elementKindName;
  @override
  final String oldName;
  SourceChange change;

  String newName;

  RenameRefactoringImpl(this.workspace, Element element)
      : searchEngine = workspace.searchEngine,
        _element = element,
        elementKindName = element.kind.displayName,
        oldName = _getDisplayName(element);

  Element get element => _element;

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    var result = RefactoringStatus();
    if (element.source.isInSystemLibrary) {
      var message = format(
          "The {0} '{1}' is defined in the SDK, so cannot be renamed.",
          getElementKindName(element),
          getElementQualifiedName(element));
      result.addFatalError(message);
    }
    if (!workspace.containsElement(element)) {
      var message = format(
          "The {0} '{1}' is defined outside of the project, so cannot be renamed.",
          getElementKindName(element),
          getElementQualifiedName(element));
      result.addFatalError(message);
    }
    return Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    var result = RefactoringStatus();
    if (newName == oldName) {
      result.addFatalError(
          'The new name must be different than the current name.');
    }
    return result;
  }

  @override
  Future<SourceChange> createChange() async {
    var changeName = "$refactoringName '$oldName' to '$newName'";
    change = SourceChange(changeName);
    await fillChange();
    return change;
  }

  /// Adds individual edits to [change].
  Future<void> fillChange();

  static String _getDisplayName(Element element) {
    if (element is ImportElement) {
      var prefix = element.prefix;
      if (prefix != null) {
        return prefix.displayName;
      }
      return '';
    }
    return element.displayName;
  }
}
