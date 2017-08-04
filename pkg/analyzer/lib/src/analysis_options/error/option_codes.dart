// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.analysis_options.error.option_codes;

import 'package:analyzer/error/error.dart';

/**
 * The error codes used for errors in analysis options files. The convention for
 * this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what is
 * wrong and, when appropriate, how the problem can be corrected.
 */
class AnalysisOptionsErrorCode extends ErrorCode {
  /**
   * An error code indicating that there is a syntactic error in the included
   * file.
   *
   * Parameters:
   * 0: the path of the file containing the error
   * 1: the starting offset of the text in the file that contains the error
   * 2: the ending offset of the text in the file that contains the error
   * 3: the error message
   */
  static const AnalysisOptionsErrorCode INCLUDED_FILE_PARSE_ERROR =
      const AnalysisOptionsErrorCode(
          'INCLUDED_FILE_PARSE_ERROR', '{3} in {0}({1}..{2})');

  /**
   * An error code indicating that there is a syntactic error in the file.
   *
   * Parameters:
   * 0: the error message from the parse error
   */
  static const AnalysisOptionsErrorCode PARSE_ERROR =
      const AnalysisOptionsErrorCode('PARSE_ERROR', '{0}');

  /**
   * Initialize a newly created error code to have the given [name].
   */
  const AnalysisOptionsErrorCode(String name, String message,
      [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

/**
 * The error codes used for warnings in analysis options files. The convention
 * for this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what is
 * wrong and, when appropriate, how the problem can be corrected.
 */
class AnalysisOptionsWarningCode extends ErrorCode {
  /**
   * An error code indicating a specified include file could not be found.
   *
   * Parameters:
   * 0: the uri of the file to be included
   * 1: the path of the file containing the include directive
   */
  static const AnalysisOptionsWarningCode INCLUDE_FILE_NOT_FOUND =
      const AnalysisOptionsWarningCode('INCLUDE_FILE_NOT_FOUND',
          "The include file {0} in {1} cannot be found.");

  /**
   * An error code indicating a specified include file has a warning.
   *
   * Parameters:
   * 0: the path of the file containing the warnings
   * 1: the starting offset of the text in the file that contains the warning
   * 2: the ending offset of the text in the file that contains the warning
   * 3: the warning message
   */
  static const AnalysisOptionsWarningCode INCLUDED_FILE_WARNING =
      const AnalysisOptionsWarningCode('INCLUDED_FILE_WARNING',
          "Warning in the included options file {0}({1}..{2}): {3}");

  /**
   * An error code indicating that an unrecognized error code is being used to
   * specify an error filter.
   *
   * Parameters:
   * 0: the unrecognized error code
   */
  static const AnalysisOptionsWarningCode UNRECOGNIZED_ERROR_CODE =
      const AnalysisOptionsWarningCode(
          'UNRECOGNIZED_ERROR_CODE', "'{0}' isn't a recognized error code.");

  /**
   * An error code indicating that a plugin is being configured with an
   * unsupported option where there is just one legal value.
   *
   * Parameters:
   * 0: the plugin name
   * 1: the unsupported option key
   * 2: the legal value
   */
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITH_LEGAL_VALUE =
      const AnalysisOptionsWarningCode(
          'UNSUPPORTED_OPTION_WITH_LEGAL_VALUE',
          "The option '{1}' isn't supported by '{0}'."
          "Try using the only supported option: '{2}'.");

  /**
   * An error code indicating that a plugin is being configured with an
   * unsupported option and legal options are provided.
   *
   * Parameters:
   * 0: the plugin name
   * 1: the unsupported option key
   * 2: legal values
   */
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITH_LEGAL_VALUES =
      const AnalysisOptionsWarningCode(
          'UNSUPPORTED_OPTION_WITH_LEGAL_VALUES',
          "The option '{1}' isn't supported by '{0}'.",
          "Try using one of the supported options: {2}.");

  /**
   * An error code indicating that an option entry is being configured with an
   * unsupported value.
   *
   * Parameters:
   * 0: the option name
   * 1: the unsupported value
   * 2: legal values
   */
  static const AnalysisOptionsWarningCode UNSUPPORTED_VALUE =
      const AnalysisOptionsWarningCode(
          'UNSUPPORTED_VALUE',
          "The value '{1}' isn't supported by '{0}'.",
          "Try using one of the supported options: {2}.");

  /**
   * Initialize a newly created warning code to have the given [name].
   */
  const AnalysisOptionsWarningCode(String name, String message,
      [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
