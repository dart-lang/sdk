// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analyzer/dart/element/element.dart';

/// A [Refactoring] for renaming [LabelElement]s.
class RenameLabelRefactoringImpl extends RenameRefactoringImpl {
  RenameLabelRefactoringImpl(
      RefactoringWorkspace workspace, LabelElement element)
      : super(workspace, element);

  @override
  LabelElement get element => super.element as LabelElement;

  @override
  String get refactoringName => 'Rename Label';

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    result.addStatus(validateLabelName(newName));
    return result;
  }

  @override
  Future<void> fillChange() {
    var processor = RenameProcessor(workspace, change, newName);
    return processor.renameElement(element);
  }
}
