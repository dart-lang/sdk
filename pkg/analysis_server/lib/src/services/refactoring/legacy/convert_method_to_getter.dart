// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/util/file_paths.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// [ConvertMethodToGetterRefactoring] implementation.
class ConvertMethodToGetterRefactoringImpl extends RefactoringImpl
    implements ConvertMethodToGetterRefactoring {
  final RefactoringWorkspace workspace;
  final SearchEngine searchEngine;
  final AnalysisSessionHelper sessionHelper;
  final ExecutableElement2 element;

  late SourceChange change;

  ConvertMethodToGetterRefactoringImpl(
    this.workspace,
    AnalysisSession session,
    this.element,
  ) : sessionHelper = AnalysisSessionHelper(session),
      searchEngine = workspace.searchEngine;

  @override
  String get refactoringName => 'Convert Method To Getter';

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    return _checkElement();
  }

  @override
  Future<SourceChange> createChange() async {
    change = SourceChange(refactoringName);
    // FunctionElement
    var element = this.element;
    if (element is TopLevelFunctionElement) {
      await _updateElementDeclaration(element);
      await _updateElementReferences(element);
    }
    // MethodElement
    if (element is MethodElement2) {
      var elements = await getHierarchyMembers(searchEngine, element);
      await Future.forEach(elements, (Element2 element) async {
        await _updateElementDeclaration(element as ExecutableElement2);
        return _updateElementReferences(element);
      });
    }
    // done
    return change;
  }

  @override
  bool isAvailable() {
    return !_checkElement().hasFatalError;
  }

  /// Checks if [element] is valid to perform this refactor.
  RefactoringStatus _checkElement() {
    if (!workspace.containsElement2(element)) {
      return RefactoringStatus.fatal(
        'Only methods in your workspace can be converted.',
      );
    }

    // check Element type
    if (element is! MethodElement2 && element is! TopLevelFunctionElement) {
      return RefactoringStatus.fatal(
        'Only methods or top-level functions can be converted to getters.',
      );
    }
    // returns a value
    if (element.returnType is VoidType) {
      return RefactoringStatus.fatal(
        'Cannot convert ${element.kind.displayName} returning void.',
      );
    }
    // no parameters
    if (element.formalParameters.isNotEmpty) {
      return RefactoringStatus.fatal(
        'Only methods without parameters can be converted to getters.',
      );
    }
    // OK
    return RefactoringStatus();
  }

  Future<void> _updateElementDeclaration(ExecutableElement2 element) async {
    // prepare parameters
    FormalParameterList? parameters;
    for (
      ExecutableFragment? fragment = element.firstFragment;
      fragment != null;
      fragment = fragment.nextFragment as GetterFragment?
    ) {
      var result = await sessionHelper.getElementDeclaration2(fragment);
      var declaration = result?.node;
      if (declaration is MethodDeclaration) {
        parameters = declaration.parameters;
      } else if (declaration is FunctionDeclaration) {
        parameters = declaration.functionExpression.parameters;
      } else {
        return;
      }
      if (parameters == null) {
        return;
      }
      // insert "get "
      {
        var edit = SourceEdit(fragment.nameOffset2 ?? -1, 0, 'get ');
        doSourceChange_addFragmentEdit(change, fragment, edit);
      }
      // remove parameters
      {
        var edit = newSourceEdit_range(range.node(parameters), '');
        doSourceChange_addFragmentEdit(change, fragment, edit);
      }
    }
  }

  Future<void> _updateElementReferences(Element2 element) async {
    var matches = await searchEngine.searchReferences2(element);
    var references = getSourceReferences(matches);
    for (var reference in references) {
      // Don't update references in macro-generated files.
      if (isMacroGenerated(reference.file)) continue;

      var refElement = reference.element2;
      var refRange = reference.range;
      // prepare invocation

      var resolvedUnit = await sessionHelper.getResolvedUnitByElement2(
        refElement,
      );
      var refUnit = resolvedUnit?.unit;
      if (refUnit == null) continue;
      var refNode = NodeLocator(refRange.offset).searchWithin(refUnit);
      var invocation = refNode?.thisOrAncestorOfType<MethodInvocation>();

      // we need invocation
      if (invocation != null) {
        var edit = newSourceEdit_range(
          range.startOffsetEndOffset(refRange.end, invocation.end),
          '',
        );
        doSourceChange_addSourceEdit(change, reference.unitSource, edit);
      }
    }
  }
}
