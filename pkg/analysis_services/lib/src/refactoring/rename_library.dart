// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_library;

import 'dart:async';

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/status.dart';
import 'package:analysis_services/refactoring/refactoring.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/refactoring/naming_conventions.dart';
import 'package:analysis_services/src/refactoring/rename.dart';
import 'package:analyzer/src/generated/element.dart';


/**
 * A [Refactoring] for renaming [LibraryElement]s.
 */
class RenameLibraryRefactoringImpl extends RenameRefactoringImpl {
  RenameLibraryRefactoringImpl(SearchEngine searchEngine,
      LibraryElement element)
      : super(searchEngine, element);

  @override
  LibraryElement get element => super.element as LibraryElement;

  @override
  String get refactoringName {
    return "Rename Library";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    result.addStatus(validateLibraryName(newName));
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
}
