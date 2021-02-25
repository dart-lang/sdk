// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_single_quotes, slash_for_doc_comments
import 'package:analyzer/error/error.dart';

/// An error code representing a problem in a file containing an encoding of a
/// transform set.
class TransformSetErrorCode extends ErrorCode {
  /**
   * Parameters:
   * 0: the conflicting key
   * 1: the key that it conflicts with
   */
  static const TransformSetErrorCode conflictingKey = TransformSetErrorCode(
      'conflicting_key',
      "The key '{0}' can't be used when '{1}' is also used.");

  /**
   * No parameters.
   */
  static const TransformSetErrorCode expectedPrimary = TransformSetErrorCode(
      'expected_primary', "Expected either an identifier or a string literal.");

  /**
   * Parameters:
   * 0: the character that is invalid
   */
  static const TransformSetErrorCode invalidCharacter =
      TransformSetErrorCode('invalid_character', "Invalid character '{0}'.");

  /**
   * Parameters:
   * 0: the actual type of the key
   */
  static const TransformSetErrorCode invalidKey = TransformSetErrorCode(
      'invalid_key', "Keys must be of type 'String' but found the type '{0}'.");

  /**
   * No parameters.
   */
  static const TransformSetErrorCode invalidRequiredIf = TransformSetErrorCode(
      'invalid_required_if',
      "The key 'requiredIf' can only be used with optional named parameters.");

  /**
   * Parameters:
   * 0: the key with which the value is associated
   * 1: the expected type of the value
   * 2: the actual type of the value
   */
  static const TransformSetErrorCode invalidValue = TransformSetErrorCode(
      'invalid_value',
      "The value of '{0}' should be of type '{1}' but is of type '{2}'.");

  /**
   * Parameters:
   * 0: the list of valid parameter styles
   */
  static const TransformSetErrorCode invalidParameterStyle =
      TransformSetErrorCode('invalid_parameter_style',
          "The parameter style must be one of the following: {0}.");

  /**
   * Parameters:
   * 0: the key with which the value is associated
   * 1: the allowed values as a comma-separated list
   */
  static const TransformSetErrorCode invalidValueOneOf = TransformSetErrorCode(
      'invalid_value_one_of',
      "The value of '{0}' must be one of the following: '{1}'.");

  /**
   * Parameters:
   * 0: the missing key
   */
  static const TransformSetErrorCode missingKey =
      TransformSetErrorCode('missing_key', "Missing the required key '{0}'.");

  /**
   * Parameters:
   * 0: the list of valid keys
   */
  static const TransformSetErrorCode missingOneOfMultipleKeys =
      TransformSetErrorCode('missing_one_of_multiple_keys',
          "Exactly one of the following keys must be provided: {0}.");

  /**
   * No parameters.
   */
  static const TransformSetErrorCode missingTemplateEnd = TransformSetErrorCode(
      'missing_template_end', "Missing the end brace for the template.");

  /**
   * Parameters:
   * 0: a description of the expected kinds of tokens
   */
  static const TransformSetErrorCode missingToken =
      TransformSetErrorCode('missing_token', "Expected to find {0}.");

  /**
   * No parameters.
   */
  static const TransformSetErrorCode missingUri = TransformSetErrorCode(
      'missing_uri', "At least one URI must be provided.");

  /**
   * Parameters:
   * 0: the missing key
   */
  static const TransformSetErrorCode undefinedVariable = TransformSetErrorCode(
      'undefined_variable', "The variable '{0}' isn't defined.");

  /**
   * Parameters:
   * 0: the token that was unexpectedly found
   */
  static const TransformSetErrorCode unexpectedToken =
      TransformSetErrorCode('unexpected_token', "Didn't expect to find {0}.");

  /**
   * Parameters:
   * 0: a description of the expected kind of token
   */
  static const TransformSetErrorCode unknownAccessor = TransformSetErrorCode(
      'unknown_accessor', "The accessor '{0}' is invalid.");

  /**
   * Parameters:
   * 0: the unsupported key
   */
  static const TransformSetErrorCode unsupportedKey = TransformSetErrorCode(
      'unsupported_key', "The key '{0}' isn't supported.");

  /**
   * No parameters.
   */
  static const TransformSetErrorCode unsupportedVersion = TransformSetErrorCode(
      'unsupported_version', "Only version '1' is supported at this time.");

  /**
   * Parameters:
   * 0: a description of the expected kind of token
   * 1: a description of the actual kind of token
   */
  static const TransformSetErrorCode wrongToken = TransformSetErrorCode(
      'wrong_token', "Expected to find {0}, but found {1}.");

  /**
   * Parameters:
   * 0: the message produced by the YAML parser
   */
  static const TransformSetErrorCode yamlSyntaxError =
      TransformSetErrorCode('yaml_syntax_error', "Parse error: {0}");

  /// Initialize a newly created error code.
  const TransformSetErrorCode(
    String name,
    String message, {
    String correction,
    bool hasPublishedDocs = false,
  }) : super(
          correction: correction,
          hasPublishedDocs: hasPublishedDocs,
          message: message,
          name: name,
          uniqueName: 'TransformSetErrorCode.$name',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}
