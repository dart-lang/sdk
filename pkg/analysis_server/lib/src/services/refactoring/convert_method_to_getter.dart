// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.convert_method_to_getter;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * [ConvertMethodToGetterRefactoring] implementation.
 */
class ConvertMethodToGetterRefactoringImpl extends RefactoringImpl implements
    ConvertMethodToGetterRefactoring {
  final SearchEngine searchEngine;
  final ExecutableElement element;

  SourceChange change;

  ConvertMethodToGetterRefactoringImpl(this.searchEngine, this.element);

  @override
  String get refactoringName => 'Convert Method To Getter';

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    RefactoringStatus result = _checkInitialConditions();
    return new Future.value(result);
  }

  @override
  Future<SourceChange> createChange() {
    change = new SourceChange(refactoringName);
    // FunctionElement
    if (element is FunctionElement) {
      _updateElementDeclaration(element);
      return _updateElementReferences(element).then((_) => change);
    }
    // MethodElement
    if (element is MethodElement) {
      MethodElement method = element;
      return getHierarchyMembers(searchEngine, method).then((elements) {
        return Future.forEach(elements, (Element element) {
          _updateElementDeclaration(element);
          return _updateElementReferences(element);
        });
      }).then((_) => change);
    }
    // not reachable
    return null;
  }

  @override
  bool requiresPreview() => false;

  RefactoringStatus _checkInitialConditions() {
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
    // no parameters
    if (element.parameters.isNotEmpty) {
      return new RefactoringStatus.fatal(
          'Only methods without parameters can be converted to getters.');
    }
    // OK
    return new RefactoringStatus();
  }

  void _updateElementDeclaration(Element element) {
    // prepare parameters
    FormalParameterList parameters;
    {
      AstNode node = element.node;
      if (node is MethodDeclaration) {
        parameters = node.parameters;
      }
      if (node is FunctionDeclaration) {
        parameters = node.functionExpression.parameters;
      }
    }
    // insert "get "
    {
      SourceEdit edit = new SourceEdit(element.nameOffset, 0, 'get ');
      doSourceChange_addElementEdit(change, element, edit);
    }
    // remove parameters
    {
      SourceEdit edit = newSourceEdit_range(rangeNode(parameters), '');
      doSourceChange_addElementEdit(change, element, edit);
    }
  }

  Future _updateElementReferences(Element element) {
    return searchEngine.searchReferences(element).then((matches) {
      List<SourceReference> references = getSourceReferences(matches);
      for (SourceReference reference in references) {
        Element refElement = reference.element;
        SourceRange refRange = reference.range;
        // prepare invocation
        MethodInvocation invocation;
        {
          CompilationUnit refUnit = refElement.unit;
          AstNode refNode =
              new NodeLocator.con1(refRange.offset).searchWithin(refUnit);
          invocation = refNode.getAncestor((node) => node is MethodInvocation);
        }
        // we need invocation
        if (invocation != null) {
          SourceRange range = rangeEndEnd(refRange, invocation);
          SourceEdit edit = newSourceEdit_range(range, '');
          doSourceChange_addElementEdit(change, element, edit);
        }
      }
    });
  }
}
