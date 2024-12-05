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
    var result = RefactoringStatus();

    var enclosing = element.enclosingElement3;
    if (enclosing is TypeParameterizedElement) {
      for (var sibling in enclosing.typeParameters) {
        if (sibling.name == newName) {
          var nodeKind = sibling.kind.displayName;
          var message = "Duplicate $nodeKind '$newName'.";
          result.addError(message, newLocation_fromElement(sibling));
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
    processor.addDeclarationEdit(element);

    var references = await searchEngine.searchReferences(element);
    processor.addReferenceEdits(references);
  }
}
