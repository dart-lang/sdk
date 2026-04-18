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
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class ConflictValidatorVisitor extends RecursiveAstVisitor<void> {
  final RefactoringStatus result;
  final String newName;
  final LocalElement target;
  final Map<Element, SourceRange> visibleRangeMap;
  final Set<Element> conflictingLocals = <Element>{};

  ConflictValidatorVisitor(
    this.result,
    this.newName,
    this.target,
    this.visibleRangeMap,
  );

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkDeclaration(
      declaredElement: node.declaredFragment!.element,
      nameToken: node.name,
    );

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var nodeElement = node.element;
    if (nodeElement != null && nodeElement.name == newName) {
      if (conflictingLocals.contains(nodeElement)) {
        return;
      }
      // Shadowing by the target element.
      var targetRange = _getVisibleRange(target);
      if (targetRange != null &&
          targetRange.contains(node.offset) &&
          !node.isQualified) {
        nodeElement = getSyntheticAccessorVariable(nodeElement);
        var nodeKind = nodeElement.kind.displayName;
        var nodeName = getElementQualifiedName(nodeElement);
        var nameElementSourceName =
            nodeElement.firstFragment.libraryFragment!.source.shortName;
        var refKind = target.kind.displayName;
        var message =
            'Usage of $nodeKind "$nodeName" declared in '
            '"$nameElementSourceName" will be shadowed by renamed $refKind.';
        result.addError(message, newLocation_fromNode(node));
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _checkDeclaration(
      declaredElement: node.declaredFragment!.element,
      nameToken: node.name,
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
        var message = formatList("Duplicate {0} of name '{1}'{2}.", [
          nodeKind,
          newName,
          declaredElement.declarationLocation,
        ]);
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
}

/// A [Refactoring] for renaming [LocalElement]s (excluding
/// [FormalParameterElement]s).
class RenameLocalRefactoringImpl extends RenameRefactoringImpl {
  final ResolvedUnitResult resolvedUnit;

  final CorrectionUtils utils;

  RenameLocalRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    this.resolvedUnit,
    LocalElement super.element,
  ) : utils = CorrectionUtils(resolvedUnit),
      super();

  @override
  LocalElement get element => super.element as LocalElement;

  @override
  String get refactoringName {
    if (element is LocalFunctionElement) {
      return 'Rename Local Function';
    }
    return 'Rename Local Variable';
  }

  Future<void> buildChange({required ChangeBuilder builder}) async {
    var processor = RenameProcessor2(
      workspace,
      sessionHelper,
      builder,
      newName,
    );

    var element = this.element;
    if (element is PatternVariableElement) {
      var rootVariable =
          (element.firstFragment as PatternVariableFragmentImpl).rootVariable;
      var declaredFragments = rootVariable is JoinPatternVariableFragmentImpl
          ? rootVariable.transitiveVariables
                .whereType<BindPatternVariableFragmentImpl>()
                .toList()
          : [element.firstFragment];
      for (var declaredFragment in declaredFragments) {
        await processor.addDeclarationEdit(declaredFragment.element);
        if (declaredFragment is BindPatternVariableFragmentImpl) {
          // If a variable is used to resolve a named field with an implicit
          // name, we need to make the field name explicit.
          var fieldName = declaredFragment.node.fieldNameWithImplicitName;
          if (fieldName != null) {
            await processor.replace(
              referenceElement: element,
              offset: fieldName.colon.offset,
              length: 0,
              code: element.name!,
            );
          }
        }
      }
    } else {
      await processor.addDeclarationEdit(element);
    }

    var references = await searchEngine.searchReferences(element);
    await processor.addReferenceEdits(references);
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var result = RefactoringStatus();
    var resolvedUnit = await sessionHelper.getResolvedUnitByElement(element);
    var unit = resolvedUnit?.unit;
    unit?.accept(
      ConflictValidatorVisitor(
        result,
        newName,
        element,
        VisibleRangesComputer.forNode(unit),
      ),
    );
    return result;
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    if (element is LocalVariableElement) {
      result.addStatus(validateVariableName(newName));
    } else if (element is LocalFunctionElement) {
      result.addStatus(validateFunctionName(newName));
    }
    return result;
  }

  @override
  Future<SourceChange> createChange({ChangeBuilder? builder}) async {
    builder ??= ChangeBuilder(
      session: resolvedUnit.session,
      defaultEol: utils.endOfLine,
    );
    await buildChange(builder: builder);
    var sourceChange = builder.sourceChange;
    sourceChange.message = "$refactoringName '$oldName' to '$newName'";
    return sourceChange;
  }

  @override
  Future<void> fillChange() {
    throw UnsupportedError('This method should never be called.');
  }
}

extension on Element {
  String get declarationLocation {
    var sourceName = firstFragment.libraryFragment!.source.shortName;
    var executable = enclosingElement;
    String className = '';
    String executableName = '';
    if (executable is MethodElement) {
      var namescope = executable.enclosingElement as ClassElement?;
      className = namescope?.displayName ?? '';
      if (className.isNotEmpty && executable.displayName.isNotEmpty) {
        className += '.';
      }
      executableName = executable.displayName;
    } else if (executable is TopLevelFunctionElement) {
      executableName = executable.displayName;
    }
    if (executableName.isEmpty) {
      return " in '$sourceName'";
    }
    return " at $className$executableName in '$sourceName'";
  }
}
