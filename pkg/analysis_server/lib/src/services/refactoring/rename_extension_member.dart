// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analysis_server/src/services/refactoring/visible_ranges_computer.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';

/// A [Refactoring] for renaming extension member [Element]s.
class RenameExtensionMemberRefactoringImpl extends RenameRefactoringImpl {
  final AnalysisSessionHelper sessionHelper;

  _ExtensionMemberValidator _validator;

  RenameExtensionMemberRefactoringImpl(
      RefactoringWorkspace workspace, AnalysisSession session, Element element)
      : sessionHelper = AnalysisSessionHelper(session),
        super(workspace, element);

  @override
  String get refactoringName {
    if (element is TypeParameterElement) {
      return 'Rename Type Parameter';
    }
    if (element is FieldElement) {
      return 'Rename Field';
    }
    return 'Rename Method';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    _validator = _ExtensionMemberValidator.forRename(
        searchEngine, sessionHelper, element, newName);
    return _validator.validate();
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    var result = await super.checkInitialConditions();
    if (element is MethodElement && (element as MethodElement).isOperator) {
      result.addFatalError('Cannot rename operator.');
    }
    return Future<RefactoringStatus>.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    if (element is FieldElement) {
      result.addStatus(validateFieldName(newName));
    }
    if (element is MethodElement) {
      result.addStatus(validateMethodName(newName));
    }
    return result;
  }

  @override
  Future<void> fillChange() async {
    var processor = RenameProcessor(workspace, change, newName);

    // Update the declaration.
    var renameElement = element;
    if (renameElement.isSynthetic && renameElement is FieldElement) {
      processor.addDeclarationEdit(renameElement.getter);
      processor.addDeclarationEdit(renameElement.setter);
    } else {
      processor.addDeclarationEdit(renameElement);
    }

    // Update references.
    processor.addReferenceEdits(_validator.references);
  }
}

/// Helper to check if the created or renamed [Element] will cause any
/// conflicts.
class _ExtensionMemberValidator {
  final SearchEngine searchEngine;
  final AnalysisSessionHelper sessionHelper;
  final LibraryElement library;
  final Element element;
  final ExtensionElement elementExtension;
  final ElementKind elementKind;
  final String name;
  final bool isRename;

  final RefactoringStatus result = RefactoringStatus();
  final List<SearchMatch> references = <SearchMatch>[];

  _ExtensionMemberValidator.forRename(
      this.searchEngine, this.sessionHelper, this.element, this.name)
      : isRename = true,
        library = element.library,
        elementExtension = element.enclosingElement,
        elementKind = element.kind;

  Future<RefactoringStatus> validate() async {
    // Check if there is a member with "newName" in the extension.
    for (var newNameMember in getChildren(elementExtension, name)) {
      result.addError(
        format(
          "Extension '{0}' already declares {1} with name '{2}'.",
          elementExtension.displayName,
          getElementKindName(newNameMember),
          name,
        ),
        newLocation_fromElement(newNameMember),
      );
    }

    await _prepareReferences();

    // usage of the renamed Element is shadowed by a local element
    {
      var conflict = await _getShadowingLocalElement();
      if (conflict != null) {
        var localElement = conflict.localElement;
        result.addError(
          format(
            "Usage of renamed {0} will be shadowed by {1} '{2}'.",
            elementKind.displayName,
            getElementKindName(localElement),
            localElement.displayName,
          ),
          newLocation_fromMatch(conflict.match),
        );
      }
    }

    return result;
  }

  Future<_MatchShadowedByLocal> _getShadowingLocalElement() async {
    var localElementMap = <CompilationUnitElement, List<LocalElement>>{};
    var visibleRangeMap = <LocalElement, SourceRange>{};

    Future<List<LocalElement>> getLocalElements(Element element) async {
      var unitElement = element.thisOrAncestorOfType<CompilationUnitElement>();
      var localElements = localElementMap[unitElement];

      if (localElements == null) {
        var result = await sessionHelper.getResolvedUnitByElement(element);
        var unit = result.unit;

        var collector = _LocalElementsCollector(name);
        unit.accept(collector);
        localElements = collector.elements;
        localElementMap[unitElement] = localElements;

        visibleRangeMap.addAll(VisibleRangesComputer.forNode(unit));
      }

      return localElements;
    }

    for (var match in references) {
      // Qualified reference cannot be shadowed by local elements.
      if (match.isQualified) {
        continue;
      }
      // Check local elements that might shadow the reference.
      var localElements = await getLocalElements(match.element);
      for (var localElement in localElements) {
        var elementRange = visibleRangeMap[localElement];
        if (elementRange != null &&
            elementRange.intersects(match.sourceRange)) {
          return _MatchShadowedByLocal(match, localElement);
        }
      }
    }
    return null;
  }

  /// Fills [references] with references to the [element].
  Future<void> _prepareReferences() async {
    if (!isRename) return;

    references.addAll(
      await searchEngine.searchReferences(element),
    );
  }
}

class _LocalElementsCollector extends GeneralizingAstVisitor<void> {
  final String name;
  final List<LocalElement> elements = [];

  _LocalElementsCollector(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is LocalElement && element.name == name) {
      elements.add(element);
    }
  }
}

class _MatchShadowedByLocal {
  final SearchMatch match;
  final LocalElement localElement;

  _MatchShadowedByLocal(this.match, this.localElement);
}
