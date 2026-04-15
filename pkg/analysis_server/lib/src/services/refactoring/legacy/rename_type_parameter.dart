// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class RenameTypeParameterRefactoringImpl extends RenameRefactoringImpl {
  final ResolvedUnitResult resolvedUnit;

  final CorrectionUtils utils;

  RenameTypeParameterRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    this.resolvedUnit,
    TypeParameterElement super.element2,
  ) : utils = CorrectionUtils(resolvedUnit),
      super();

  @override
  TypeParameterElement get element => super.element as TypeParameterElement;

  @override
  String get refactoringName {
    return 'Rename Type Parameter';
  }

  Future<void> buildChange({required ChangeBuilder builder}) async {
    var processor = RenameProcessor2(
      workspace,
      sessionHelper,
      builder,
      newName,
    );
    await processor.addDeclarationEdit(element);

    var references = await searchEngine.searchReferences(element);
    await processor.addReferenceEdits(references);
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var result = RefactoringStatus();

    var enclosing = element.enclosingElement;
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
  Future<SourceChange> createChange({ChangeBuilder? builder}) async {
    builder ??= ChangeBuilder(
      session: resolvedUnit.session,
      defaultEol: utils.endOfLine,
    );
    await buildChange(builder: builder);
    var sourceChange = builder.sourceChange;
    sourceChange.message = "$refactoringName '$oldName' to '$newName'";
    return sourceChange;
  }

  @override
  Future<void> fillChange() {
    throw UnsupportedError('This method should never be called.');
  }
}
