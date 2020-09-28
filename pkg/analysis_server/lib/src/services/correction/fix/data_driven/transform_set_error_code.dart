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
   * 0: the key with which the value is associated
   * 1: the expected type of the value
   * 0: the actual type of the value
   */
  static const TransformSetErrorCode invalidValue = TransformSetErrorCode(
      'invalid_value',
      "The value of '{0}' should be of type '{1}' but is of type '{2}'.");

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
   * No parameters.
   */
  static const TransformSetErrorCode missingTemplateEnd = TransformSetErrorCode(
      'missing_template_end', "Missing the end brace for the template.");

  /**
   * Parameters:
   * 0: the missing key
   */
  static const TransformSetErrorCode undefinedVariable = TransformSetErrorCode(
      'undefined_variable', "The variable '{0}' is not defined.");

  /**
   * Parameters:
   * 0: the unsupported key
   */
  static const TransformSetErrorCode unsupportedKey = TransformSetErrorCode(
      'unsupported_key', "The key '{0}' isn't supported.");

  /**
   * Parameters:
   * 0: the message produced by the YAML parser
   */
  static const TransformSetErrorCode yamlSyntaxError =
      TransformSetErrorCode('yaml_syntax_error', "Parse error: {0}");

  /// Initialize a newly created error code.
  const TransformSetErrorCode(String name, String message,
      {String correction, bool hasPublishedDocs = false})
      : super.temporary(name, message,
            correction: correction, hasPublishedDocs: hasPublishedDocs);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}
