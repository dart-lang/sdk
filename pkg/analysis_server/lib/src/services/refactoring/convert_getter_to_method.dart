// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// [ConvertMethodToGetterRefactoring] implementation.
class ConvertGetterToMethodRefactoringImpl extends RefactoringImpl
    implements ConvertGetterToMethodRefactoring {
  final SearchEngine searchEngine;
  final AnalysisSession session;
  final PropertyAccessorElement element;

  SourceChange change;

  ConvertGetterToMethodRefactoringImpl(
      this.searchEngine, this.session, this.element);

  @override
  String get refactoringName => 'Convert Getter To Method';

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    var result = _checkInitialConditions();
    return Future.value(result);
  }

  @override
  Future<SourceChange> createChange() async {
    change = SourceChange(refactoringName);
    // function
    if (element.enclosingElement is CompilationUnitElement) {
      await _updateElementDeclaration(element);
      await _updateElementReferences(element);
    }
    // method
    if (element.enclosingElement is ClassElement) {
      FieldElement field = element.variable;
      var elements = await getHierarchyMembers(searchEngine, field);
      await Future.forEach(elements, (ClassMemberElement member) async {
        if (member is FieldElement) {
          var getter = member.getter;
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

  RefactoringStatus _checkInitialConditions() {
    if (!element.isGetter || element.isSynthetic) {
      return RefactoringStatus.fatal(
          'Only explicit getters can be converted to methods.');
    }
    return RefactoringStatus();
  }

  Future<void> _updateElementDeclaration(
      PropertyAccessorElement element) async {
    // prepare "get" keyword
    Token getKeyword;
    {
      var sessionHelper = AnalysisSessionHelper(session);
      var result = await sessionHelper.getElementDeclaration(element);
      var declaration = result.node;
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
      var getRange =
          range.startOffsetEndOffset(getKeyword.offset, element.nameOffset);
      var edit = newSourceEdit_range(getRange, '');
      doSourceChange_addElementEdit(change, element, edit);
    }
    // add parameters "()"
    {
      var edit = SourceEdit(range.elementName(element).end, 0, '()');
      doSourceChange_addElementEdit(change, element, edit);
    }
  }

  Future _updateElementReferences(Element element) async {
    var matches = await searchEngine.searchReferences(element);
    var references = getSourceReferences(matches);
    for (var reference in references) {
      var refElement = reference.element;
      var refRange = reference.range;
      // insert "()"
      var edit = SourceEdit(refRange.end, 0, '()');
      doSourceChange_addElementEdit(change, refElement, edit);
    }
  }
}
