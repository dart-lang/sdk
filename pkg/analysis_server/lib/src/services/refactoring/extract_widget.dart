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

/// The refactoring that extracts a widget creation expression or a method
/// returning a widget, into a new stateless or stateful widget.
class ExtractWidget extends ParameterizedRefactoringProducer {
  static const String commandName = 'dart.refactor.extract_widget';

  static const String constTitle = 'Extract Widget';

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
      description: 'Widget Name',
      required: true,
      defaultValue: 'NewWidget',
      type: FormFieldTypeString(validators: validators.className),
      validate: wrapRefactorValidationFunction(validateClassName),
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
      _ => 'NewWidget',
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

  ExtractWidgetRefactoring _createRefactoring() {
    return ExtractWidgetRefactoring(
      searchEngine,
      unitResult,
      selectionOffset,
      selectionLength,
    );
  }
}
