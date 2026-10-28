// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// The refactoring that extracts an expression into a local variable.
class ExtractLocalVariable extends RefactoringProducer {
  static const String commandName = 'dart.refactor.extract_local_variable';

  static const String constTitle = 'Extract Local Variable';

  new(super.context);

  @override
  bool get isExperimental => false;

  @override
  CodeActionKind get kind => CodeActionKind.RefactorExtract;

  @override
  String get title => constTitle;

  @override
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) async {
    var refactoring = _createRefactoring();

    // checkInitialConditions will populate names with suggestions.
    var status = await refactoring.checkInitialConditions();
    if (status.hasFatalError) {
      return ComputeStatusFailure(reason: status.message);
    }
    refactoring.name = refactoring.names.firstOrNull ?? 'newVariable';

    status.addStatus(await refactoring.checkFinalConditions());
    if (status.hasFatalError) {
      return ComputeStatusFailure(reason: status.message);
    }
    // For non-fatal errors and warnings, we must still compute the change to
    // give the user the choice to proceed.
    await refactoring.createChange(builder: builder);
    if (status.hasError || status.hasWarning) {
      return ComputeStatusWarning(status.summarizedMessage);
    }
    return ComputeStatusSuccess();
  }

  @override
  bool isAvailable() {
    return _createRefactoring().isAvailable();
  }

  ExtractLocalRefactoring _createRefactoring() {
    return ExtractLocalRefactoring(unitResult, selectionOffset, selectionLength)
      // Defaults to true, but may be surprising if users didn't have an option
      // to opt in.
      ..extractAll = false;
  }
}
