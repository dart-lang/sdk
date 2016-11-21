// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/errors.dart';

/**
 * The error codes used for errors detected by the scanner.
 */
class ScannerErrorCode extends ErrorCode {
  /**
   * Parameters:
   * 0: the illegal character
   */
  static const ScannerErrorCode ILLEGAL_CHARACTER =
      const ScannerErrorCode('ILLEGAL_CHARACTER', "Illegal character '{0}'.");

  static const ScannerErrorCode MISSING_DIGIT =
      const ScannerErrorCode('MISSING_DIGIT', "Decimal digit expected.");

  static const ScannerErrorCode MISSING_HEX_DIGIT = const ScannerErrorCode(
      'MISSING_HEX_DIGIT', "Hexidecimal digit expected.");

  static const ScannerErrorCode MISSING_QUOTE =
      const ScannerErrorCode('MISSING_QUOTE', "Expected quote (' or \").");

  /**
   * Parameters:
   * 0: the path of the file that cannot be read
   */
  static const ScannerErrorCode UNABLE_GET_CONTENT = const ScannerErrorCode(
      'UNABLE_GET_CONTENT', "Unable to get content of '{0}'.");

  static const ScannerErrorCode UNTERMINATED_MULTI_LINE_COMMENT =
      const ScannerErrorCode(
          'UNTERMINATED_MULTI_LINE_COMMENT',
          "Unterminated multi-line comment.",
          "Try terminating the comment with '*/', or "
          "removing any unbalanced occurances of '/*' (because comments nest in Dart).");

  static const ScannerErrorCode UNTERMINATED_STRING_LITERAL =
      const ScannerErrorCode(
          'UNTERMINATED_STRING_LITERAL', "Unterminated string literal.");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const ScannerErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}
