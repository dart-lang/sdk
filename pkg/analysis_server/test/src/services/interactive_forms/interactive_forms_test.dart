// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/interactive_forms/interactive_forms.dart';
import 'package:matcher/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../support/interactive_forms.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InteractiveFormsTest);
  });
}

@reflectiveTest
class InteractiveFormsTest {
  /// Default values are not treated the same as user answers. A form will not
  /// be considered complete even if unanswered fields have defaults (as long
  /// as they are supported).
  test_defaults_doNotCompleteForm_answered() {
    var fieldA = _stringField('a', defaultValue: 'aDefault');
    var fieldB = _stringField('b', defaultValue: 'bDefault');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      fields: fields,
    );

    // Process empty answers. This makes no difference to the unanswered case
    // above.
    form.processResponse([]);

    // Because we never provided answers, we still have fields to complete.
    expect(form.clientFields, [fieldA, fieldB]);
    expect(form.clientAnswers, isEmpty);
    expect(form.answers, ['aDefault', 'bDefault']);
  }

  /// Default values are not treated the same as user answers. A form will not
  /// be considered complete even if unanswered fields have defaults (as long
  /// as they are supported).
  test_defaults_doNotCompleteForm_unanswered() {
    var fieldA = _stringField('a', defaultValue: 'aDefault');
    var fieldB = _stringField('b', defaultValue: 'bDefault');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      fields: fields,
    );

    // Because we have never responded to the form, we still have fields to
    // complete.
    expect(form.clientFields, [fieldA, fieldB]);
    expect(form.clientAnswers, isEmpty);
    expect(form.answers, ['aDefault', 'bDefault']);
  }

  test_initialState() {
    var fieldA = _stringField('a', defaultValue: 'aDefault');
    var fieldB = _stringField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      fields: fields,
    );

    expect(form.clientFields, [fieldA, fieldB]);
    expect(form.clientAnswers, isEmpty); // No client answers
    expect(form.answers, ['aDefault', null]); // But defaults here
  }

  test_initialState_defaultsForUnsupportedFields() {
    var fieldA = _stringField('a', defaultValue: 'aDefault');
    var fieldB = _stringField('b', defaultValue: 'bDefault');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'int'}, // We don't support strings!
      fields: fields,
    );

    // No outstanding fields, because we don't support strings and used the
    // defaults instead.
    expect(form.clientFields, isEmpty);
    expect(form.clientAnswers, isEmpty);
    expect(form.answers, ['aDefault', 'bDefault']);
  }

  test_processResponse_invalidAnswers() {
    var fieldA = _stringField('a', defaultValue: 'aDefault');
    var fieldB = _stringField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      fields: fields,
    );

    // Process a response with invalid answers.
    var clientAnswers = [fieldA.answer(1), fieldB.answer(2)];
    form.processResponse(clientAnswers);

    // Expect error messages on the fields.
    expect(form.clientFields, [
      fieldA.withError('Must be a valid string'),
      fieldB.withError('Must be a valid string'),
    ]);
    expect(form.clientAnswers, clientAnswers); // Previous user input
    expect(form.answers, ['aDefault', null]); // Still defaults here
  }

  test_processResponse_mixedValidInvalidAnswers() {
    var fieldA = _stringField('a', defaultValue: 'aDefault');
    var fieldB = _stringField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      fields: fields,
    );

    // Process a response with some valid and some invalid answers.
    var clientAnswers = [fieldA.answer('valid'), fieldB.answer(2)];
    form.processResponse(clientAnswers);

    // Expect only the invalid field to have a validation error.
    expect(form.clientFields, [
      fieldA,
      fieldB.withError('Must be a valid string'),
    ]);
    expect(form.clientAnswers, clientAnswers); // Previous user input
    expect(form.answers, ['valid', null]); // Updated with valid answer
  }

  test_processResponse_multipleRounds() {
    var fieldA = _stringField('a', defaultValue: 'aDefault');
    var fieldB = _stringField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      fields: fields,
    );

    // Process response with one valid answer.
    form.processResponse([fieldA.answer('valid'), fieldB.answer(2)]);

    // Expect the invalid field to have a validation error.
    expect(form.clientFields, [
      fieldA,
      fieldB.withError('Must be a valid string'),
    ]);

    // Process with both valid answers.
    form.processResponse([fieldA.answer('valid'), fieldB.answer('alsoValid')]);

    // Now we have no outstanding fields, but both answers populated.
    expect(form.clientFields, isEmpty);
    expect(form.clientAnswers, hasLength(2));
    expect(form.answers, ['valid', 'alsoValid']);
  }

  test_processResponse_noAnswers() {
    var fieldA = _stringField('a', defaultValue: 'aDefault');
    var fieldB = _stringField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      fields: fields,
    );

    // Provide no answers.
    form.processResponse([]);

    // Fields now show validation messages.
    expect(form.clientFields, [
      fieldA,
      fieldB.withError('Must be a valid string'),
    ]);
    expect(form.clientAnswers, isEmpty); // No client answers
    expect(form.answers, ['aDefault', null]); // But defaults here
  }

  test_throws_duplicateAnswerIDs() {
    var fieldA = _fileField('a');

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'file'},
      fields: [fieldA],
    );

    expect(
      () => form.processResponse([fieldA.answer(1), fieldA.answer(2)]),
      throwsArgumentError,
    );
  }

  test_throws_duplicateFieldIDs() {
    var fieldA = _fileField('a');

    expect(
      () => InteractiveForm(
        supportedInteractiveFormInputTypes: {'file'},
        fields: [fieldA, fieldA],
      ),
      throwsArgumentError,
    );
  }

  test_throws_invalidAnswerId() {
    var fieldA = _fileField('a');

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'file'},
      fields: [fieldA],
    );

    expect(
      () => form.processResponse([FormAnswer(id: 'fake')]),
      throwsArgumentError,
    );
  }

  test_throws_unsupportedWithNoDefault() {
    var fieldA = _fileField('a');

    expect(
      () => InteractiveForm(
        supportedInteractiveFormInputTypes: {'string'}, // no 'file'
        fields: [fieldA],
      ),
      throwsArgumentError,
    );
  }

  test_validation_bool() {
    var fieldA = _boolField('a');
    var fieldB = _boolField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'bool'},
      fields: fields,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse([fieldA.answer(true), fieldB.answer('invalid')]);

    // Expect all fields, with a validation message on the invalid one.
    expect(form.clientFields, [
      fieldA,
      fieldB.withError('Must be a valid boolean'),
    ]);
  }

  test_validation_file() {
    var fieldA = _fileField('a');
    var fieldB = _fileField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'file'},
      fields: fields,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse([
      fieldA.answer('file:///a/b'),
      fieldB.answer('invalid'),
    ]);

    // Expect all fields, with a validation message on the invalid one.
    expect(form.clientFields, [
      fieldA,
      fieldB.withError('Must be a valid file:// URI'),
    ]);
  }

  test_validation_number() {
    var fieldA = _numberField('a');
    var fieldB = _numberField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'number'},
      fields: fields,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse([fieldA.answer(1), fieldB.answer('invalid')]);

    // Expect all fields, with a validation message on the invalid one.
    expect(form.clientFields, [
      fieldA,
      fieldB.withError('Must be a valid number'),
    ]);
  }

  test_validation_optional() {
    var fieldA = _boolField('a', required: false);
    var fieldB = _boolField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'bool'},
      fields: fields,
    );

    // No answers.
    form.processResponse([]);

    expect(form.clientFields, [
      fieldA, // Valid because optional.
      fieldB.withError('Must be a valid boolean'),
    ]);
  }

  test_validation_optionalButWrongType() {
    var fieldA = _boolField('a', required: false);
    var fieldB = _boolField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'bool'},
      fields: fields,
    );

    // No answers.
    form.processResponse([fieldA.answer('invalid')]);

    expect(form.clientFields, [
      fieldA.withError('Must be a valid boolean'), // Invalid type
      fieldB.withError('Must be a valid boolean'), // Not answered
    ]);
  }

  test_validation_string() {
    var fieldA = _stringField('a');
    var fieldB = _stringField('b');
    var fields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      fields: fields,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse([fieldA.answer('valid'), fieldB.answer(2)]);

    // Expect all fields, with a validation message on the invalid one.
    expect(form.clientFields, [
      fieldA,
      fieldB.withError('Must be a valid string'),
    ]);
  }

  FormField _boolField(
    String id, {
    bool? required,
    String? description,
    String? defaultValue,
  }) {
    return _field(
      FormFieldTypeBool(),
      id,
      description: description,
      required: required,
      defaultValue: defaultValue,
    );
  }

  FormField _field(
    FormFieldType type,
    String id, {
    String? description,
    bool? required,
    String? defaultValue,
  }) {
    return FormField(
      id: id,
      description: description ?? 'Field for $id',
      type: type,
      required: required ?? true,
      defaultValue: defaultValue,
    );
  }

  FormField _fileField(
    String id, {
    bool? required,
    String? description,
    String? defaultValue,
  }) {
    return _field(
      FormFieldTypeFile(existence: .New, type: .Regular),
      id,
      description: description,
      required: required,
      defaultValue: defaultValue,
    );
  }

  FormField _numberField(
    String id, {
    bool? required,
    String? description,
    String? defaultValue,
  }) {
    return _field(
      FormFieldTypeNumber(),
      id,
      description: description,
      required: required,
      defaultValue: defaultValue,
    );
  }

  FormField _stringField(
    String id, {
    bool? required,
    String? description,
    String? defaultValue,
  }) {
    return _field(
      FormFieldTypeString(),
      id,
      description: description,
      required: required,
      defaultValue: defaultValue,
    );
  }
}
