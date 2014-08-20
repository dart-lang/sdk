// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_constructor;

import 'dart:async';

import 'package:analysis_server/src/protocol2.dart' show SourceEdit;
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';


/**
 * A [Refactoring] for renaming [ConstructorElement]s.
 */
class RenameConstructorRefactoringImpl extends RenameRefactoringImpl {
  RenameConstructorRefactoringImpl(SearchEngine searchEngine,
      ConstructorElement element)
      : super(searchEngine, element);

  @override
  ConstructorElement get element => super.element as ConstructorElement;

  @override
  String get refactoringName {
    return "Rename Constructor";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    _analyzePossibleConflicts(result);
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    result.addStatus(validateConstructorName(newName));
    return result;
  }

  @override
  Future<Change> createChange() {
    Change change = new Change(refactoringName);
    String replacement = newName.isEmpty ? '' : '.${newName}';
    // update references
    return searchEngine.searchReferences(element).then((refMatches) {
      List<SourceReference> references = getSourceReferences(refMatches);
      if (!element.isSynthetic) {
        for (SourceReference reference in references) {
          SourceEdit edit = createReferenceEdit(reference, replacement);
          change.addEdit(reference.file, edit);
        }
      }
      return change;
    });
  }

  void _analyzePossibleConflicts(RefactoringStatus result) {
    // check if there are members with "newName" in the same ClassElement
    ClassElement parentClass = element.enclosingElement;
    for (Element newNameMember in getChildren(parentClass, newName)) {
      String message =
          format(
              "Class '{0}' already declares {1} with name '{2}'.",
              parentClass.displayName,
              getElementKindName(newNameMember),
              newName);
      result.addError(
          message,
          new RefactoringStatusContext.forElement(newNameMember));
    }
  }
}
