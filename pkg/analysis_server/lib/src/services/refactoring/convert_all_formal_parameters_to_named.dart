// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/agnostic/change_method_signature.dart';
import 'package:analysis_server/src/services/refactoring/framework/formal_parameter.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/framework/write_invocation_arguments.dart'
    show ArgumentsTrailingComma;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';

/// The refactoring that converts all formal parameters into required named.
class ConvertAllFormalParametersToNamed extends RefactoringProducer {
  static const String commandName =
      'dart.refactor.convert_all_formal_parameters_to_named';

  static const String constTitle = 'Convert all formal parameters to named';

  ConvertAllFormalParametersToNamed(super.context);

  @override
  bool get isExperimental => true;

  @override
  List<CommandParameter> get parameters => const <CommandParameter>[];

  @override
  String get title => constTitle;

  @override
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) async {
    var availability = analyzeAvailability(
      refactoringContext: refactoringContext,
    );

    // This should not happen, `isAvailable()` returns `false`.
    if (availability is! Available) {
      return ComputeStatusFailure();
    }

    var selection = await analyzeSelection(available: availability);

    // This should not happen, `isAvailable()` returns `false`.
    if (selection is! ValidSelectionState) {
      return ComputeStatusFailure();
    }

    var formalParameterUpdates =
        selection.formalParameters.map((formalParameter) {
          var newKind = formalParameter.kind;
          if (formalParameter.kind.isPositional) {
            newKind = FormalParameterKind.requiredNamed;
          }
          return FormalParameterUpdate(id: formalParameter.id, kind: newKind);
        }).toList();

    var signatureUpdate = MethodSignatureUpdate(
      formalParameters: formalParameterUpdates,
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    var status = await computeSourceChange(
      selectionState: selection,
      signatureUpdate: signatureUpdate,
      builder: builder,
    );

    switch (status) {
      case ChangeStatusFailure():
        return ComputeStatusFailure(reason: 'Failed to compute the change.');
      case ChangeStatusSuccess():
        return ComputeStatusSuccess();
    }
  }

  @override
  bool isAvailable() {
    var availability = analyzeAvailability(
      refactoringContext: refactoringContext,
    );
    if (availability is! Available) {
      return false;
    }
    return availability.hasPositionalParameters;
  }
}
