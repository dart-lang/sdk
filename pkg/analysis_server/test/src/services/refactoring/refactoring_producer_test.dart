// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/services/interactive_forms/interactive_forms.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ParameterizedRefactoringProducerTest);
  });
}

@reflectiveTest
class ParameterizedRefactoringProducerTest {
  /// Validation should not be triggered when resolve is called without any
  /// answers, otherwise we'll see validation errors on mandatory fields that
  /// the user hasn't had any opportunity to answer.
  Future<void> test_resolve_onlyValidatesWhenAnswered() async {
    var field = FormField(
      id: 'name',
      description: 'Name',
      required: true, // Mandatory, no default
      type: FormFieldTypeString(),
    );
    var producer = _TestProducer(fields: [field]);

    // Resolve with no answers.
    var result = (await producer.resolve(
      InteractiveExecuteCommandParams(command: 'test', arguments: []),
    )).result;

    // Expect not validation error.
    expect(result.formFields![0].error, isNull);

    // Now resolve with a null answer.
    result = (await producer.resolve(
      InteractiveExecuteCommandParams(
        command: result.command,
        arguments: result.arguments,
        formAnswers: result.formFields!
            .map((field) => FormAnswer(id: field.id))
            .toList(),
      ),
    )).result;

    // Expect a validation error.
    expect(result.formFields![0].error, 'Must be a valid string');
  }
}

class _TestProducer extends ParameterizedRefactoringProducer {
  final List<FormField> fields;

  new({required this.fields}) : super(_TestRefactoringContext());

  @override
  bool get isExperimental => false;

  @override
  List<CommandParameter> get parameters => [];

  @override
  String get title => 'Test';

  @override
  ErrorOr<InteractiveForm> buildInteractiveForm() {
    return success(
      InteractiveForm(
        supportedInteractiveFormInputTypes: {'string'},
        fields: fields,
      ),
    );
  }

  @override
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) {
    throw UnimplementedError();
  }

  @override
  bool isAvailable() => true;
}

class _TestRefactoringContext implements RefactoringContext {
  @override
  final resolvedUnitResult = _TestResolvedUnitResult();

  @override
  int get selectionLength => 0;

  @override
  int get selectionOffset => 0;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestResolvedUnitResult implements ResolvedUnitResult {
  @override
  String get path => 'test.dart';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
