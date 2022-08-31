// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
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
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/generated/source.dart';

/// A [Refactoring] for renaming [LocalElement]s.
class RenameLocalRefactoringImpl extends RenameRefactoringImpl {
  final AnalysisSessionHelper sessionHelper;

  List<LocalElement> elements = [];

  RenameLocalRefactoringImpl(
      super.workspace, AnalysisSession session, LocalElement super.element)
      : sessionHelper = AnalysisSessionHelper(session);

  @override
  LocalElement get element => super.element as LocalElement;

  @override
  String get refactoringName {
    if (element is ParameterElement) {
      return 'Rename Parameter';
    }
    if (element is FunctionElement) {
      return 'Rename Local Function';
    }
    return 'Rename Local Variable';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var result = RefactoringStatus();
    await _prepareElements();
    for (var element in elements) {
      var resolvedUnit = await sessionHelper.getResolvedUnitByElement(element);
      var unit = resolvedUnit?.unit;
      unit?.accept(
        _ConflictValidatorVisitor(
          result,
          newName,
          element,
          VisibleRangesComputer.forNode(unit),
        ),
      );
    }
    return result;
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    if (element is LocalVariableElement) {
      result.addStatus(validateVariableName(newName));
    } else if (element is ParameterElement) {
      result.addStatus(validateParameterName(newName));
    } else if (element is FunctionElement) {
      result.addStatus(validateFunctionName(newName));
    }
    return result;
  }

  @override
  Future<void> fillChange() async {
    var processor = RenameProcessor(workspace, change, newName);
    for (Element element in elements) {
      processor.addDeclarationEdit(element);
      var references = await searchEngine.searchReferences(element);

      // Remove references that don't have to have the same name.
      if (element is ParameterElement) {
        // Implicit references to optional positional parameters.
        if (element.isOptionalPositional) {
          references.removeWhere((match) => match.sourceRange.length == 0);
        }
        // References to positional parameters from super-formal.
        if (element.isPositional) {
          references.removeWhere(
            (match) => match.element is SuperFormalParameterElement,
          );
        }
      }

      processor.addReferenceEdits(references);
    }
  }

  /// Fills [elements] with [Element]s to rename.
  Future _prepareElements() async {
    final element = this.element;
    if (element is ParameterElement && element.isNamed) {
      elements = await getHierarchyNamedParameters(searchEngine, element);
    } else {
      elements = [element];
    }
  }
}

class _ConflictValidatorVisitor extends RecursiveAstVisitor<void> {
  final RefactoringStatus result;
  final String newName;
  final LocalElement target;
  final Map<Element, SourceRange> visibleRangeMap;
  final Set<Element> conflictingLocals = <Element>{};

  _ConflictValidatorVisitor(
    this.result,
    this.newName,
    this.target,
    this.visibleRangeMap,
  );

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkDeclaration(
      declaredElement: node.declaredElement2!,
      nameToken: node.name2,
    );

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var nodeElement = node.staticElement;
    if (nodeElement != null && nodeElement.name == newName) {
      if (conflictingLocals.contains(nodeElement)) {
        return;
      }
      // Shadowing by the target element.
      var targetRange = _getVisibleRange(target);
      if (targetRange != null &&
          targetRange.contains(node.offset) &&
          !node.isQualified &&
          !_isNamedExpressionName(node)) {
        nodeElement = getSyntheticAccessorVariable(nodeElement);
        var nodeKind = nodeElement.kind.displayName;
        var nodeName = getElementQualifiedName(nodeElement);
        var nameElementSourceName = nodeElement.source!.shortName;
        var refKind = target.kind.displayName;
        var message = 'Usage of $nodeKind "$nodeName" declared in '
            '"$nameElementSourceName" will be shadowed by renamed $refKind.';
        result.addError(message, newLocation_fromNode(node));
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _checkDeclaration(
      declaredElement: node.declaredElement2!,
      nameToken: node.name2,
    );

    super.visitVariableDeclaration(node);
  }

  void _checkDeclaration({
    required Element? declaredElement,
    required Token nameToken,
  }) {
    if (declaredElement != null && nameToken.lexeme == newName) {
      // Duplicate declaration.
      if (_isVisibleWithTarget(declaredElement)) {
        conflictingLocals.add(declaredElement);
        var nodeKind = declaredElement.kind.displayName;
        var message = "Duplicate $nodeKind '$newName'.";
        result.addError(message, newLocation_fromElement(declaredElement));
        return;
      }
    }
  }

  SourceRange? _getVisibleRange(LocalElement element) {
    return visibleRangeMap[element];
  }

  /// Returns whether [element] and [target] are visible together.
  bool _isVisibleWithTarget(Element element) {
    if (element is LocalElement) {
      var targetRange = _getVisibleRange(target);
      var elementRange = _getVisibleRange(element);
      return elementRange != null && elementRange.intersects(targetRange);
    }
    return false;
  }

  static bool _isNamedExpressionName(SimpleIdentifier node) {
    var parent = node.parent;
    return parent is Label && parent.parent is NamedExpression;
  }
}
