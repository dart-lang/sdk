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

class AnalysisOptionsErrorCode extends DiagnosticCodeWithExpectedTypes {
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
  static const AnalysisOptionsErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  includedFileParseError = AnalysisOptionsErrorTemplate(
    'INCLUDED_FILE_PARSE_ERROR',
    "{3} in {0}({1}..{2})",
    withArguments: _withArgumentsIncludedFileParseError,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// An error code indicating that there is a syntactic error in the file.
  ///
  /// Parameters:
  /// Object p0: the error message from the parse error
  static const AnalysisOptionsErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  parseError = AnalysisOptionsErrorTemplate(
    'PARSE_ERROR',
    "{0}",
    withArguments: _withArgumentsParseError,
    expectedTypes: [ExpectedType.object],
  );

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsErrorCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required super.expectedTypes,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'AnalysisOptionsErrorCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.ERROR;

  @override
  DiagnosticType get type => DiagnosticType.COMPILE_TIME_ERROR;

  static LocatableDiagnostic _withArgumentsIncludedFileParseError({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(includedFileParseError, [p0, p1, p2, p3]);
  }

  static LocatableDiagnostic _withArgumentsParseError({required Object p0}) {
    return LocatableDiagnosticImpl(parseError, [p0]);
  }
}

final class AnalysisOptionsErrorTemplate<T extends Function>
    extends AnalysisOptionsErrorCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsErrorTemplate(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class AnalysisOptionsErrorWithoutArguments
    extends AnalysisOptionsErrorCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsErrorWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}

class AnalysisOptionsWarningCode extends DiagnosticCodeWithExpectedTypes {
  /// An error code indicating that the given option is deprecated.
  ///
  /// Parameters:
  /// Object p0: the option name
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  analysisOptionDeprecated = AnalysisOptionsWarningTemplate(
    'ANALYSIS_OPTION_DEPRECATED',
    "The option '{0}' is no longer supported.",
    withArguments: _withArgumentsAnalysisOptionDeprecated,
    expectedTypes: [ExpectedType.object],
  );

  /// An error code indicating that the given option is deprecated.
  ///
  /// Parameters:
  /// Object p0: the option name
  /// Object p1: the replacement option name
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  analysisOptionDeprecatedWithReplacement = AnalysisOptionsWarningTemplate(
    'ANALYSIS_OPTION_DEPRECATED',
    "The option '{0}' is no longer supported.",
    correctionMessage: "Try using the new '{1}' option.",
    uniqueName: 'ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT',
    withArguments: _withArgumentsAnalysisOptionDeprecatedWithReplacement,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// A hint code indicating reference to a deprecated lint.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedLint = AnalysisOptionsWarningTemplate(
    'DEPRECATED_LINT',
    "'{0}' is a deprecated lint rule and should not be used.",
    correctionMessage: "Try removing '{0}'.",
    withArguments: _withArgumentsDeprecatedLint,
    expectedTypes: [ExpectedType.string],
  );

  /// A hint code indicating reference to a deprecated lint.
  ///
  /// Parameters:
  /// String p0: the deprecated lint name
  /// String p1: the replacing rule name
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  deprecatedLintWithReplacement = AnalysisOptionsWarningTemplate(
    'DEPRECATED_LINT_WITH_REPLACEMENT',
    "'{0}' is deprecated and should be replaced by '{1}'.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    withArguments: _withArgumentsDeprecatedLintWithReplacement,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Duplicate rules.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateRule = AnalysisOptionsWarningTemplate(
    'DUPLICATE_RULE',
    "The rule {0} is already specified and doesn't need to be specified again.",
    correctionMessage: "Try removing all but one specification of the rule.",
    withArguments: _withArgumentsDuplicateRule,
    expectedTypes: [ExpectedType.string],
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
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  includedFileWarning = AnalysisOptionsWarningTemplate(
    'INCLUDED_FILE_WARNING',
    "Warning in the included options file {0}({1}..{2}): {3}",
    withArguments: _withArgumentsIncludedFileWarning,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// An error code indicating a specified include file could not be found.
  ///
  /// Parameters:
  /// Object p0: the URI of the file to be included
  /// Object p1: the path of the file containing the include directive
  /// Object p2: the path of the context being analyzed
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  includeFileNotFound = AnalysisOptionsWarningTemplate(
    'INCLUDE_FILE_NOT_FOUND',
    "The include file '{0}' in '{1}' can't be found when analyzing '{2}'.",
    withArguments: _withArgumentsIncludeFileNotFound,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// An error code indicating an incompatible rule.
  ///
  /// The incompatible rules must be included by context messages.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the incompatible rules
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  incompatibleLint = AnalysisOptionsWarningTemplate(
    'INCOMPATIBLE_LINT',
    "The rule '{0}' is incompatible with {1}.",
    correctionMessage: "Try removing all but one of the incompatible rules.",
    withArguments: _withArgumentsIncompatibleLint,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// An error code indicating an incompatible rule.
  ///
  /// The files that enable the referenced rules must be included by context messages.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the incompatible rules
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  incompatibleLintFiles = AnalysisOptionsWarningTemplate(
    'INCOMPATIBLE_LINT',
    "The rule '{0}' is incompatible with {1}.",
    correctionMessage:
        "Try locally disabling all but one of the conflicting rules or "
        "removing one of the incompatible files.",
    uniqueName: 'INCOMPATIBLE_LINT_FILES',
    withArguments: _withArgumentsIncompatibleLintFiles,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// An error code indicating an incompatible rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the incompatible rules
  /// int p2: the number of files that include the incompatible rule
  /// String p3: plural suffix for the word "file"
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required int p2,
      required String p3,
    })
  >
  incompatibleLintIncluded = AnalysisOptionsWarningTemplate(
    'INCOMPATIBLE_LINT',
    "The rule '{0}' is incompatible with {1}, which is included from {2} "
        "file{3}.",
    correctionMessage:
        "Try locally disabling all but one of the conflicting rules or "
        "removing one of the incompatible files.",
    uniqueName: 'INCOMPATIBLE_LINT_INCLUDED',
    withArguments: _withArgumentsIncompatibleLintIncluded,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.int,
      ExpectedType.string,
    ],
  );

  /// An error code indicating that a plugin is being configured with an invalid
  /// value for an option and a detail message is provided.
  ///
  /// Parameters:
  /// String p0: the option name
  /// String p1: the detail message
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidOption = AnalysisOptionsWarningTemplate(
    'INVALID_OPTION',
    "Invalid option specified for '{0}': {1}",
    withArguments: _withArgumentsInvalidOption,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// An error code indicating an invalid format for an options file section.
  ///
  /// Parameters:
  /// String p0: the section name
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidSectionFormat = AnalysisOptionsWarningTemplate(
    'INVALID_SECTION_FORMAT',
    "Invalid format for the '{0}' section.",
    withArguments: _withArgumentsInvalidSectionFormat,
    expectedTypes: [ExpectedType.string],
  );

  /// An error code indicating multiple plugins have been specified as enabled.
  ///
  /// Parameters:
  /// String p0: the name of the first plugin
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  multiplePlugins = AnalysisOptionsWarningTemplate(
    'MULTIPLE_PLUGINS',
    "Multiple plugins can't be enabled.",
    correctionMessage: "Remove all plugins following the first, '{0}'.",
    withArguments: _withArgumentsMultiplePlugins,
    expectedTypes: [ExpectedType.string],
  );

  /// An error code indicating plugins have been specified in an "inner"
  /// analysis options file.
  ///
  /// Parameters:
  /// String contextRoot: the root of the analysis context
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String contextRoot})
  >
  pluginsInInnerOptions = AnalysisOptionsWarningTemplate(
    'PLUGINS_IN_INNER_OPTIONS',
    "Plugins can only be specified in the root of a pub workspace or the root "
        "of a package that isn't in a workspace.",
    correctionMessage:
        "Try specifying plugins in an analysis options file at '{0}'.",
    withArguments: _withArgumentsPluginsInInnerOptions,
    expectedTypes: [ExpectedType.string],
  );

  /// An error code indicating a specified include file includes itself recursively.
  ///
  /// Parameters:
  /// Object p0: the URI of the file to be included
  /// Object p1: the path of the file containing the include directive
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  recursiveIncludeFile = AnalysisOptionsWarningTemplate(
    'RECURSIVE_INCLUDE_FILE',
    "The include file '{0}' in '{1}' includes itself recursively.",
    correctionMessage:
        "Try changing the chain of 'include's to not re-include this file.",
    withArguments: _withArgumentsRecursiveIncludeFile,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// An error code indicating a removed lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the SDK version in which the lint was removed
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  removedLint = AnalysisOptionsWarningTemplate(
    'REMOVED_LINT',
    "'{0}' was removed in Dart '{1}'",
    correctionMessage: "Remove the reference to '{0}'.",
    withArguments: _withArgumentsRemovedLint,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// An error code indicating a removed lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  /// String p1: the SDK version in which the lint was removed
  /// String p2: the name of a replacing lint
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  replacedLint = AnalysisOptionsWarningTemplate(
    'REPLACED_LINT',
    "'{0}' was replaced by '{2}' in Dart '{1}'.",
    correctionMessage: "Replace '{0}' with '{1}'.",
    withArguments: _withArgumentsReplacedLint,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// An error code indicating an undefined lint rule.
  ///
  /// Parameters:
  /// String p0: the rule name
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedLint = AnalysisOptionsWarningTemplate(
    'UNDEFINED_LINT',
    "'{0}' is not a recognized lint rule.",
    correctionMessage: "Try using the name of a recognized lint rule.",
    withArguments: _withArgumentsUndefinedLint,
    expectedTypes: [ExpectedType.string],
  );

  /// An error code indicating that an unrecognized error code is being used to
  /// specify an error filter.
  ///
  /// Parameters:
  /// String p0: the unrecognized error code
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unrecognizedErrorCode = AnalysisOptionsWarningTemplate(
    'UNRECOGNIZED_ERROR_CODE',
    "'{0}' isn't a recognized error code.",
    withArguments: _withArgumentsUnrecognizedErrorCode,
    expectedTypes: [ExpectedType.string],
  );

  /// An error code indicating that a YAML section is being configured with an
  /// unsupported option where there is just one legal value.
  ///
  /// Parameters:
  /// String p0: the section name
  /// String p1: the unsupported option key
  /// String p2: the legal value
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  unsupportedOptionWithLegalValue = AnalysisOptionsWarningTemplate(
    'UNSUPPORTED_OPTION_WITH_LEGAL_VALUE',
    "The option '{1}' isn't supported by '{0}'. Try using the only supported "
        "option: '{2}'.",
    withArguments: _withArgumentsUnsupportedOptionWithLegalValue,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// An error code indicating that a YAML section is being configured with an
  /// unsupported option and legal options are provided.
  ///
  /// Parameters:
  /// String p0: the section name
  /// String p1: the unsupported option key
  /// String p2: legal values
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  unsupportedOptionWithLegalValues = AnalysisOptionsWarningTemplate(
    'UNSUPPORTED_OPTION_WITH_LEGAL_VALUES',
    "The option '{1}' isn't supported by '{0}'.",
    correctionMessage: "Try using one of the supported options: {2}.",
    withArguments: _withArgumentsUnsupportedOptionWithLegalValues,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// An error code indicating that a plugin is being configured with an
  /// unsupported option and legal options are provided.
  ///
  /// Parameters:
  /// String p0: the plugin name
  /// String p1: the unsupported option key
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  unsupportedOptionWithoutValues = AnalysisOptionsWarningTemplate(
    'UNSUPPORTED_OPTION_WITHOUT_VALUES',
    "The option '{1}' isn't supported by '{0}'.",
    withArguments: _withArgumentsUnsupportedOptionWithoutValues,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// An error code indicating that an option entry is being configured with an
  /// unsupported value.
  ///
  /// Parameters:
  /// String p0: the option name
  /// Object p1: the unsupported value
  /// String p2: legal values
  static const AnalysisOptionsWarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required Object p1,
      required String p2,
    })
  >
  unsupportedValue = AnalysisOptionsWarningTemplate(
    'UNSUPPORTED_VALUE',
    "The value '{1}' isn't supported by '{0}'.",
    correctionMessage: "Try using one of the supported options: {2}.",
    withArguments: _withArgumentsUnsupportedValue,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.object,
      ExpectedType.string,
    ],
  );

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsWarningCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required super.expectedTypes,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'AnalysisOptionsWarningCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.WARNING;

  @override
  DiagnosticType get type => DiagnosticType.STATIC_WARNING;

  static LocatableDiagnostic _withArgumentsAnalysisOptionDeprecated({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(analysisOptionDeprecated, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsAnalysisOptionDeprecatedWithReplacement({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(analysisOptionDeprecatedWithReplacement, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedLint({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(deprecatedLint, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedLintWithReplacement({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(deprecatedLintWithReplacement, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateRule({required String p0}) {
    return LocatableDiagnosticImpl(duplicateRule, [p0]);
  }

  static LocatableDiagnostic _withArgumentsIncludedFileWarning({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(includedFileWarning, [p0, p1, p2, p3]);
  }

  static LocatableDiagnostic _withArgumentsIncludeFileNotFound({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(includeFileNotFound, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsIncompatibleLint({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(incompatibleLint, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsIncompatibleLintFiles({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(incompatibleLintFiles, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsIncompatibleLintIncluded({
    required String p0,
    required String p1,
    required int p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(incompatibleLintIncluded, [p0, p1, p2, p3]);
  }

  static LocatableDiagnostic _withArgumentsInvalidOption({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(invalidOption, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidSectionFormat({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidSectionFormat, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMultiplePlugins({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(multiplePlugins, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPluginsInInnerOptions({
    required String contextRoot,
  }) {
    return LocatableDiagnosticImpl(pluginsInInnerOptions, [contextRoot]);
  }

  static LocatableDiagnostic _withArgumentsRecursiveIncludeFile({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(recursiveIncludeFile, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsRemovedLint({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(removedLint, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsReplacedLint({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(replacedLint, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedLint({required String p0}) {
    return LocatableDiagnosticImpl(undefinedLint, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnrecognizedErrorCode({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(unrecognizedErrorCode, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedOptionWithLegalValue({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(unsupportedOptionWithLegalValue, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedOptionWithLegalValues({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(unsupportedOptionWithLegalValues, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedOptionWithoutValues({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(unsupportedOptionWithoutValues, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedValue({
    required String p0,
    required Object p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(unsupportedValue, [p0, p1, p2]);
  }
}

final class AnalysisOptionsWarningTemplate<T extends Function>
    extends AnalysisOptionsWarningCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsWarningTemplate(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class AnalysisOptionsWarningWithoutArguments
    extends AnalysisOptionsWarningCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const AnalysisOptionsWarningWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
