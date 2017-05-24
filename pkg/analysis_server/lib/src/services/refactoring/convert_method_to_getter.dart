// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/**
 * [ConvertMethodToGetterRefactoring] implementation.
 */
class ConvertMethodToGetterRefactoringImpl extends RefactoringImpl
    implements ConvertMethodToGetterRefactoring {
  final SearchEngine searchEngine;
  final AstProvider astProvider;
  final ExecutableElement element;

  SourceChange change;

  ConvertMethodToGetterRefactoringImpl(
      this.searchEngine, this.astProvider, this.element);

  @override
  String get refactoringName => 'Convert Method To Getter';

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    // check Element type
    if (element is FunctionElement) {
      if (element.enclosingElement is! CompilationUnitElement) {
        return new RefactoringStatus.fatal(
            'Only top-level functions can be converted to getters.');
      }
    } else if (element is! MethodElement) {
      return new RefactoringStatus.fatal(
          'Only class methods or top-level functions can be converted to getters.');
    }
    // returns a value
    if (element.returnType != null && element.returnType.isVoid) {
      return new RefactoringStatus.fatal(
          'Cannot convert ${element.kind.displayName} returning void.');
    }
    // no parameters
    if (element.parameters.isNotEmpty) {
      return new RefactoringStatus.fatal(
          'Only methods without parameters can be converted to getters.');
    }
    // OK
    return new RefactoringStatus();
  }

  @override
  Future<SourceChange> createChange() async {
    change = new SourceChange(refactoringName);
    // FunctionElement
    if (element is FunctionElement) {
      await _updateElementDeclaration(element);
      await _updateElementReferences(element);
    }
    // MethodElement
    if (element is MethodElement) {
      MethodElement method = element;
      Set<ClassMemberElement> elements =
          await getHierarchyMembers(searchEngine, method);
      await Future.forEach(elements, (Element element) async {
        await _updateElementDeclaration(element);
        return _updateElementReferences(element);
      });
    }
    // done
    return change;
  }

  @override
  bool requiresPreview() => false;

  Future<Null> _updateElementDeclaration(Element element) async {
    // prepare parameters
    FormalParameterList parameters;
    {
      AstNode name = await astProvider.getParsedNameForElement(element);
      AstNode declaration = name?.parent;
      if (declaration is MethodDeclaration) {
        parameters = declaration.parameters;
      } else if (declaration is FunctionDeclaration) {
        parameters = declaration.functionExpression.parameters;
      } else {
        return;
      }
    }
    // insert "get "
    {
      SourceEdit edit = new SourceEdit(element.nameOffset, 0, 'get ');
      doSourceChange_addElementEdit(change, element, edit);
    }
    // remove parameters
    {
      SourceEdit edit = newSourceEdit_range(range.node(parameters), '');
      doSourceChange_addElementEdit(change, element, edit);
    }
  }

  Future<Null> _updateElementReferences(Element element) async {
    List<SearchMatch> matches = await searchEngine.searchReferences(element);
    List<SourceReference> references = getSourceReferences(matches);
    for (SourceReference reference in references) {
      Element refElement = reference.element;
      SourceRange refRange = reference.range;
      // prepare invocation
      MethodInvocation invocation;
      {
        CompilationUnit refUnit =
            await astProvider.getParsedUnitForElement(refElement);
        AstNode refNode =
            new NodeLocator(refRange.offset).searchWithin(refUnit);
        invocation = refNode.getAncestor((node) => node is MethodInvocation);
      }
      // we need invocation
      if (invocation != null) {
        SourceEdit edit = newSourceEdit_range(
            range.startOffsetEndOffset(refRange.end, invocation.end), '');
        doSourceChange_addElementEdit(change, refElement, edit);
      }
    }
  }
}
