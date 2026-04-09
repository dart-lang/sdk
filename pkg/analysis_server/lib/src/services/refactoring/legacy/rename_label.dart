// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// A [Refactoring] for renaming [LabelElement]s.
class RenameLabelRefactoringImpl extends RenameRefactoringImpl {
  final ResolvedUnitResult resolvedUnit;

  final CorrectionUtils utils;

  RenameLabelRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    this.resolvedUnit,
    LabelElement super.element,
  ) : utils = CorrectionUtils(resolvedUnit),
      super();

  @override
  LabelElement get element => super.element as LabelElement;

  @override
  String get refactoringName => 'Rename Label';

  Future<void> buildChange({required ChangeBuilder builder}) async {
    var processor = RenameProcessor2(
      workspace,
      sessionHelper,
      builder,
      newName,
    );
    return await processor.renameElement(element);
  }

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
