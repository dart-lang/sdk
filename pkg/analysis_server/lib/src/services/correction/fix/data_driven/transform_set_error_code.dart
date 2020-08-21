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
   * 0: the unsupported key
   */
  static const TransformSetErrorCode unsupportedKey = TransformSetErrorCode(
      'unsupported_key', "The key '{0}' isn't supported.");

  /**
   * Parameters:
   * 0: the message produced by the YAML parser
   */
  static const TransformSetErrorCode yamlSyntaxError =
      TransformSetErrorCode('yaml_syntax_error', "{0}");

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
