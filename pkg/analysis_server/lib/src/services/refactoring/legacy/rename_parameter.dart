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
import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// A [Refactoring] for renaming [analyzer.FormalParameterElement]s.
class RenameParameterRefactoringImpl extends RenameRefactoringImpl {
  List<analyzer.FormalParameterElement> elements = [];
  bool _renameAllPositionalOccurrences = false;

  RenameParameterRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    analyzer.FormalParameterElement super.element,
  ) : super();

  @override
  analyzer.FormalParameterElement get element =>
      super.element as analyzer.FormalParameterElement;

  @override
  String get refactoringName {
    return 'Rename Parameter';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var result = RefactoringStatus();
    var conflictResult = RefactoringStatus();
    await _prepareElements();
    for (var element in elements) {
      if (newName.startsWith('_') && element.isNamed) {
        result.addError(
          formatList("The parameter '{0}' is named and can not be private.", [
            element.name,
          ]),
        );
        break;
      }
      var resolvedUnit = await sessionHelper.getResolvedUnitByElement(element);
      if (resolvedUnit != null) {
        // If any of the resolved units have the lint enabled, we should avoid
        // renaming method parameters separately from the other implementations.
        if (element.isPositional && !_renameAllPositionalOccurrences) {
          _renameAllPositionalOccurrences |=
              getCodeStyleOptions(
                resolvedUnit.file,
              ).avoidRenamingMethodParameters;
        }

        var unit = resolvedUnit.unit;
        unit.accept(
          ConflictValidatorVisitor(
            conflictResult,
            newName,
            element,
            VisibleRangesComputer.forNode(unit),
          ),
        );
      }
    }
    if (_renameAllPositionalOccurrences && elements.length > 1) {
      result.addStatus(
        _RefactoringStatusExt.from(
          'This will also rename all related positional parameters '
          'to the same name.',
          conflictResult,
        ),
      );
    }
    if (result.problem == null) {
      return conflictResult;
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
      if (element != this.element &&
          element.isPositional &&
          !_renameAllPositionalOccurrences) {
        continue;
      }
      var fieldRenamed = false;
      if (element is analyzer.FieldFormalParameterElement) {
        var field = element.field;
        if (field != null) {
          await processor.renameElement(field);
          fieldRenamed = true;
        }
      }

      if (!fieldRenamed) {
        processor.addDeclarationEdit(element);
      }
      var references = await searchEngine.searchReferences(element);

      // Remove references that don't have to have the same name.

      // Implicit references to optional positional parameters.
      if (element.isOptionalPositional) {
        references.removeWhere((match) => match.sourceRange.length == 0);
      }
      // References to positional parameters from super-formal.
      if (element.isPositional) {
        references.removeWhere(
          (match) => match.element is analyzer.SuperFormalParameterElement,
        );
      }

      processor.addReferenceEdits(references);
    }
  }

  /// Fills [elements] with [Element]s to rename.
  Future<void> _prepareElements() async {
    var element = this.element;
    if (element.isNamed) {
      elements = await getHierarchyNamedParameters(searchEngine, element);
    } else if (element.isPositional) {
      elements = await getHierarchyPositionalParameters(searchEngine, element);
    }
  }
}

extension _RefactoringStatusExt on RefactoringStatus {
  String get messagesAggregated {
    if (problems.isEmpty) {
      return '';
    }
    if (problems.length == 1) {
      return '\n${problems.first.message}';
    }
    return '\n${problems.first.message} And ${problems.length - 1} more '
        'error${problems.length > 1 ? 's' : ''}.';
  }

  static RefactoringStatus from(String message, RefactoringStatus result) {
    var constructor = switch (result.severity) {
      RefactoringProblemSeverity.ERROR => RefactoringStatus.error,
      RefactoringProblemSeverity.FATAL => RefactoringStatus.fatal,
      _ => RefactoringStatus.warning,
    };
    return constructor(message + result.messagesAggregated);
  }
}
