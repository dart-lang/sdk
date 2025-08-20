// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// While transitioning `HintCodes` to `WarningCodes`, we refer to deprecated
// codes here.
// ignore_for_file: deprecated_member_use_from_same_package
//
// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/analysis_options/error/option_codes.dart";

class AnalysisOptionsErrorCode extends DiagnosticCode {
  /// An error code indicating that there is a syntactic error in the included
  /// file.
  ///
  /// Parameters:
  /// Object p0: the path of the file containing the error
  /// Object p1: the starting offset of the text in the file that contains the
  ///            error
  /// Object p2: the ending offset of the text in the file that contains the
  ///            error
  /// Object p3: the error message
  static const AnalysisOptionsErrorCode includedFileParseError =
      AnalysisOptionsErrorCode(
        'INCLUDED_FILE_PARSE_ERROR',
        "{3} in {0}({1}..{2})",
      );

  /// An error code indicating that there is a syntactic error in the file.
  ///
  /// Parameters:
  /// Object p0: the error message from the parse error
  static const AnalysisOptionsErrorCode parseError = AnalysisOptionsErrorCode(
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
  DiagnosticSeverity get severity => DiagnosticSeverity.ERROR;

  @override
  DiagnosticType get type => DiagnosticType.COMPILE_TIME_ERROR;
}

class AnalysisOptionsWarningCode extends DiagnosticCode {
  /// An error code indicating that the given option is deprecated.
  ///
  /// Parameters:
  /// Object p0: the option name
  static const AnalysisOptionsWarningCode analysisOptionDeprecated =
      AnalysisOptionsWarningCode(
        'ANALYSIS_OPTION_DEPRECATED',
        "The option '{0}' is no longer supported.",
      );

  /// An error code indicating that the given option is deprecated.
  ///
  /// Parameters:
  /// Object p0: the option name
  /// Object p1: the replacement option name
  static const AnalysisOptionsWarningCode
  analysisOptionDeprecatedWithReplacement = AnalysisOptionsWarningCode(
    'ANALYSIS_OPTION_DEPRECATED',
    "The option '{0}' is no longer supported.",
    correctionMessage: "Try using the new '{1}' option.",
    uniqueName: 'ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT',
  );

  /// A hint code indicating reference to a deprecated lint.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const AnalysisOptionsWarningCode deprecatedLint =
      AnalysisOptionsWarningCode(
        'DEPRECATED_LINT',
        "'{0}' is a deprecated lint rule and should not be used.",
        correctionMessage: "Try removing '{0}'.",
      );

  /// A hint code indicating reference to a deprecated lint.
  ///
  /// Parameters:
  /// String p0: the deprecated lint name
  /// String p1: the replacing rule name
  static const AnalysisOptionsWarningCode deprecatedLintWithReplacement =
      AnalysisOptionsWarningCode(
        'DEPRECATED_LINT_WITH_REPLACEMENT',
        "'{0}' is deprecated and should be replaced by '{1}'.",
        correctionMessage: "Try replacing '{0}' with '{1}'.",
      );

  /// Duplicate rules.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const AnalysisOptionsWarningCode
  duplicateRule = AnalysisOptionsWarningCode(
    'DUPLICATE_RULE',
    "The rule {0} is already specified and doesn't need to be specified again.",
    correctionMessage: "Try removing all but one specification of the rule.",
  );

  /// An error code indicating a specified include file has a warning.
  ///
  /// Parameters:
  /// Object p0: the path of the file containing the warnings
  /// Object p1: the starting offset of the text in the file that contains the
  ///            warning
  /// Object p2: the ending offset of the text in the file that contains the
  ///            warning
  /// Object p3: the warning message
  static const AnalysisOptionsWarningCode includedFileWarning =
      AnalysisOptionsWarningCode(
        'INCLUDED_FILE_WARNING',
        "Warning in the included options file {0}({1}..{2}): {3}",
      );

  /// An error code indicating a specified include file could not be found.
  ///
  /// Parameters:
  /// Object p0: the URI of the file to be included
  /// Object p1: the path of the file containing the include directive
  /// Object p2: the path of the context being analyzed
  static const AnalysisOptionsWarningCode includeFileNotFound =
      AnalysisOptionsWarningCode(
        'INCLUDE_FILE_NOT_FOUND',
        "The include file '{0}' in '{1}' can't be found when analyzing '{2}'.",
      );

  /// An error code indicating an incompatible rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the incompatible rule
  static const AnalysisOptionsWarningCode incompatibleLint =
      AnalysisOptionsWarningCode(
        'INCOMPATIBLE_LINT',
        "The rule '{0}' is incompatible with the rule '{1}'.",
        correctionMessage: "Try removing one of the incompatible rules.",
      );

