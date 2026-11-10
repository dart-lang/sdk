// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/services/interactive_forms/interactive_forms.dart';
import 'package:analysis_server/src/services/refactoring/client_side_validators.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// The refactoring that extracts an expression or statements into a new method.
class ExtractMethod extends ParameterizedRefactoringProducer {
  static const String commandName = 'dart.refactor.extract_method';

  static const String constTitle = 'Extract Method';

  new(super.context);

  @override
  bool get isExperimental => false;

  @override
  CodeActionKind get kind => CodeActionKind.RefactorExtract;

  @override
  /// This refactor supports input using the new system (see
  /// [buildInteractiveForm]) but not using the old one, so there are no
  /// parameters.
  List<CommandParameter> get parameters => [];

  @override
  String get title => constTitle;

  /// Builds the [InteractiveForm] to collect input for this refactor.
  @override
  Future<ErrorOr<InteractiveForm>> buildInteractiveForm() async {
    var refactoring = _createRefactoring();
    var status = await refactoring.checkInitialConditions();
    if (status.hasFatalError) {
      return error(
        ServerErrorCodes.refactoringComputeStatusFailure,
        status.message!,
      );
    }

    var validators = ClientSideValidators(
      refactoringContext.clientCapabilities,
    );
    var nameField = ValidatableFormField(
      id: 'name',
      description: 'Method Name',
      required: true,
      defaultValue: refactoring.names.firstOrNull ?? 'newMethod',
      type: FormFieldTypeString(validators: validators.methodName),
      validate: wrapRefactorValidationFunction(validateMethodName),
    );

    return success(createForm([nameField]));
  }

  @override
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) async {
    var refactoring = _createRefactoring();
    refactoring.name = switch (commandArguments) {
      [String name] => name,
      _ => refactoring.names.firstOrNull ?? 'newMethod',
    };

    var status = await refactoring.checkAllConditions();
    if (status.hasFatalError) {
      return ComputeStatusFailure(reason: status.message);
    }
    // For non-fatal errors and warnings, we must still compute the change to
    // give the user the choice to proceed.
    await refactoring.createChange(builder: builder);
    if (status.hasError || status.hasWarning) {
      return ComputeStatusWarning(status.message);
    }
    return ComputeStatusSuccess();
  }

  @override
  bool isAvailable() {
    if (refactoringContext.server.prefersLegacyRefactors) {
      // The legacy refactor will show up in this case.
      return false;
    }
    return _createRefactoring().isAvailable();
  }

  ExtractMethodRefactoring _createRefactoring() {
    return ExtractMethodRefactoring(
        searchEngine,
        unitResult,
        selectionOffset,
        selectionLength,
      )
      // Defaults to true, but may be surprising if users didn't have an option
      // to opt in.
      ..extractAll = false;
  }
}
