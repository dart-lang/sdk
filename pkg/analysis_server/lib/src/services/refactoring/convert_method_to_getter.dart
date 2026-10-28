// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// The refactoring that converts a method into a getter.
class ConvertMethodToGetter extends RefactoringProducer {
  static const String commandName = 'dart.refactor.convert_method_to_getter';

  static const String constTitle = 'Convert Method to Getter';

  new(super.context);

  @override
  bool get isExperimental => false;

  @override
  CodeActionKind get kind => CodeActionKind.RefactorRewrite;

  @override
  String get title => constTitle;

  @override
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) async {
    var refactoring = _createRefactoring();
    if (refactoring == null) {
      return ComputeStatusFailure();
    }

    var status = await refactoring.checkAllConditions();
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
    return _createRefactoring()?.isAvailable() ?? false;
  }

  ConvertMethodToGetterRefactoring? _createRefactoring() {
    var node = unitResult.unit.nodeCovering(offset: selectionOffset);
    var element = node?.getElement();
    if (element is ExecutableElement) {
      return ConvertMethodToGetterRefactoring(
        refactoringContext.server.refactoringWorkspace,
        unitResult,
        element,
      );
    }
    return null;
  }
}
