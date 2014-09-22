// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_label;

import 'dart:async';

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';


/**
 * A [Refactoring] for renaming [LabelElement]s.
 */
class RenameLabelRefactoringImpl extends RenameRefactoringImpl {
  RenameLabelRefactoringImpl(SearchEngine searchEngine, LabelElement element)
      : super(searchEngine, element);

  @override
  LabelElement get element => super.element as LabelElement;

  @override
  String get refactoringName => "Rename Label";

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    result.addStatus(validateLabelName(newName));
    return result;
  }

  @override
  Future fillChange() {
    addDeclarationEdit(element);
    return searchEngine.searchReferences(element).then(addReferenceEdits);
  }
}
