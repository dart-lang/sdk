// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/agnostic/change_method_signature.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/framework/write_invocation_arguments.dart'
    show ArgumentsTrailingComma;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';

/// The refactoring that move selected formal parameters one position left
/// in the list of formal parameters.
class MoveSelectedFormalParametersLeft extends RefactoringProducer {
  static const String commandName =
      'dart.refactor.move_selected_formal_parameters_left';

  static const String constTitle = 'Move selected formal parameter(s) left';

  MoveSelectedFormalParametersLeft(super.context);

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

    var all = selection.formalParameters.toList();
    var selected = all.where((e) => e.isSelected).toList();
    var firstSelected = selected.firstOrNull;

    // This should not happen, `isAvailable()` returns `false`.
    if (firstSelected == null) {
      return ComputeStatusFailure();
    }

    var firstSelectedIndex = all.indexOf(firstSelected);

    // This should not happen, `isAvailable()` returns `false`.
    if (firstSelectedIndex < 1) {
      return ComputeStatusFailure();
    }

    var beforePrevious = all.take(firstSelectedIndex - 1);
    var afterPrevious = all.skip(firstSelectedIndex - 1);
    var reordered = [
      ...beforePrevious,
      ...selected,
      ...afterPrevious.whereNot(selected.contains),
    ];

    var formalParameterUpdates =
        reordered.map((formalParameter) {
          return FormalParameterUpdate(
            id: formalParameter.id,
            kind: formalParameter.kind,
          );
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
    return availability.hasSelectedFormalParametersToMoveLeft;
  }
}
