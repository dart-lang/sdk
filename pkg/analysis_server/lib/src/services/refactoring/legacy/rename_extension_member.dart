// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analysis_server/src/services/refactoring/legacy/visible_ranges_computer.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/generated/java_core.dart';

/// A [Refactoring] for renaming extension member [Element]s.
class RenameExtensionMemberRefactoringImpl extends RenameRefactoringImpl {
  final ExtensionElement2 extensionElement;

  late _ExtensionMemberValidator _validator;

  RenameExtensionMemberRefactoringImpl(
    RefactoringWorkspace workspace,
    AnalysisSessionHelper sessionHelper,
    this.extensionElement,
    Element2 element,
  ) : super.c2(workspace, sessionHelper, element);

  @override
  String get refactoringName {
    if (element2 is TypeParameterElement2) {
      return 'Rename Type Parameter';
    } else if (element2 is FieldElement2) {
      return 'Rename Field';
    }
    return 'Rename Method';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    _validator = _ExtensionMemberValidator.forRename(
      searchEngine,
      sessionHelper,
      extensionElement,
      element2,
      newName,
    );
    return _validator.validate();
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    var result = await super.checkInitialConditions();
    if (element2 is MethodElement2 && (element2 as MethodElement2).isOperator) {
      result.addFatalError('Cannot rename operator.');
    }
    return result;
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    if (element2 is FieldElement2) {
      result.addStatus(validateFieldName(newName));
    } else if (element2 is MethodElement2) {
      result.addStatus(validateMethodName(newName));
    }
    return result;
  }

  @override
  Future<void> fillChange() async {
    var processor = RenameProcessor(workspace, sessionHelper, change, newName);

    // Update the declaration.
    var renameElement = element2;
    if (renameElement.isSynthetic && renameElement is FieldElement2) {
      processor.addDeclarationEdit2(renameElement.getter2);
      processor.addDeclarationEdit2(renameElement.setter2);
    } else {
      processor.addDeclarationEdit2(renameElement);
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
  final LibraryElement2 library;
  final Element2 element;
  final ExtensionElement2 elementExtension;
  final ElementKind elementKind;
  final String name;
  final bool isRename;

  final RefactoringStatus result = RefactoringStatus();
  final List<SearchMatch> references = <SearchMatch>[];

  _ExtensionMemberValidator.forRename(
    this.searchEngine,
    this.sessionHelper,
    this.elementExtension,
    this.element,
    this.name,
  ) : isRename = true,
      library = elementExtension.library2,
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
        newLocation_fromElement2(newNameMember),
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

  Future<_MatchShadowedByLocal?> _getShadowingLocalElement() async {
    var localElementMap = <LibraryFragment, List<LocalElement2>>{};
    var visibleRangeMap = <LocalElement2, SourceRange>{};

    Future<List<LocalElement2>> getLocalElements(Element2 element) async {
      var unitFragment = element.firstFragment.libraryFragment;
      if (unitFragment == null) {
        return const [];
      }

      var localElements = localElementMap[unitFragment];

      if (localElements == null) {
        var result = await sessionHelper.getResolvedUnitByElement2(element);
        if (result == null) {
          return const [];
        }

        var unit = result.unit;

        var collector = _LocalElementsCollector(name);
        unit.accept(collector);
        localElements = collector.elements;
        localElementMap[unitFragment] = localElements;

        visibleRangeMap.addAll(VisibleRangesComputer.forNode2(unit));
      }

      return localElements;
    }

    for (var match in references) {
      // Qualified reference cannot be shadowed by local elements.
      if (match.isQualified) {
        continue;
      }
      // Check local elements that might shadow the reference.
      var localElements = await getLocalElements(match.element2);
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

    references.addAll(await searchEngine.searchReferences2(element));
  }
}

class _LocalElementsCollector extends GeneralizingAstVisitor<void> {
  final String name;
  final List<LocalElement2> elements = [];

  _LocalElementsCollector(this.name);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme == name) {
      var element = node.declaredFragment?.element;
      if (element is LocalFunctionElement) {
        elements.add(element);
      }
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.name?.lexeme == name) {
      var element = node.declaredFragment?.element;
      if (element != null) {
        elements.add(element);
      }
    }

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == name) {
      var element = node.declaredFragment?.element;
      if (element is LocalVariableElement2) {
        elements.add(element);
      }
    }

    super.visitVariableDeclaration(node);
  }
}

class _MatchShadowedByLocal {
  final SearchMatch match;
  final LocalElement2 localElement;

  _MatchShadowedByLocal(this.match, this.localElement);
}
