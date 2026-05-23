// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
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

  /// The complete set of all fields for this form regardless of whether they
  /// are supported by the client or previously answered.
  final List<FormField> _masterFields;

  /// The set of existing answers.
  ///
  /// The items in this list correspond go the fields in [_masterFields].
  /// Initially this list will contain nulls or default values but should become
  /// populated after round trips to the client.
  ///
  /// It is up to the caller to determine how to carry answers from
  /// [existingAnswers] through the client and back into this field. For
  /// commands this is usually in the real set of arguments against the command.
  ///
  /// These answers will be updated by [processResponse] so they can be
  /// sent back to the client.
  final List<Object?> existingAnswers;

  /// The current outstanding fields that need to go back to the client.
  final List<FormField> outstandingFields = [];

  /// The current answers for [outstandingFields].
  ///
  /// Values may be `null` if the user has not provided a value, but the list
  /// always contains the same number of items as [outstandingFields].
  final List<Object?> outstandingFieldAnswers = [];

  InteractiveForm({
    required this.supportedInteractiveFormInputTypes,
    required this._masterFields,
    required this.existingAnswers,
  }) {
    if (_masterFields.length != existingAnswers.length) {
      throw ArgumentError(
        'masterFields and existingAnswers must have the same length',
      );
    }

    // Process the full set of fields initially, so we can handle defaults for
    // unsupported fields by reading their answers and removing them from the
    // outstanding field list.
    processResponse(_masterFields, List.filled(_masterFields.length, null));
  }

  /// Processes the set of answers from the client, updating
  /// [outstandingFields], [outstandingFieldAnswers] and [existingAnswers].
  ///
  /// [clientFields] is the set of fields that returned from the client (the
  /// previous turns [outstandingFields]), and [clientAnswers] are the responses
  /// (matched by index).
  void processResponse(
    List<FormField> clientFields,
    List<Object?> clientAnswers,
  ) {
    if (clientFields.length != clientAnswers.length) {
      throw ArgumentError(
        'clientFields and clientAnswers must have the same length',
      );
    }

    // Validate all responses from the client.
    var responses = clientFields
        .mapIndexed((i, field) => _validate(field, clientAnswers[i]))
        .toList();

    // Rebuild the outstanding fields from only those that did not contain
    // valid answers.
    outstandingFields.clear();
    outstandingFieldAnswers.clear();

    // Process any responses and update the existing answers.
    for (var response in responses) {
      var field = response.field;
      var isValid = response.isValid;
      var value = response.value;

      if (!isValid) {
        // Field is not valid and must go back to the client.
        outstandingFields.add(field);
        outstandingFieldAnswers.add(value);
      } else {
        // Field was valid, so update the existing answers.
        var masterIndex = _masterFields.indexWhere(field.matches);
        if (masterIndex == -1) {
          throw StateError(
            "Field '${field.description}' provided by client is not recognised by the server",
          );
        }
        existingAnswers[masterIndex] = value;
      }
    }

    assert(outstandingFields.length == outstandingFieldAnswers.length);
    assert(_masterFields.length == existingAnswers.length);
  }

  /// Returns whether [field] is a type of field that the client supports
  /// prompting for.
  bool _isSupported(FormField field) {
    return supportedInteractiveFormInputTypes.contains(field.type.kind);
  }

  ValidatedResponse _validate(FormField field, Object? answer) {
    // If a field is not supported, it must have a default and we will use
    // that value and consider it valid. It is up to the caller (for example the
    // refactor) to ensure that if there are required fields with no defaults
    // that they do not present themselves to the user (for example by checking
    // in isAvailable).
    if (answer == null && !_isSupported(field)) {
      if (field.defaultValue == null) {
        throw ArgumentError(
          "The form field '${field.description}' is not supported by "
          'the client and has no default value',
        );
      }
      answer = field.defaultValue;
    }

    var errorMessage = _validateAnswer(field, answer);
    var isValid = answer != null && errorMessage == null;

    // Only attach error messages if the user had provided a value.
    if (answer != null) {
      field = field.withError(errorMessage);
    }

    return ValidatedResponse(field, answer, isValid: isValid);
  }

  String? _validateAnswer(FormField field, Object? answer) {
    return switch (field.type) {
      FormFieldTypeFile() => _validateFile(answer),
      FormFieldTypeBool() => _validateBool(answer),
      FormFieldTypeNumber() => _validateNumber(answer),
      FormFieldTypeString() => _validateString(answer),
    };
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

class ValidatedResponse {
  /// The [FormField] this response relates to.
  final FormField field;

  /// The current value provided by the user.
  ///
  /// The value might be null (if the user has not provided an answer), or an
  /// invalid value (or even an incorrect type).
  final Object? value;

  /// Whether the valid provided in [value] validated correctly and the user
  /// does not need to be re-prompted for this field.
  final bool isValid;

  ValidatedResponse(this.field, this.value, {required this.isValid});
}

extension FormFieldExtension on FormField {
  /// Returns whether this field is the same as [other].
  ///
  /// Fields are round-tripped to the client so we cannot check references for
  /// equality. The fields sent to the client may also include error messages so
  /// we cannot use value equality.
  ///
  /// We assume that the type + description are a unique pair.
  bool matches(FormField other) {
    // TODO(dantup): Determine if we can do something better here.
    return description == other.description && type == other.type;
  }

  FormField withError(String? error) {
    if (this.error == error) {
      return this;
    } else {
      return FormField(
        description: description,
        type: type,
        defaultValue: defaultValue,
        error: error,
      );
    }
  }
}

extension ListFormField on List<FormField> {
  /// The default values for these fields.
  List<Object?> get defaults => map((field) => field.defaultValue).toList();
}
