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
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * [ConvertMethodToGetterRefactoring] implementation.
 */
class ConvertGetterToMethodRefactoringImpl extends RefactoringImpl
    implements ConvertGetterToMethodRefactoring {
  final SearchEngine searchEngine;
  final AstProvider astProvider;
  final PropertyAccessorElement element;

  SourceChange change;

  ConvertGetterToMethodRefactoringImpl(
      this.searchEngine, this.astProvider, this.element);

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
  Future<SourceChange> createChange() async {
    change = new SourceChange(refactoringName);
    // function
    if (element.enclosingElement is CompilationUnitElement) {
      await _updateElementDeclaration(element);
      await _updateElementReferences(element);
    }
    // method
    if (element.enclosingElement is ClassElement) {
      FieldElement field = element.variable;
      Set<ClassMemberElement> elements =
          await getHierarchyMembers(searchEngine, field);
      await Future.forEach(elements, (ClassMemberElement member) async {
        if (member is FieldElement) {
          PropertyAccessorElement getter = member.getter;
          if (!getter.isSynthetic) {
            await _updateElementDeclaration(getter);
            return _updateElementReferences(getter);
          }
        }
      });
    }
    // done
    return change;
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

  Future<Null> _updateElementDeclaration(
      PropertyAccessorElement element) async {
    // prepare "get" keyword
    Token getKeyword = null;
    {
      AstNode name = await astProvider.getParsedNameForElement(element);
      AstNode declaration = name?.parent;
      if (declaration is MethodDeclaration) {
        getKeyword = declaration.propertyKeyword;
      } else if (declaration is FunctionDeclaration) {
        getKeyword = declaration.propertyKeyword;
      } else {
        return;
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

  Future _updateElementReferences(Element element) async {
    List<SearchMatch> matches = await searchEngine.searchReferences(element);
    List<SourceReference> references = getSourceReferences(matches);
    for (SourceReference reference in references) {
      Element refElement = reference.element;
      SourceRange refRange = reference.range;
      // insert "()"
      var edit = new SourceEdit(refRange.end, 0, "()");
      doSourceChange_addElementEdit(change, refElement, edit);
    }
  }
}
