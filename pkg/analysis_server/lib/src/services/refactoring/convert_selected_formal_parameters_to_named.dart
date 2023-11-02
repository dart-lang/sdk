// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/agnostic/change_method_signature.dart';
import 'package:analysis_server/src/services/refactoring/framework/formal_parameter.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/framework/write_invocation_arguments.dart'
    show ArgumentsTrailingComma;
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';

/// The refactoring that converts selected formal parameters into required
/// named.
class ConvertSelectedFormalParametersToNamed extends RefactoringProducer {
  static const String commandName =
      'dart.refactor.convert_selected_formal_parameters_to_named';

  static const String constTitle =
      'Convert selected formal parameter(s) to named';

  ConvertSelectedFormalParametersToNamed(super.context);

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

    final List<FormalParameterState> reordered;
    final formalParameters = selection.formalParameters;
    final allSelectedNamed = formalParameters
        .where((e) => e.isSelected)
        .every((e) => e.kind.isNamed);
    if (allSelectedNamed) {
      reordered = formalParameters;
    } else {
      reordered = formalParameters.stablePartition((e) => !e.isSelected);
    }

    final formalParameterUpdates = reordered.map(
      (formalParameter) {
        if (formalParameter.isSelected) {
          return FormalParameterUpdate(
            id: formalParameter.id,
            kind: FormalParameterKind.requiredNamed,
          );
        } else {
          return FormalParameterUpdate(
            id: formalParameter.id,
            kind: formalParameter.kind,
          );
        }
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
    if (availability is! Available) {
      return false;
    }
    return availability.hasSelectedFormalParametersToConvertToNamed;
  }
}
