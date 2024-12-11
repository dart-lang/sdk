// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename_local.dart';
import 'package:analysis_server/src/services/refactoring/legacy/visible_ranges_computer.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/generated/java_core.dart';

/// A [Refactoring] for renaming [ParameterElement]s.
class RenameParameterRefactoringImpl extends RenameRefactoringImpl {
  List<FormalParameterElement> elements = [];

  RenameParameterRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    FormalParameterElement super.element,
  ) : super.c2();

  @override
  FormalParameterElement get element2 =>
      super.element2 as FormalParameterElement;

  @override
  String get refactoringName {
    return 'Rename Parameter';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var result = RefactoringStatus();
    await _prepareElements();
    for (var element in elements) {
      if (newName.startsWith('_') && element.isNamed) {
        result.addError(
          format(
            "The parameter '{0}' is named and can not be private.",
            element.name3,
          ),
        );
        break;
      }
      var resolvedUnit = await sessionHelper.getResolvedUnitByElement2(element);
      var unit = resolvedUnit?.unit;
      unit?.accept(
        ConflictValidatorVisitor(
          result,
          newName,
          element,
          VisibleRangesComputer.forNode(unit),
        ),
      );
    }
    return result;
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    result.addStatus(validateParameterName(newName));
    return result;
  }

  @override
  Future<void> fillChange() async {
    var processor = RenameProcessor(workspace, sessionHelper, change, newName);
    for (var element in elements) {
      var fieldRenamed = false;
      if (element is FieldFormalParameterElement2) {
        var field = element.field2;
        if (field != null) {
          await processor.renameElement2(field);
          fieldRenamed = true;
        }
      }

      if (!fieldRenamed) {
        processor.addDeclarationEdit2(element);
      }
      var references = await searchEngine.searchReferences2(element);

      // Remove references that don't have to have the same name.

      // Implicit references to optional positional parameters.
      if (element.isOptionalPositional) {
        references.removeWhere((match) => match.sourceRange.length == 0);
      }
      // References to positional parameters from super-formal.
      if (element.isPositional) {
        references.removeWhere(
          (match) => match.element2 is SuperFormalParameterElement2,
        );
      }

      processor.addReferenceEdits(references);
    }
  }

  /// Fills [elements] with [Element]s to rename.
  Future<void> _prepareElements() async {
    var element = element2;
    if (element.isNamed) {
      elements =
          (await getHierarchyNamedParameters(searchEngine, element)).toList();
    } else {
      elements = [element];
    }
  }
}