  /// An error code indicating that a plugin is being configured with an invalid
  /// value for an option and a detail message is provided.
  ///
  /// Parameters:
  /// String p0: the option name
  /// String p1: the detail message
  static const AnalysisOptionsWarningCode invalidOption =
      AnalysisOptionsWarningCode(
        'INVALID_OPTION',
        "Invalid option specified for '{0}': {1}",
      );

  /// An error code indicating an invalid format for an options file section.
  ///
  /// Parameters:
  /// String p0: the section name
  static const AnalysisOptionsWarningCode invalidSectionFormat =
      AnalysisOptionsWarningCode(
        'INVALID_SECTION_FORMAT',
        "Invalid format for the '{0}' section.",
      );

  /// An error code indicating multiple plugins have been specified as enabled.
  ///
  /// Parameters:
  /// String p0: the name of the first plugin
  static const AnalysisOptionsWarningCode multiplePlugins =
      AnalysisOptionsWarningCode(
        'MULTIPLE_PLUGINS',
        "Multiple plugins can't be enabled.",
        correctionMessage: "Remove all plugins following the first, '{0}'.",
      );

  /// An error code indicating a specified include file includes itself recursively.
  ///
  /// Parameters:
  /// Object p0: the URI of the file to be included
  /// Object p1: the path of the file containing the include directive
  static const AnalysisOptionsWarningCode recursiveIncludeFile =
      AnalysisOptionsWarningCode(
        'RECURSIVE_INCLUDE_FILE',
        "The include file '{0}' in '{1}' includes itself recursively.",
        correctionMessage:
            "Try changing the chain of 'include's to not re-include this file.",
      );

  /// An error code indicating a removed lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the SDK version in which the lint was removed
  static const AnalysisOptionsWarningCode removedLint =
      AnalysisOptionsWarningCode(
        'REMOVED_LINT',
        "'{0}' was removed in Dart '{1}'",
        correctionMessage: "Remove the reference to '{0}'.",
      );

  /// An error code indicating a removed lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the SDK version in which the lint was removed
  /// String p2: the name of a replacing lint
  static const AnalysisOptionsWarningCode replacedLint =
      AnalysisOptionsWarningCode(
        'REPLACED_LINT',
        "'{0}' was replaced by '{2}' in Dart '{1}'.",
        correctionMessage: "Replace '{0}' with '{1}'.",
      );

  /// An error code indicating an undefined lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const AnalysisOptionsWarningCode undefinedLint =
      AnalysisOptionsWarningCode(
        'UNDEFINED_LINT',
        "'{0}' is not a recognized lint rule.",
        correctionMessage: "Try using the name of a recognized lint rule.",
      );

  /// An error code indicating that an unrecognized error code is being used to
  /// specify an error filter.
  ///
  /// Parameters:
  /// String p0: the unrecognized error code
  static const AnalysisOptionsWarningCode unrecognizedErrorCode =
      AnalysisOptionsWarningCode(
        'UNRECOGNIZED_ERROR_CODE',
        "'{0}' isn't a recognized error code.",
      );

  /// An error code indicating that a YAML section is being configured with an
  /// unsupported option where there is just one legal value.
  ///
  /// Parameters:
  /// String p0: the section name
  /// String p1: the unsupported option key
  /// String p2: the legal value
  static const AnalysisOptionsWarningCode
  unsupportedOptionWithLegalValue = AnalysisOptionsWarningCode(
    'UNSUPPORTED_OPTION_WITH_LEGAL_VALUE',
    "The option '{1}' isn't supported by '{0}'. Try using the only supported "
        "option: '{2}'.",
  );

  /// An error code indicating that a YAML section is being configured with an
  /// unsupported option and legal options are provided.
  ///
  /// Parameters:
  /// String p0: the section name
  /// String p1: the unsupported option key
  /// String p2: legal values
  static const AnalysisOptionsWarningCode unsupportedOptionWithLegalValues =
      AnalysisOptionsWarningCode(
        'UNSUPPORTED_OPTION_WITH_LEGAL_VALUES',
        "The option '{1}' isn't supported by '{0}'.",
        correctionMessage: "Try using one of the supported options: {2}.",
      );

  /// An error code indicating that a plugin is being configured with an
  /// unsupported option and legal options are provided.
  ///
  /// Parameters:
  /// String p0: the plugin name
  /// String p1: the unsupported option key
  static const AnalysisOptionsWarningCode unsupportedOptionWithoutValues =
      AnalysisOptionsWarningCode(
        'UNSUPPORTED_OPTION_WITHOUT_VALUES',
        "The option '{1}' isn't supported by '{0}'.",
      );

  /// An error code indicating that an option entry is being configured with an
  /// unsupported value.
  ///
  /// Parameters:
  /// String p0: the option name
  /// int p1: the unsupported value
  /// String p2: legal values
  static const AnalysisOptionsWarningCode unsupportedValue =
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
  DiagnosticSeverity get severity => DiagnosticSeverity.WARNING;

  @override
  DiagnosticType get type => DiagnosticType.STATIC_WARNING;
}
