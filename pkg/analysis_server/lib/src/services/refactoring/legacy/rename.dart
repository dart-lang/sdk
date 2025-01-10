// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Helper for renaming one or more [Element]s.
class RenameProcessor {
  final RefactoringWorkspace workspace;
  final AnalysisSessionHelper sessionHelper;
  final SourceChange change;
  final String newName;

  RenameProcessor(
    this.workspace,
    this.sessionHelper,
    this.change,
    this.newName,
  );

  /// Add the edit that updates the [element] declaration.
  void addDeclarationEdit2(Element2? element) {
    if (element == null) {
      return;
    } else if (element is LibraryElementImpl) {
      // TODO(brianwilkerson): Consider adding public API to get the offset and
      //  length of the library's name.
      var nameRange = range.startOffsetLength(
        element.nameOffset,
        element.nameLength,
      );
      var edit = newSourceEdit_range(nameRange, newName);
      doSourceChange_addFragmentEdit(change, element.firstFragment, edit);
    } else if (workspace.containsElement2(element)) {
      Fragment? fragment = element.firstFragment;
      while (fragment != null) {
        var edit = newSourceEdit_range(range.fragmentName(fragment)!, newName);
        doSourceChange_addFragmentEdit(change, fragment, edit);
        fragment = fragment.nextFragment;
      }
    }
  }

  /// Add edits that update [matches].
  void addReferenceEdits(List<SearchMatch> matches) {
    var references = getSourceReferences(matches);
    for (var reference in references) {
      if (!workspace.containsElement2(reference.element2)) {
        continue;
      }
      reference.addEdit(change, newName);
    }
  }

  /// Update the [element] declaration and references to it.
  Future<void> renameElement2(Element2 element) async {
    addDeclarationEdit2(element);
    var matches = await workspace.searchEngine.searchReferences(element);
    addReferenceEdits(matches);
  }

  /// Add an edit that replaces the specified region with [code].
  /// Uses [referenceElement] to identify the file to update.
  void replace({
    required Element referenceElement,
    required int offset,
    required int length,
    required String code,
  }) {
    var edit = SourceEdit(offset, length, code);
    doSourceChange_addElementEdit(change, referenceElement, edit);
  }

  /// Add an edit that replaces the specified region with [code].
  /// Uses [referenceElement] to identify the file to update.
  void replace2({
    required Element2 referenceElement,
    required int offset,
    required int length,
    required String code,
  }) {
    var edit = SourceEdit(offset, length, code);
    doSourceChange_addFragmentEdit(
      change,
      referenceElement.firstFragment,
      edit,
    );
  }
}

/// An abstract implementation of [RenameRefactoring].
abstract class RenameRefactoringImpl extends RefactoringImpl
    implements RenameRefactoring {
  final RefactoringWorkspace workspace;
  final AnalysisSessionHelper sessionHelper;
  final SearchEngine searchEngine;
  final Element _element;
  @override
  final String elementKindName;
  @override
  final String oldName;
  late SourceChange change;

  late String newName;

  RenameRefactoringImpl(this.workspace, this.sessionHelper, Element element)
    : searchEngine = workspace.searchEngine,
      _element = element,
      elementKindName = element.kind.displayName,
      oldName = _getOldName(element);

  RenameRefactoringImpl.c2(this.workspace, this.sessionHelper, Element2 element)
    : searchEngine = workspace.searchEngine,
      _element = element.asElement!,
      elementKindName = element.kind.displayName,
      oldName = _getOldName(element.asElement!);

  Element get element => _element;

  Element2 get element2 => _element.asElement2!;

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    var result = RefactoringStatus();
    if (element.library?.isInSdk == true) {
      var message = format(
        "The {0} '{1}' is defined in the SDK, so cannot be renamed.",
        getElementKindName(element2),
        getElementQualifiedName(element2),
      );
      result.addFatalError(message);
    }
    if (!workspace.containsElement(element)) {
      var message = format(
        "The {0} '{1}' is defined outside of the project, so cannot be renamed.",
        getElementKindName(element2),
        getElementQualifiedName(element2),
      );
      result.addFatalError(message);
    }
    return Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    var result = RefactoringStatus();
    if (newName == oldName) {
      result.addFatalError(
        'The new name must be different than the current name.',
      );
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

  static String _getOldName(Element element) {
    if (element is ConstructorElement) {
      return element.name;
    } else if (element is LibraryImportElement) {
      var prefix = element.prefix?.element;
      if (prefix != null) {
        return prefix.displayName;
      }
      return '';
    }
    return element.displayName;
  }
}
