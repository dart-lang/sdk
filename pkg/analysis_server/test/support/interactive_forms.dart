// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:matcher/expect.dart';

import '../lsp/request_helpers_mixin.dart';

mixin InteractiveFormsTestMixin on LspRequestHelpersMixin {
  /// A helper to complete an interactive form, taking the place of a user and
  /// the client-side code.
  ///
  /// [command] is the original command that will be resolved.
  ///
  /// [answers] is a map of Field ID -> answer values that should be provided.
  ///
  /// Returns an updated command after fields have been answered that can be
  /// executed.
  Future<Command> completeInteractiveForm(
    Command command,
    Map<String, Object?> answers,
  ) async {
    var interactiveCommand = InteractiveExecuteCommandParams(
      command: command.command,
      arguments: command.arguments,
    );

    // Perform an initial resolve to get the form.
    interactiveCommand = await resolveCommand(interactiveCommand);

    // Expect at least some fields (we wouldn't have been called if none were
    // expected).
    expect(interactiveCommand.formFields, allOf(isNotNull, isNotEmpty));

    // Ensure all answers we have are in the form.
    expect(
      interactiveCommand.formFields!.map((field) => field.id),
      containsAll(answers.keys),
    );

    // Resolve again, using the answers we were given.
    interactiveCommand = InteractiveExecuteCommandParams(
      command: interactiveCommand.command,
      arguments: interactiveCommand.arguments,
      formFields: interactiveCommand.formFields,
      formAnswers: answers.keys
          .map((id) => FormAnswer(id: id, value: answers[id]))
          .toList(),
    );
    interactiveCommand = await resolveCommand(interactiveCommand);

    // Ensure the form is considered complete.
    expect(interactiveCommand.formFields, isNull);

    // Return the updated command.
    return Command(
      title: command.title,
      command: interactiveCommand.command,
      arguments: interactiveCommand.arguments,
    );
  }
}

extension FormFieldExtension on FormField {
  /// Returns a [FormAnswer] for this field with the answer [value].
  FormAnswer answer(Object? value) {
    return FormAnswer(id: id, value: value);
  }
}
