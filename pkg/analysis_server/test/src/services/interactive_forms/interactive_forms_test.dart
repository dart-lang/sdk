// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/interactive_forms/interactive_forms.dart';
import 'package:matcher/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InteractiveFormsTest);
  });
}

@reflectiveTest
class InteractiveFormsTest {
  test_initialState() {
    var fieldA = _stringField('a', 'aDefault');
    var fieldB = _stringField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    expect(form.outstandingFields, [fieldA, fieldB]);
    expect(form.outstandingFieldAnswers, [null, null]); // No client answers
    expect(form.existingAnswers, ['aDefault', null]); // But defaults here
  }

  test_initialState_defaultsForUnsupportedFields() {
    var fieldA = _stringField('a', 'aDefault');
    var fieldB = _stringField('b', 'bDefault');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'int'}, // We don't support strings!
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // No outstanding fields, because we don't support strings and used the
    // defaults instead.
    expect(form.outstandingFields, isEmpty);
    expect(form.outstandingFieldAnswers, isEmpty);
    expect(form.existingAnswers, ['aDefault', 'bDefault']);
  }

  test_processResponse_invalidAnswers() {
    var fieldA = _stringField('a', 'aDefault');
    var fieldB = _stringField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // Process a response with invalid answers.
    form.processResponse(masterFields, [1, 2]);

    // Expect error messages on the fields.
    expect(form.outstandingFields, [
      fieldA.withError('Must be a valid string'),
      fieldB.withError('Must be a valid string'),
    ]);
    expect(form.outstandingFieldAnswers, [1, 2]); // Previous user input
    expect(form.existingAnswers, ['aDefault', null]); // Still defaults here
  }

  test_processResponse_mixedValidInvalidAnswers() {
    var fieldA = _stringField('a', 'aDefault');
    var fieldB = _stringField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse(masterFields, ['valid', 2]);

    // Expect only the invalid field as outstanding.
    expect(form.outstandingFields, [
      fieldB.withError('Must be a valid string'),
    ]);
    expect(form.outstandingFieldAnswers, [2]); // Previous user input
    expect(form.existingAnswers, ['valid', null]); // Updated with valid answer
  }

  test_processResponse_multipleRounds() {
    var fieldA = _stringField('a', 'aDefault');
    var fieldB = _stringField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // Process response with one valid answer.
    form.processResponse(masterFields, ['valid', 2]);

    // One remaining oustanding field.
    expect(form.outstandingFields, [
      fieldB.withError('Must be a valid string'),
    ]);

    // Process that one field.
    form.processResponse([fieldB], ['alsoValid']);

    // Now we have no outstanding fields, but both answers populated.
    expect(form.outstandingFields, isEmpty);
    expect(form.existingAnswers, ['valid', 'alsoValid']);
  }

  test_processResponse_noAnswers() {
    var fieldA = _stringField('a', 'aDefault');
    var fieldB = _stringField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // This should not change anything, because the client didn't provide any
    // answers.
    form.processResponse(masterFields, List.filled(masterFields.length, null));

    expect(form.outstandingFields, [fieldA, fieldB]);
    expect(form.outstandingFieldAnswers, [null, null]); // No client answers
    expect(form.existingAnswers, ['aDefault', null]); // But defaults here
  }

  test_validation_bool() {
    var fieldA = _boolField('a');
    var fieldB = _boolField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'bool'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse(masterFields, [true, 'invalid']);

    // Expect only the invalid field as outstanding.
    expect(form.outstandingFields, [
      fieldB.withError('Must be a valid boolean'),
    ]);
  }

  test_validation_file() {
    var fieldA = _fileField('a');
    var fieldB = _fileField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'file'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse(masterFields, ['file:///a/b', 'invalid']);

    // Expect only the invalid field as outstanding.
    expect(form.outstandingFields, [
      fieldB.withError('Must be a valid file:// URI'),
    ]);
  }

  test_validation_number() {
    var fieldA = _numberField('a');
    var fieldB = _numberField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'number'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse(masterFields, [1, 'invalid']);

    // Expect only the invalid field as outstanding.
    expect(form.outstandingFields, [
      fieldB.withError('Must be a valid number'),
    ]);
  }

  test_validation_string() {
    var fieldA = _stringField('a');
    var fieldB = _stringField('b');
    var masterFields = [fieldA, fieldB];

    var form = InteractiveForm(
      supportedInteractiveFormInputTypes: {'string'},
      masterFields: masterFields,
      existingAnswers: masterFields.defaults,
    );

    // Process a response with some valid and some invalid answers.
    form.processResponse(masterFields, ['valid', 2]);

    // Expect only the invalid field as outstanding.
    expect(form.outstandingFields, [
      fieldB.withError('Must be a valid string'),
    ]);
  }

  FormField _boolField(String description, [String? defaultValue]) {
    return _field(FormFieldTypeBool(), description, defaultValue);
  }

  FormField _field(
    FormFieldType type,
    String description, [
    String? defaultValue,
  ]) {
    return FormField(
      description: description,
      type: type,
      defaultValue: defaultValue,
    );
  }

  FormField _fileField(String description, [String? defaultValue]) {
    return _field(
      FormFieldTypeFile(existence: FileExistence.New, type: FileType.Regular),
      description,
      defaultValue,
    );
  }

  FormField _numberField(String description, [String? defaultValue]) {
    return _field(FormFieldTypeNumber(), description, defaultValue);
  }

  FormField _stringField(String description, [String? defaultValue]) {
    return _field(FormFieldTypeString(), description, defaultValue);
  }
}
