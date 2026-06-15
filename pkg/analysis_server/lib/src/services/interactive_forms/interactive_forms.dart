// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:language_server_protocol/protocol_custom_generated.dart';

/// A class for processing interactive forms.
///
/// A form is a set of fields that should be presented to the user to collect
/// input. Collecting input for all fields may involve multiple round trips to
/// the client (because validation is done on the server).
///
/// This class manages both the outstanding set of form fields that need to go
/// back to the user, as well as updating the set of answers for the entire
/// form.
class InteractiveForm {
  /// The kinds of input the client supports.
  ///
  /// This is used as a safety check that we do not try to use form fields that
  /// are not supported unless they have default values (in which case we will
  /// use them in place of user values).
  final Set<String> supportedInteractiveFormInputTypes;

  /// The fields for this form, indexed by [FormField.id].
  final Map<String, FormField> _fieldMap = {};

  /// The master list of all fields for this form in the order to be shown to
  /// the user.
  ///
  /// The [answers] getter will return all answers with matching order/indexes.
  final List<FormField> fields;

  /// The current answers for the form and whether they are valid, indexed by
  /// [FormAnswer.id].
  ///
  /// It is not guaranteed that answers for all fields are present (for example
  /// some fields may be optional and unanswered).
  final Map<String, ({Object? value, bool isValid})> _answerMap = {};

  /// The set of fields to go back to the client.
  ///
  /// If the form is complete, this list will be empty. If there are validation
  /// errors, the errors will be attached to the fields.
  ///
  /// The order of these fields is not guaranteed. Answers should always be
  /// looked up by ID.
  final List<FormField> clientFields = [];

  /// The set of answers provided by, and to go back to, the client.
  ///
  /// The server never modifies these answers, they are just retained by
  /// [processResponse] for convenience.
  final List<FormAnswer> clientAnswers = [];

  bool _isComplete = false;

  new({
    required this.supportedInteractiveFormInputTypes,
    required this.fields,
  }) {
    // Validate input and build a map.
    for (var field in fields) {
      if (_fieldMap.containsKey(field.id)) {
        throw ArgumentError(
          'Multiple fields were given with the ID "${field.id}"',
          'fields',
        );
      } else if (!_isSupported(field) && field.defaultValue == null) {
        throw ArgumentError(
          'Field "${field.id}" is not supported by the client and does not ',
          'have a default value',
        );
      }
      _fieldMap[field.id] = field;
    }

    // Pre-populate the fields to be sent to the client.
    clientFields.addAll(_fieldMap.values.where(_isSupported));
  }

  /// A list of all answers matching the order of [fields].
  ///
  /// This list is computed on-demand and always matches the length of [fields]
  /// with unanswered questions (or those with invalid answers) having their
  /// default answers (or `null`).
  ///
  /// This getter is for convenience for callers that flatten answers into an
  /// arguments array such as for LSP command execution.
  List<Object?> get answers {
    return fields.map((field) {
      var answer = _answerMap[field.id];
      var isValid = answer?.isValid ?? !field.required;
      // Only use the users answer if valid, otherwise use the default value.
      return isValid ? answer?.value ?? field.defaultValue : field.defaultValue;
    }).toList();
  }

  /// Whether the form is complete.
  ///
  /// `true` if all required fields are present and pass validation.
  /// `false` if there are missing required fields, or validation errors.
  bool get isComplete => _isComplete;

  /// Replaces the current set of answers with a new set from the client and
  /// updates [clientAnswers] and [isComplete].
  void processResponse(List<FormAnswer> answers) {
    clientAnswers
      ..clear()
      ..addAll(answers);
    _answerMap.clear();

    // Validate input and build a map.
    Map<String, FormAnswer> answerById = {};
    for (var answer in answers) {
      if (!_fieldMap.containsKey(answer.id)) {
        throw ArgumentError(
          'Answer references non-existent field "${answer.id}"',
          'answers',
        );
      } else if (answerById.containsKey(answer.id)) {
        throw ArgumentError(
          'Multiple answers were given for field "${answer.id}"',
          'answers',
        );
      }

      answerById[answer.id] = answer;
    }

    // Validate the answers for all fields and rebuild the fields that go back
    // to the client with any validation errors.
    _isComplete = true; // Default until we see validation errors.
    clientFields.clear();
    for (var field in _fieldMap.values) {
      var answerValue = answerById[field.id]?.value;
      var errorMessage = _validateAnswer(
        field,
        // For validation, we can use the default value if none was provided.
        // This allows unsupported fields with defaults to pass validation.
        answerValue ?? field.defaultValue,
      );
      var isValid = errorMessage == null;

      // Record the current answer and validation state so it can be used by
      // [answers] later.
      _answerMap[field.id] = (value: answerValue, isValid: isValid);

      // Record any error message.
      field = field.withError(errorMessage);

      // Only supported fields go back to the client.
      if (_isSupported(field)) {
        clientFields.add(field);
      }

      // Update form completion state.
      if (!isValid) {
        // User has given an invalid answer and must be shown an error.
        _isComplete = false;
      } else if (_isSupported(field) && field.required && answerValue == null) {
        // A supported, required field does not have an answer so the form must
        // still be presented again.
        _isComplete = false;
      }
    }

    // If the form is complete, no fields go back to the client.
    if (_isComplete) {
      clientFields.clear();
    }
  }

  /// Returns whether [field] is a type of field that the client supports
  /// prompting for.
  bool _isSupported(FormField field) {
    return supportedInteractiveFormInputTypes.contains(field.type.kind);
  }

  String? _validateAnswer(FormField field, Object? answerValue) {
    // Optional fields with no answer are valid.
    if (!field.required && answerValue == null) {
      return null;
    }

    var errorMessage = switch (field.type) {
      FormFieldTypeFile() => _validateFile(answerValue),
      FormFieldTypeBool() => _validateBool(answerValue),
      FormFieldTypeNumber() => _validateNumber(answerValue),
      FormFieldTypeString() => _validateString(answerValue),
    };

    // Handle fields with custom validation.
    if (field is ValidatableFormField) {
      errorMessage ??= field._validate(answerValue);
    }

    return errorMessage;
  }

  /// Validates this value is a valid boolean, returning a user-facing error
  /// message if not.
  String? _validateBool(Object? value) {
    return value is bool ? null : 'Must be a valid boolean';
  }

  /// Validates this value is a valid file:// URI, returning a user-facing error
  /// message if not.
  String? _validateFile(Object? value) {
    var isValid =
        value is String && (Uri.tryParse(value)?.isScheme('file') ?? false);
    return isValid ? null : 'Must be a valid file:// URI';
  }

  /// Validates this value is a valid number, returning a user-facing error
  /// message if not.
  String? _validateNumber(Object? value) {
    return value is num ? null : 'Must be a valid number';
  }

  /// Validates this value is a valid string, returning a user-facing error
  /// message if not.
  String? _validateString(Object? value) {
    return value is String ? null : 'Must be a valid string';
  }
}

/// A [FormField] with custom validation.
class ValidatableFormField extends FormField {
  /// A custom validation function for this field.
  ///
  /// Returns `null` if the value is valid, otherwise a validation error
  /// message.
  final String? Function(Object? value) _validate;

  new({
    super.defaultValue,
    required super.description,
    super.error,
    required super.id,
    required super.required,
    required super.type,
    required this._validate,
  });
}

extension FormFieldExtension on FormField {
  FormField withError(String? error) {
    if (this.error == error) {
      return this;
    } else {
      return FormField(
        id: id,
        description: description,
        type: type,
        required: required,
        defaultValue: defaultValue,
        error: error,
      );
    }
  }
}
