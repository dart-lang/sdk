// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.convert_getter_to_getter;

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
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * [ConvertMethodToGetterRefactoring] implementation.
 */
class ConvertGetterToMethodRefactoringImpl extends RefactoringImpl implements
    ConvertGetterToMethodRefactoring {
  final SearchEngine searchEngine;
  final PropertyAccessorElement element;

  SourceChange change;

  ConvertGetterToMethodRefactoringImpl(this.searchEngine, this.element);

  @override
  String get refactoringName => 'Convert Getter To Method';

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
    // function
    if (element.enclosingElement is CompilationUnitElement) {
      _updateElementDeclaration(element);
      return _updateElementReferences(element).then((_) => change);
    }
    // method
    if (element.enclosingElement is ClassElement) {
      FieldElement field = element.variable;
      return getHierarchyMembers(searchEngine, field).then((elements) {
        return Future.forEach(elements, (FieldElement field) {
          PropertyAccessorElement getter = field.getter;
          if (!getter.isSynthetic) {
            _updateElementDeclaration(getter);
            return _updateElementReferences(getter);
          }
        });
      }).then((_) => change);
    }
    // not reachable
    return null;
  }

  @override
  bool requiresPreview() => false;

  RefactoringStatus _checkInitialConditions() {
    if (!element.isGetter || element.isSynthetic) {
      return new RefactoringStatus.fatal(
          'Only explicit getters can be converted to methods.');
    }
    return new RefactoringStatus();
  }

  void _updateElementDeclaration(PropertyAccessorElement element) {
    // prepare "get" keyword
    Token getKeyword = null;
    {
      AstNode node = element.node;
      if (node is MethodDeclaration) {
        getKeyword = node.propertyKeyword;
      } else if (node is FunctionDeclaration) {
        getKeyword = node.propertyKeyword;
      }
    }
    // remove "get "
    if (getKeyword != null) {
      SourceRange getRange = rangeStartEnd(getKeyword, element.nameOffset);
      SourceEdit edit = newSourceEdit_range(getRange, '');
      doSourceChange_addElementEdit(change, element, edit);
    }
    // add parameters "()"
    {
      SourceEdit edit = new SourceEdit(rangeElementName(element).end, 0, '()');
      doSourceChange_addElementEdit(change, element, edit);
    }
  }

  Future _updateElementReferences(Element element) {
    return searchEngine.searchReferences(element).then((matches) {
      List<SourceReference> references = getSourceReferences(matches);
      for (SourceReference reference in references) {
        Element refElement = reference.element;
        SourceRange refRange = reference.range;
        // insert "()"
        var edit = new SourceEdit(refRange.end, 0, "()");
        doSourceChange_addElementEdit(change, refElement, edit);
      }
    });
  }
}
