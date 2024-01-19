// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

// While transitioning `HintCodes` to `WarningCodes`, we refer to deprecated
// codes here.
// ignore_for_file: deprecated_member_use_from_same_package
//
// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

import "package:analyzer/error/error.dart";

class AnalysisOptionsErrorCode extends ErrorCode {
  ///  An error code indicating that there is a syntactic error in the included
  ///  file.
  ///
  ///  Parameters:
  ///  0: the path of the file containing the error
  ///  1: the starting offset of the text in the file that contains the error
  ///  2: the ending offset of the text in the file that contains the error
  ///  3: the error message
  static const AnalysisOptionsErrorCode INCLUDED_FILE_PARSE_ERROR =
      AnalysisOptionsErrorCode(
    'INCLUDED_FILE_PARSE_ERROR',
    "{3} in {0}({1}..{2})",
  );

  ///  An error code indicating that there is a syntactic error in the file.
  ///
  ///  Parameters:
  ///  0: the error message from the parse error
  static const AnalysisOptionsErrorCode PARSE_ERROR = AnalysisOptionsErrorCode(
    'PARSE_ERROR',
    "{0}",
  );

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsErrorCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'AnalysisOptionsErrorCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

class AnalysisOptionsHintCode extends ErrorCode {
  ///  A hint code indicating reference to a deprecated lint.
  ///
  ///  Parameters:
  ///  0: the rule name
  static const AnalysisOptionsHintCode DEPRECATED_LINT =
      AnalysisOptionsHintCode(
    'DEPRECATED_LINT',
    "'{0}' is a deprecated lint rule and should not be used.",
    correctionMessage: "Try removing '{0}'.",
  );

  ///  A hint code indicating reference to a deprecated lint.
  ///
  ///  Parameters:
  ///  0: the deprecated lint name
  ///  1: the replacing rule name
  static const AnalysisOptionsHintCode DEPRECATED_LINT_WITH_REPLACEMENT =
      AnalysisOptionsHintCode(
    'DEPRECATED_LINT_WITH_REPLACEMENT',
    "'{0}' is deprecated and should be replaced by '{1}'.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
  );

  ///  Duplicate rules.
  ///
  ///  Parameters:
  ///  0: the rule name
  static const AnalysisOptionsHintCode DUPLICATE_RULE = AnalysisOptionsHintCode(
    'DUPLICATE_RULE',
    "The rule {0} is already specified and doesn't need to be specified again.",
    correctionMessage: "Try removing all but one specification of the rule.",
  );

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsHintCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'AnalysisOptionsHintCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.HINT;
}

class AnalysisOptionsWarningCode extends ErrorCode {
  ///  An error code indicating that the given option is deprecated.
  ///
  ///  Parameters:
  ///  0: the option name
  ///
  static const AnalysisOptionsWarningCode ANALYSIS_OPTION_DEPRECATED =
      AnalysisOptionsWarningCode(
    'ANALYSIS_OPTION_DEPRECATED',
    "The option '{0}' is no longer supported.",
  );

  ///  An error code indicating that the given option is deprecated.
  ///
  ///  Parameters:
  ///  0: the option name
  ///  1: the replacement option name
  static const AnalysisOptionsWarningCode
      ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT = AnalysisOptionsWarningCode(
    'ANALYSIS_OPTION_DEPRECATED',
    "The option '{0}' is no longer supported.",
    correctionMessage: "Try using the new '{1}' option.",
    uniqueName: 'ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT',
  );

  ///  An error code indicating a specified include file has a warning.
  ///
  ///  Parameters:
  ///  0: the path of the file containing the warnings
  ///  1: the starting offset of the text in the file that contains the warning
  ///  2: the ending offset of the text in the file that contains the warning
  ///  3: the warning message
  static const AnalysisOptionsWarningCode INCLUDED_FILE_WARNING =
      AnalysisOptionsWarningCode(
    'INCLUDED_FILE_WARNING',
    "Warning in the included options file {0}({1}..{2}): {3}",
  );

  ///  An error code indicating a specified include file could not be found.
  ///
  ///  Parameters:
  ///  0: the URI of the file to be included
  ///  1: the path of the file containing the include directive
  ///  2: the path of the context being analyzed
  static const AnalysisOptionsWarningCode INCLUDE_FILE_NOT_FOUND =
      AnalysisOptionsWarningCode(
    'INCLUDE_FILE_NOT_FOUND',
    "The include file '{0}' in '{1}' can't be found when analyzing '{2}'.",
  );

  ///  An error code indicating an incompatible rule.
  ///
  ///  Parameters:
  ///  0: the rule name
  ///  1: the incompatible rule
  static const AnalysisOptionsWarningCode INCOMPATIBLE_LINT =
      AnalysisOptionsWarningCode(
    'INCOMPATIBLE_LINT',
    "The rule '{0}' is incompatible with the rule '{1}'.",
    correctionMessage: "Try removing one of the incompatible rules.",
  );

  ///  An error code indicating that a plugin is being configured with an invalid
  ///  value for an option and a detail message is provided.
  ///
  ///  Parameters:
  ///  0: the option name
  ///  1: the detail message
  static const AnalysisOptionsWarningCode INVALID_OPTION =
      AnalysisOptionsWarningCode(
    'INVALID_OPTION',
    "Invalid option specified for '{0}': {1}",
  );

