// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analyzer/dart/element/element2.dart';

/// A [Refactoring] for renaming [LibraryElement2]s.
class RenameLibraryRefactoringImpl extends RenameRefactoringImpl {
  RenameLibraryRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    LibraryElement2 super.element2,
  ) : super.c2();

  @override
  LibraryElement2 get element2 => super.element2 as LibraryElement2;

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
    var processor = RenameProcessor(workspace, sessionHelper, change, newName);
    await processor.renameElement2(element2);
  }
}
