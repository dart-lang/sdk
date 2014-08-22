// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_local;

import 'dart:async';

import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A [Refactoring] for renaming [LocalElement]s.
 */
class RenameLocalRefactoringImpl extends RenameRefactoringImpl {
  RenameLocalRefactoringImpl(SearchEngine searchEngine, LocalElement element)
      : super(searchEngine, element);

  @override
  LocalElement get element => super.element as LocalElement;

  @override
  String get refactoringName {
    if (element is ParameterElement) {
      return "Rename Parameter";
    }
    if (element is FunctionElement) {
      return "Rename Local Function";
    }
    return "Rename Local Variable";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    // checks the resolved CompilationUnit(s)
    Source unitSource = element.source;
    List<Source> librarySources = context.getLibrariesContaining(unitSource);
    for (Source librarySource in librarySources) {
      _analyzePossibleConflicts_inLibrary(result, unitSource, librarySource);
    }
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    if (element is LocalVariableElement) {
      LocalVariableElement variableElement = element;
      if (variableElement.isConst) {
        result.addStatus(validateConstantName(newName));
      } else {
        result.addStatus(validateVariableName(newName));
      }
    } else if (element is ParameterElement) {
      result.addStatus(validateParameterName(newName));
    } else if (element is FunctionElement) {
      result.addStatus(validateFunctionName(newName));
    }
    return result;
  }

  @override
  Future<Change> createChange() {
    Change change = new Change(refactoringName);
    // update declaration
    addDeclarationEdit(change, element);
    // update references
    return searchEngine.searchReferences(element).then((refMatches) {
      List<SourceReference> references = getSourceReferences(refMatches);
      for (SourceReference reference in references) {
        addReferenceEdit(change, reference);
      }
      return change;
    });
  }

  void _analyzePossibleConflicts_inLibrary(RefactoringStatus result,
      Source unitSource, Source librarySource) {
    // prepare resolved unit
    CompilationUnit unit = null;
    try {
      unit = context.resolveCompilationUnit2(unitSource, librarySource);
    } catch (e) {
    }
    if (unit == null) {
      return;
    }
    // check for conflicts in the unit
    SourceRange elementRange = element.visibleRange;
    unit.accept(new _ConflictValidatorVisitor(this, result, elementRange));
  }
}


class _ConflictValidatorVisitor extends RecursiveAstVisitor<Object> {
  final RenameLocalRefactoringImpl refactoring;
  final RefactoringStatus result;
  final SourceRange elementRange;

  _ConflictValidatorVisitor(this.refactoring, this.result, this.elementRange);

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element nodeElement = node.bestElement;
    String newName = refactoring.newName;
    if (nodeElement != null && nodeElement.name == newName) {
      // duplicate declaration
      if (haveIntersectingRanges(refactoring.element, nodeElement)) {
        String nodeKind = nodeElement.kind.displayName;
        String message = "Duplicate ${nodeKind} '$newName'.";
        result.addError(
            message,
            createLocation_forElement(nodeElement));
        return null;
      }
      // shadowing referenced element
      if (elementRange.contains(node.offset) && !node.isQualified) {
        nodeElement = getSyntheticAccessorVariable(nodeElement);
        String nodeKind = nodeElement.kind.displayName;
        String nodeName = getElementQualifiedName(nodeElement);
        String nameElementSourceName = nodeElement.source.shortName;
        String refKind = refactoring.element.kind.displayName;
        String message =
            'Usage of $nodeKind "$nodeName" declared in '
                '"$nameElementSourceName" will be shadowed by renamed $refKind.';
        result.addError(message, createLocation_forNode(node));
      }
    }
    return null;
  }
}
