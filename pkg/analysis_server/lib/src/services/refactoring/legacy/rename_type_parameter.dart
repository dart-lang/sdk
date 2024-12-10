// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analyzer/dart/element/element2.dart';

class RenameTypeParameterRefactoringImpl extends RenameRefactoringImpl {
  RenameTypeParameterRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    TypeParameterElement2 super.element2,
  ) : super.c2();

  @override
  TypeParameterElement2 get element2 => super.element2 as TypeParameterElement2;

  @override
  String get refactoringName {
    return 'Rename Type Parameter';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var result = RefactoringStatus();

    var enclosing = element2.enclosingElement2;
    if (enclosing is TypeParameterizedElement2) {
      for (var sibling in enclosing.typeParameters2) {
        if (sibling.name3 == newName) {
          var nodeKind = sibling.kind.displayName;
          var message = "Duplicate $nodeKind '$newName'.";
          result.addError(message, newLocation_fromElement2(sibling));
        }
      }
    }

    return result;
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    result.addStatus(validateTypeParameter(newName));
    return result;
  }

  @override
  Future<void> fillChange() async {
    var processor = RenameProcessor(workspace, sessionHelper, change, newName);
    processor.addDeclarationEdit2(element2);

    var references = await searchEngine.searchReferences2(element2);
    processor.addReferenceEdits(references);
  }
}
