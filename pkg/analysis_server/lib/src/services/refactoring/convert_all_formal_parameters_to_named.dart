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
  Future<void> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) async {
    final availability = analyzeAvailability(
      refactoringContext: refactoringContext,
    );
    if (availability is! Available) {
      return;
    }

    final selection = await analyzeSelection(
      available: availability,
    );

    if (selection is! ValidSelectionState) {
      return;
    }

    final formalParameterUpdates = selection.formalParameters.map(
      (formalParameter) {
        return FormalParameterUpdate(
          id: formalParameter.id,
          kind: FormalParameterKind.requiredNamed,
        );
      },
    ).toList();

    final signatureUpdate = MethodSignatureUpdate(
      formalParameters: formalParameterUpdates,
      formalParametersTrailingComma: TrailingComma.ifPresent,
      argumentsTrailingComma: ArgumentsTrailingComma.ifPresent,
    );

    await computeSourceChange(
      selectionState: selection,
      signatureUpdate: signatureUpdate,
      builder: builder,
    );
  }

  @override
  bool isAvailable() {
    final availability = analyzeAvailability(
      refactoringContext: refactoringContext,
    );
    return availability is Available;
  }
}