  ///  An error code indicating an invalid format for an options file section.
  ///
  ///  Parameters:
  ///  0: the section name
  static const AnalysisOptionsWarningCode INVALID_SECTION_FORMAT =
      AnalysisOptionsWarningCode(
    'INVALID_SECTION_FORMAT',
    "Invalid format for the '{0}' section.",
  );

  ///  An error code indicating multiple plugins have been specified as enabled.
  ///
  ///  Parameters:
  ///  0: the name of the first plugin
  static const AnalysisOptionsWarningCode MULTIPLE_PLUGINS =
      AnalysisOptionsWarningCode(
    'MULTIPLE_PLUGINS',
    "Multiple plugins can't be enabled.",
    correctionMessage: "Remove all plugins following the first, '{0}'.",
  );

  ///  An error code indicating a specified include file includes itself recursively.
  ///
  ///  Parameters:
  ///  0: the URI of the file to be included
  ///  1: the path of the file containing the include directive
  static const AnalysisOptionsWarningCode RECURSIVE_INCLUDE_FILE =
      AnalysisOptionsWarningCode(
    'RECURSIVE_INCLUDE_FILE',
    "The include file '{0}' in '{1}' includes itself recursively.",
    correctionMessage:
        "Try changing the chain of 'include's to not re-include this file.",
  );

  ///  An error code indicating a removed lint rule.
  ///
  ///  Parameters:
  ///  0: the rule name
  ///  1: the SDK version in which the lint was removed
  static const AnalysisOptionsWarningCode REMOVED_LINT =
      AnalysisOptionsWarningCode(
    'REMOVED_LINT',
    "'{0}' was removed in Dart '{1}'",
    correctionMessage: "Remove the reference to '{0}'.",
  );

  ///  An error code indicating a removed lint rule.
  ///
  ///  Parameters:
  ///  0: the rule name
  ///  1: the SDK version in which the lint was removed
  ///  2: the name of a replacing lint
  static const AnalysisOptionsWarningCode REPLACED_LINT =
      AnalysisOptionsWarningCode(
    'REPLACED_LINT',
    "'{0}' was replaced by '{2}' in Dart '{1}'.",
    correctionMessage: "Replace '{0}' with '{1}'.",
  );

  ///  An error code indicating an undefined lint rule.
  ///
  ///  Parameters:
  ///  0: the rule name
  static const AnalysisOptionsWarningCode UNDEFINED_LINT =
      AnalysisOptionsWarningCode(
    'UNDEFINED_LINT',
    "'{0}' is not a recognized lint rule.",
    correctionMessage: "Try using the name of a recognized lint rule.",
  );

  ///  An error code indicating that an unrecognized error code is being used to
  ///  specify an error filter.
  ///
  ///  Parameters:
  ///  0: the unrecognized error code
  static const AnalysisOptionsWarningCode UNRECOGNIZED_ERROR_CODE =
      AnalysisOptionsWarningCode(
    'UNRECOGNIZED_ERROR_CODE',
    "'{0}' isn't a recognized error code.",
  );

  ///  An error code indicating that a plugin is being configured with an
  ///  unsupported option and legal options are provided.
  ///
  ///  Parameters:
  ///  0: the plugin name
  ///  1: the unsupported option key
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITHOUT_VALUES =
      AnalysisOptionsWarningCode(
    'UNSUPPORTED_OPTION_WITHOUT_VALUES',
    "The option '{1}' isn't supported by '{0}'.",
  );

  ///  An error code indicating that a plugin is being configured with an
  ///  unsupported option where there is just one legal value.
  ///
  ///  Parameters:
  ///  0: the plugin name
  ///  1: the unsupported option key
  ///  2: the legal value
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITH_LEGAL_VALUE =
      AnalysisOptionsWarningCode(
    'UNSUPPORTED_OPTION_WITH_LEGAL_VALUE',
    "The option '{1}' isn't supported by '{0}'. Try using the only supported "
        "option: '{2}'.",
  );

  ///  An error code indicating that a plugin is being configured with an
  ///  unsupported option and legal options are provided.
  ///
  ///  Parameters:
  ///  0: the plugin name
  ///  1: the unsupported option key
  ///  2: legal values
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITH_LEGAL_VALUES =
      AnalysisOptionsWarningCode(
    'UNSUPPORTED_OPTION_WITH_LEGAL_VALUES',
    "The option '{1}' isn't supported by '{0}'.",
    correctionMessage: "Try using one of the supported options: {2}.",
  );

  ///  An error code indicating that an option entry is being configured with an
  ///  unsupported value.
  ///
  ///  Parameters:
  ///  0: the option name
  ///  1: the unsupported value
  ///  2: legal values
  static const AnalysisOptionsWarningCode UNSUPPORTED_VALUE =
      AnalysisOptionsWarningCode(
    'UNSUPPORTED_VALUE',
    "The value '{1}' isn't supported by '{0}'.",
    correctionMessage: "Try using one of the supported options: {2}.",
  );

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsWarningCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'AnalysisOptionsWarningCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
