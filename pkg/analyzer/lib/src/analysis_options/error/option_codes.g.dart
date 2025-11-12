// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/analysis_options/error/option_codes.dart";

class AnalysisOptionsErrorCode {
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
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  includedFileParseError = diag.includedFileParseError;

  /// An error code indicating that there is a syntactic error in the file.
  ///
  /// Parameters:
  /// Object p0: the error message from the parse error
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  parseError = diag.parseError;

  /// Do not construct instances of this class.
  AnalysisOptionsErrorCode._() : assert(false);
}

class AnalysisOptionsWarningCode {
  /// An error code indicating that the given option is deprecated.
  ///
  /// Parameters:
  /// Object p0: the option name
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  analysisOptionDeprecated = diag.analysisOptionDeprecated;

  /// An error code indicating that the given option is deprecated.
  ///
  /// Parameters:
  /// Object p0: the option name
  /// Object p1: the replacement option name
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  analysisOptionDeprecatedWithReplacement =
      diag.analysisOptionDeprecatedWithReplacement;

  /// A hint code indicating reference to a deprecated lint.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedLint = diag.deprecatedLint;

  /// A hint code indicating reference to a deprecated lint.
  ///
  /// Parameters:
  /// String p0: the deprecated lint name
  /// String p1: the replacing rule name
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  deprecatedLintWithReplacement = diag.deprecatedLintWithReplacement;

  /// Duplicate rules.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateRule = diag.duplicateRule;

  /// An error code indicating a specified include file has a warning.
  ///
  /// Parameters:
  /// Object p0: the path of the file containing the warnings
  /// Object p1: the starting offset of the text in the file that contains the
  ///            warning
  /// Object p2: the ending offset of the text in the file that contains the
  ///            warning
  /// Object p3: the warning message
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  includedFileWarning = diag.includedFileWarning;

  /// An error code indicating a specified include file could not be found.
  ///
  /// Parameters:
  /// Object p0: the URI of the file to be included
  /// Object p1: the path of the file containing the include directive
  /// Object p2: the path of the context being analyzed
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  includeFileNotFound = diag.includeFileNotFound;

  /// An error code indicating an incompatible rule.
  ///
  /// The incompatible rules must be included by context messages.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the incompatible rules
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  incompatibleLint = diag.incompatibleLint;

  /// An error code indicating an incompatible rule.
  ///
  /// The files that enable the referenced rules must be included by context messages.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the incompatible rules
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  incompatibleLintFiles = diag.incompatibleLintFiles;

  /// An error code indicating an incompatible rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the incompatible rules
  /// int p2: the number of files that include the incompatible rule
  /// String p3: plural suffix for the word "file"
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required int p2,
      required String p3,
    })
  >
  incompatibleLintIncluded = diag.incompatibleLintIncluded;

  /// An error code indicating that a plugin is being configured with an invalid
  /// value for an option and a detail message is provided.
  ///
  /// Parameters:
  /// String p0: the option name
  /// String p1: the detail message
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidOption = diag.invalidOption;

  /// An error code indicating an invalid format for an options file section.
  ///
  /// Parameters:
  /// String p0: the section name
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidSectionFormat = diag.invalidSectionFormat;

  /// An error code indicating multiple plugins have been specified as enabled.
  ///
  /// Parameters:
  /// String p0: the name of the first plugin
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  multiplePlugins = diag.multiplePlugins;

  /// An error code indicating plugins have been specified in an "inner"
  /// analysis options file.
  ///
  /// Parameters:
  /// String contextRoot: the root of the analysis context
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String contextRoot})
  >
  pluginsInInnerOptions = diag.pluginsInInnerOptions;

  /// An error code indicating a specified include file includes itself recursively.
  ///
  /// Parameters:
  /// Object p0: the URI of the file to be included
  /// Object p1: the path of the file containing the include directive
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  recursiveIncludeFile = diag.recursiveIncludeFile;

  /// An error code indicating a removed lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the SDK version in which the lint was removed
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  removedLint = diag.removedLint;

  /// An error code indicating a removed lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the SDK version in which the lint was removed
  /// String p2: the name of a replacing lint
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  replacedLint = diag.replacedLint;

  /// An error code indicating an undefined lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedLint = diag.undefinedLint;

  /// An error code indicating that an unrecognized error code is being used to
  /// specify an error filter.
  ///
  /// Parameters:
  /// String p0: the unrecognized error code
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unrecognizedErrorCode = diag.unrecognizedErrorCode;

  /// An error code indicating that a YAML section is being configured with an
  /// unsupported option where there is just one legal value.
  ///
  /// Parameters:
  /// String p0: the section name
  /// String p1: the unsupported option key
  /// String p2: the legal value
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  unsupportedOptionWithLegalValue = diag.unsupportedOptionWithLegalValue;

  /// An error code indicating that a YAML section is being configured with an
  /// unsupported option and legal options are provided.
  ///
  /// Parameters:
  /// String p0: the section name
  /// String p1: the unsupported option key
  /// String p2: legal values
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  unsupportedOptionWithLegalValues = diag.unsupportedOptionWithLegalValues;

  /// An error code indicating that a plugin is being configured with an
  /// unsupported option and legal options are provided.
  ///
  /// Parameters:
  /// String p0: the plugin name
  /// String p1: the unsupported option key
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  unsupportedOptionWithoutValues = diag.unsupportedOptionWithoutValues;

  /// An error code indicating that an option entry is being configured with an
  /// unsupported value.
  ///
  /// Parameters:
  /// String p0: the option name
  /// Object p1: the unsupported value
  /// String p2: legal values
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String p0,
      required Object p1,
      required String p2,
    })
  >
  unsupportedValue = diag.unsupportedValue;

  /// Do not construct instances of this class.
  AnalysisOptionsWarningCode._() : assert(false);
}
