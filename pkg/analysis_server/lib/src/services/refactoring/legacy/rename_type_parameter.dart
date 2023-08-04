// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analyzer/dart/element/element.dart';

class RenameTypeParameterRefactoringImpl extends RenameRefactoringImpl {
  RenameTypeParameterRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    TypeParameterElement super.element,
  );

  @override
  TypeParameterElement get element => super.element as TypeParameterElement;

  @override
  String get refactoringName {
    return 'Rename Type Parameter';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    final result = RefactoringStatus();

    final enclosing = element.enclosingElement;
    if (enclosing is TypeParameterizedElement) {
      for (final sibling in enclosing.typeParameters) {
        if (sibling.name == newName) {
          final nodeKind = sibling.kind.displayName;
          final message = "Duplicate $nodeKind '$newName'.";
          result.addError(message, newLocation_fromElement(sibling));
        }
      }
    }

    return result;
  }

  @override
  RefactoringStatus checkNewName() {
    final result = super.checkNewName();
    result.addStatus(validateTypeParameter(newName));
    return result;
  }

  @override
  Future<void> fillChange() async {
    final processor =
        RenameProcessor(workspace, sessionHelper, change, newName);
    processor.addDeclarationEdit(element);

    final references = await searchEngine.searchReferences(element);
    processor.addReferenceEdits(references);
  }
}
