// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analyzer/dart/element/element.dart';

/// A [Refactoring] for renaming [LibraryElement]s.
class RenameLibraryRefactoringImpl extends RenameRefactoringImpl {
  RenameLibraryRefactoringImpl(
      RefactoringWorkspace workspace, LibraryElement element)
      : super(workspace, element);

  @override
  LibraryElement get element => super.element as LibraryElement;

  @override
  String get refactoringName {
    return 'Rename Library';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    result.addStatus(validateLibraryName(newName));
    return result;
  }

  @override
  Future<void> fillChange() async {
    var processor = RenameProcessor(workspace, change, newName);
    await processor.renameElement(element);
  }
}
