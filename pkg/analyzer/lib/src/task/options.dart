// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/apply_options.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/plugin/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

List<AnalysisError> analyzeAnalysisOptions(
  Source source,
  String content,
  SourceFactory sourceFactory,
  String contextRoot,
  VersionConstraint? sdkVersionConstraint, {
  LintRuleProvider? provider,
}) {
  List<AnalysisError> errors = [];
  Source initialSource = source;
  SourceSpan? initialIncludeSpan;
  AnalysisOptionsProvider optionsProvider =
      AnalysisOptionsProvider(sourceFactory);
  String? firstPluginName;
  Map<Source, SourceSpan> includeChain = {};

  // TODO(srawlins): This code is getting quite complex, with multiple local
  // functions, and should be refactored to a class maintaining state, with less
  // variable shadowing.
  void addDirectErrorOrIncludedError(
      List<AnalysisError> validationErrors, Source source,
      {required bool sourceIsOptionsForContextRoot}) {
    if (!sourceIsOptionsForContextRoot) {
      // [source] is an included file, and we should only report errors in
      // [initialSource], noting that the included file has warnings.
      for (AnalysisError error in validationErrors) {
        var args = [
          source.fullName,
          error.offset.toString(),
          (error.offset + error.length - 1).toString(),
          error.message,
        ];
        errors.add(
          AnalysisError.tmp(
            source: initialSource,
            offset: initialIncludeSpan!.start.offset,
            length: initialIncludeSpan!.length,
            errorCode: AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING,
            arguments: args,
          ),
        );
      }
    } else {
      // [source] is the options file for [contextRoot]. Report all errors
      // directly.
      errors.addAll(validationErrors);
    }
  }

  // Validate the specified options and any included option files.
  void validate(Source source, YamlMap options, LintRuleProvider? provider) {
    var sourceIsOptionsForContextRoot = initialIncludeSpan == null;
    var validationErrors = OptionsFileValidator(
      source,
      sdkVersionConstraint: sdkVersionConstraint,
      sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot,
      provider: provider,
    ).validate(options);
    addDirectErrorOrIncludedError(validationErrors, source,
        sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot);

    var includeNode = options.valueAt(AnalyzerOptions.include);
    if (includeNode == null) {
      // Validate the 'plugins' option in [options], understanding that no other
      // options are included.
      addDirectErrorOrIncludedError(
          _validatePluginsOption(source, options: options), source,
          sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot);
      return;
    }
    var includeSpan = includeNode.span;
    initialIncludeSpan ??= includeSpan;
    String includeUri = includeSpan.text;
    var includedSource = sourceFactory.resolveUri(source, includeUri);
    if (includedSource == initialSource) {
      errors.add(
        AnalysisError.tmp(
          source: initialSource,
          offset: initialIncludeSpan!.start.offset,
          length: initialIncludeSpan!.length,
          errorCode: AnalysisOptionsWarningCode.RECURSIVE_INCLUDE_FILE,
          arguments: [includeUri, source.fullName],
        ),
      );
      return;
    }
    if (includedSource == null || !includedSource.exists()) {
      errors.add(
        AnalysisError.tmp(
          source: initialSource,
          offset: initialIncludeSpan!.start.offset,
          length: initialIncludeSpan!.length,
          errorCode: AnalysisOptionsWarningCode.INCLUDE_FILE_NOT_FOUND,
          arguments: [includeUri, source.fullName, contextRoot],
        ),
      );
      return;
    }
    var spanInChain = includeChain[includedSource];
    if (spanInChain != null) {
      errors.add(
        AnalysisError.tmp(
          source: initialSource,
          offset: initialIncludeSpan!.start.offset,
          length: initialIncludeSpan!.length,
          errorCode: AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING,
          arguments: [
            includedSource,
            spanInChain.start.offset,
            spanInChain.length,
            'The file includes itself recursively.',
          ],
        ),
      );
      return;
    }
    includeChain[includedSource] = includeSpan;

    try {
      var includedOptions =
          optionsProvider.getOptionsFromString(includedSource.contents.data);
      validate(includedSource, includedOptions, provider);
      firstPluginName ??= _firstPluginName(includedOptions);
      // Validate the 'plugins' option in [options], taking into account any
      // plugins enabled by [includedOptions].
      addDirectErrorOrIncludedError(
        _validatePluginsOption(source,
            options: options, firstEnabledPluginName: firstPluginName),
        source,
        sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot,
      );
    } on OptionsFormatException catch (e) {
      var args = [
        includedSource.fullName,
        e.span!.start.offset.toString(),
        e.span!.end.offset.toString(),
        e.message,
      ];
      // Report errors for included option files on the `include` directive
      // located in the initial options file.
      errors.add(
        AnalysisError.tmp(
          source: initialSource,
          offset: initialIncludeSpan!.start.offset,
          length: initialIncludeSpan!.length,
          errorCode: AnalysisOptionsErrorCode.INCLUDED_FILE_PARSE_ERROR,
          arguments: args,
        ),
      );
    }
  }

  try {
    YamlMap options = optionsProvider.getOptionsFromString(content);
    validate(source, options, provider);
  } on OptionsFormatException catch (e) {
    SourceSpan span = e.span!;
    errors.add(
      AnalysisError.tmp(
        source: source,
        offset: span.start.offset,
        length: span.length,
        errorCode: AnalysisOptionsErrorCode.PARSE_ERROR,
        arguments: [e.message],
      ),
    );
  }
  return errors;
}

@Deprecated("Use 'applyOptions' made available in "
    "'package:analyzer/src/analysis_options/apply_options.dart'")
void applyToAnalysisOptions(AnalysisOptionsImpl options, YamlMap optionMap) {
  options.applyOptions(optionMap);
}

/// Returns the name of the first plugin, if one is specified in [options],
/// otherwise `null`.
String? _firstPluginName(YamlMap options) {
  var analyzerMap = options.valueAt(AnalyzerOptions.analyzer);
  if (analyzerMap is! YamlMap) {
    return null;
  }
  var plugins = analyzerMap.valueAt(AnalyzerOptions.plugins);
  if (plugins is YamlScalar) {
    return plugins.value as String?;
  } else if (plugins is YamlList) {
    return plugins.first as String?;
  } else if (plugins is YamlMap) {
    return plugins.keys.first as String?;
  } else {
    return null;
  }
}

/// Validates the 'plugins' options in [options], given
/// [firstEnabledPluginName].
List<AnalysisError> _validatePluginsOption(
  Source source, {
  required YamlMap options,
  String? firstEnabledPluginName,
}) {
  RecordingErrorListener recorder = RecordingErrorListener();
  ErrorReporter reporter = ErrorReporter(recorder, source);
  PluginsOptionValidator(firstEnabledPluginName).validate(reporter, options);
  return recorder.errors;
}

/// `analyzer` analysis options constants.
class AnalyzerOptions {
  static const String analyzer = 'analyzer';

  static const String cannotIgnore = 'cannot-ignore';
  static const String codeStyle = 'code-style';
  static const String enableExperiment = 'enable-experiment';
  static const String errors = 'errors';
  static const String exclude = 'exclude';
  static const String formatter = 'formatter';
  static const String include = 'include';
  static const String language = 'language';
  static const String optionalChecks = 'optional-checks';
  static const String plugins = 'plugins';
  static const String strongMode = 'strong-mode';

  // Optional checks options.
  static const String chromeOsManifestChecks = 'chrome-os-manifest-checks';

  // Strong mode options (see AnalysisOptionsImpl for documentation).
  static const String declarationCasts = 'declaration-casts';
  static const String implicitCasts = 'implicit-casts';
  static const String implicitDynamic = 'implicit-dynamic';

  // Language options (see AnalysisOptionsImpl for documentation).
  static const String strictCasts = 'strict-casts';
  static const String strictInference = 'strict-inference';
  static const String strictRawTypes = 'strict-raw-types';

  // Code style options
  static const String format = 'format';

  /// Ways to say `ignore`.
  static const List<String> ignoreSynonyms = ['ignore', 'false'];

  /// Valid error `severity`s.
  static final List<String> severities = List.unmodifiable(severityMap.keys);

  /// Ways to say `include`.
  static const List<String> includeSynonyms = ['include', 'true'];

  // Formatter options.
  static const String pageWidth = 'page_width';

  static const String propagateLinterExceptions = 'propagate-linter-exceptions';

  /// Ways to say `true` or `false`.
  static const List<String> trueOrFalse = ['true', 'false'];

  /// Supported top-level `analyzer` options.
  static const List<String> topLevel = [
    cannotIgnore,
    enableExperiment,
    errors,
    exclude,
    language,
    optionalChecks,
    plugins,
    strongMode,
  ];

  /// Supported `analyzer` strong-mode options.
  static const List<String> strongModeOptions = [
    declarationCasts, // deprecated
    implicitCasts,
    implicitDynamic,
  ];

  /// Supported `analyzer` language options.
  static const List<String> languageOptions = [
    strictCasts,
    strictInference,
    strictRawTypes,
  ];

  /// Supported 'analyzer' optional checks options.
  static const List<String> optionalChecksOptions = [
    chromeOsManifestChecks,
    propagateLinterExceptions,
  ];

  /// Supported 'code-style' options.
  static const List<String> codeStyleOptions = [
    format,
  ];

  /// Proposed values for a `true` or `false` option.
  static String get trueOrFalseProposal =>
      AnalyzerOptions.trueOrFalse.quotedAndCommaSeparatedWithAnd;
}

/// Validates `analyzer` options.
class AnalyzerOptionsValidator extends CompositeValidator {
  AnalyzerOptionsValidator()
      : super([
          TopLevelAnalyzerOptionsValidator(),
          StrongModeOptionValueValidator(),
          ErrorFilterOptionValidator(),
          EnabledExperimentsValidator(),
          LanguageOptionValidator(),
          OptionalChecksValueValidator(),
          CannotIgnoreOptionValidator(),
        ]);
}

/// Validates the `analyzer` `cannot-ignore` option.
///
/// This includes the format of the `cannot-ignore` section, the format of
/// values in the section, and whether each value is a valid string.
class CannotIgnoreOptionValidator extends OptionsValidator {
  /// Lazily populated set of error codes.
  static final Set<String> _errorCodes =
      errorCodeValues.map((ErrorCode code) => code.name).toSet();

  /// The error code names that existed, but were removed.
  /// We don't want to report these, this breaks clients.
  // TODO(scheglov): https://github.com/flutter/flutter/issues/141576
  static const Set<String> _removedErrorCodes = {
    'MISSING_RETURN',
  };

  /// Lazily populated set of lint codes.
  late final Set<String> _lintCodes = Registry.ruleRegistry.rules
      .map((rule) => rule.name.toUpperCase())
      .toSet();

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var unignorableNames = analyzer.valueAt(AnalyzerOptions.cannotIgnore);
      if (unignorableNames is YamlList) {
        var listedNames = <String>{};
        for (var unignorableNameNode in unignorableNames.nodes) {
          var unignorableName = unignorableNameNode.value;
          if (unignorableName is String) {
            if (AnalyzerOptions.severities.contains(unignorableName)) {
              listedNames.add(unignorableName);
              continue;
            }
            var upperCaseName = unignorableName.toUpperCase();
            if (!_errorCodes.contains(upperCaseName) &&
                !_lintCodes.contains(upperCaseName) &&
                !_removedErrorCodes.contains(upperCaseName)) {
              reporter.atSourceSpan(
                unignorableNameNode.span,
                AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE,
                arguments: [unignorableName],
              );
            } else if (listedNames.contains(upperCaseName)) {
              // TODO(srawlins): Create a "duplicate value" code and report it
              // here.
            } else {
              listedNames.add(upperCaseName);
            }
          } else {
            reporter.atSourceSpan(
              unignorableNameNode.span,
              AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
              arguments: [AnalyzerOptions.cannotIgnore],
            );
          }
        }
      } else if (unignorableNames != null) {
        reporter.atSourceSpan(
          unignorableNames.span,
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          arguments: [AnalyzerOptions.cannotIgnore],
        );
      }
    }
  }
}

/// Validates `code-style` options.
class CodeStyleOptionsValidator extends OptionsValidator {
  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var codeStyle = options.valueAt(AnalyzerOptions.codeStyle);
    if (codeStyle is YamlMap) {
      codeStyle.nodeMap.forEach((keyNode, valueNode) {
        var key = keyNode.value;
        if (key == AnalyzerOptions.format) {
          _validateFormat(reporter, valueNode);
        } else {
          reporter.atSourceSpan(
            keyNode.span,
            AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES,
            arguments: [AnalyzerOptions.codeStyle, keyNode.toString()],
          );
        }
      });
    } else if (codeStyle is YamlScalar && codeStyle.value != null) {
      reporter.atSourceSpan(
        codeStyle.span,
        AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
        arguments: [AnalyzerOptions.codeStyle],
      );
    } else if (codeStyle is YamlList) {
      reporter.atSourceSpan(
        codeStyle.span,
        AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
        arguments: [AnalyzerOptions.codeStyle],
      );
    }
  }

  void _validateFormat(ErrorReporter reporter, YamlNode format) {
    if (format is YamlMap) {
      reporter.atSourceSpan(
        format.span,
        AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
        arguments: [AnalyzerOptions.format],
      );
    } else if (format is YamlScalar) {
      var formatValue = toBool(format.valueOrThrow);
      if (formatValue == null) {
        reporter.atSourceSpan(
          format.span,
          AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
          arguments: [
            AnalyzerOptions.format,
            format.valueOrThrow,
            AnalyzerOptions.trueOrFalseProposal
          ],
        );
      }
    } else if (format is YamlList) {
      reporter.atSourceSpan(
        format.span,
        AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
        arguments: [AnalyzerOptions.format],
      );
    }
  }
}

/// Convenience class for composing validators.
class CompositeValidator extends OptionsValidator {
  final List<OptionsValidator> validators;

  CompositeValidator(this.validators);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    for (var validator in validators) {
      validator.validate(reporter, options);
    }
  }
}

/// Validates `analyzer` language configuration options.
class EnabledExperimentsValidator extends OptionsValidator {
  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var experimentNames = analyzer.valueAt(AnalyzerOptions.enableExperiment);
      if (experimentNames is YamlList) {
        var flags =
            experimentNames.nodes.map((node) => node.toString()).toList();
        for (var validationResult in validateFlags(flags)) {
          var flagIndex = validationResult.stringIndex;
          var span = experimentNames.nodes[flagIndex].span;
          if (validationResult is UnrecognizedFlag) {
            reporter.atSourceSpan(
              span,
              AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES,
              arguments: [AnalyzerOptions.enableExperiment, flags[flagIndex]],
            );
          } else {
            reporter.atSourceSpan(
              span,
              AnalysisOptionsWarningCode.INVALID_OPTION,
              arguments: [
                AnalyzerOptions.enableExperiment,
                validationResult.message
              ],
            );
          }
        }
      } else if (experimentNames != null) {
        reporter.atSourceSpan(
          experimentNames.span,
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          arguments: [AnalyzerOptions.enableExperiment],
        );
      }
    }
  }
}

/// Builds error reports with value proposals.
class ErrorBuilder {
  static AnalysisOptionsWarningCode get noProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES;

  static AnalysisOptionsWarningCode get pluralProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES;

  static AnalysisOptionsWarningCode get singularProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE;

  final String proposal;

  final AnalysisOptionsWarningCode code;

  /// Create a builder for the given [supportedOptions].
  factory ErrorBuilder(List<String> supportedOptions) {
    var proposal = supportedOptions.quotedAndCommaSeparatedWithAnd;
    if (supportedOptions.isEmpty) {
      return ErrorBuilder._(proposal: proposal, code: noProposalCode);
    } else if (supportedOptions.length == 1) {
      return ErrorBuilder._(proposal: proposal, code: singularProposalCode);
    } else {
      return ErrorBuilder._(proposal: proposal, code: pluralProposalCode);
    }
  }

  ErrorBuilder._({
    required this.proposal,
    required this.code,
  });

  /// Report an unsupported [node] value, defined in the given [scopeName].
  void reportError(ErrorReporter reporter, String scopeName, YamlNode node) {
    if (proposal.isNotEmpty) {
      reporter.atSourceSpan(
        node.span,
        code,
        arguments: [scopeName, node.valueOrThrow, proposal],
      );
    } else {
      reporter.atSourceSpan(
        node.span,
        code,
        arguments: [scopeName, node.valueOrThrow],
      );
    }
  }
}

/// Validates `analyzer` error filter options.
class ErrorFilterOptionValidator extends OptionsValidator {
  /// Legal values.
  static final List<String> legalValues =
      List.from(AnalyzerOptions.ignoreSynonyms)
        ..addAll(AnalyzerOptions.includeSynonyms)
        ..addAll(AnalyzerOptions.severities);

  /// Pretty String listing legal values.
  static final String legalValueString =
      legalValues.quotedAndCommaSeparatedWithAnd;

  /// Lazily populated set of error codes.
  static final Set<String> _errorCodes =
      errorCodeValues.map((ErrorCode code) => code.name).toSet();

  /// The error code names that existed, but were removed.
  /// We don't want to report these, this breaks clients.
  // TODO(scheglov): https://github.com/flutter/flutter/issues/141576
  static const Set<String> _removedErrorCodes = {
    'MISSING_RETURN',
  };

  /// Lazily populated set of lint codes.
  late final Set<String> _lintCodes = Registry.ruleRegistry.rules
      .map((rule) => rule.name.toUpperCase())
      .toSet();

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var filters = analyzer.valueAt(AnalyzerOptions.errors);
      if (filters is YamlMap) {
        filters.nodes.forEach((k, v) {
          String? value;
          if (k is YamlScalar) {
            value = toUpperCase(k.value);
            if (!_errorCodes.contains(value) &&
                !_lintCodes.contains(value) &&
                !_removedErrorCodes.contains(value)) {
              reporter.atSourceSpan(
                k.span,
                AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE,
                arguments: [k.value.toString()],
              );
            }
          }
          if (v is YamlScalar) {
            value = toLowerCase(v.value);
            if (!legalValues.contains(value)) {
              reporter.atSourceSpan(
                v.span,
                AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES,
                arguments: [
                  AnalyzerOptions.errors,
                  v.value.toString(),
                  legalValueString
                ],
              );
            }
          } else {
            reporter.atSourceSpan(
              v.span,
              AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
              arguments: [AnalyzerOptions.enableExperiment],
            );
          }
        });
      } else if (filters != null) {
        reporter.atSourceSpan(
          filters.span,
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          arguments: [AnalyzerOptions.enableExperiment],
        );
      }
    }
  }
}

/// Validates `formatter` options.
class FormatterOptionsValidator extends OptionsValidator {
  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var formatter = options.valueAt(AnalyzerOptions.formatter);
    if (formatter is YamlMap) {
      for (var MapEntry(key: keyNode, value: valueNode)
          in formatter.nodeMap.entries) {
        if (keyNode.value == AnalyzerOptions.pageWidth) {
          _validatePageWidth(keyNode, valueNode, reporter);
        } else {
          reporter.atSourceSpan(
            keyNode.span,
            AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES,
            arguments: [
              AnalyzerOptions.formatter,
              keyNode.toString(),
            ],
          );
        }
      }
    } else if (formatter != null && formatter.value != null) {
      reporter.atSourceSpan(
        formatter.span,
        AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
        arguments: [AnalyzerOptions.formatter],
      );
    }
  }

  void _validatePageWidth(
      YamlNode keyNode, YamlNode valueNode, ErrorReporter reporter) {
    var value = valueNode.value;
    if (value is! int || value <= 0) {
      reporter.atSourceSpan(
        valueNode.span,
        AnalysisOptionsWarningCode.INVALID_OPTION,
        arguments: [
          keyNode.toString(),
          '"page_width" must be a positive integer.',
        ],
      );
    }
  }
}

/// Validates `analyzer` language configuration options.
class LanguageOptionValidator extends OptionsValidator {
  final ErrorBuilder _builder = ErrorBuilder(AnalyzerOptions.languageOptions);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var language = analyzer.valueAt(AnalyzerOptions.language);
      if (language is YamlMap) {
        language.nodes.forEach((k, v) {
          String? key, value;
          bool validKey = false;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (!AnalyzerOptions.languageOptions.contains(key)) {
              _builder.reportError(reporter, AnalyzerOptions.language, k);
            } else {
              // If we have a valid key, go on and check the value.
              validKey = true;
            }
          }
          if (validKey && v is YamlScalar) {
            value = toLowerCase(v.value);
            // `null` is not a valid key, so we can safely assume `key` is
            // non-`null`.
            if (!AnalyzerOptions.trueOrFalse.contains(value)) {
              reporter.atSourceSpan(
                v.span,
                AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
                arguments: [
                  key!,
                  v.valueOrThrow,
                  AnalyzerOptions.trueOrFalseProposal
                ],
              );
            }
          }
        });
      } else if (language is YamlScalar && language.value != null) {
        reporter.atSourceSpan(
          language.span,
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          arguments: [AnalyzerOptions.language],
        );
      } else if (language is YamlList) {
        reporter.atSourceSpan(
          language.span,
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          arguments: [AnalyzerOptions.language],
        );
      }
    }
  }
}

/// Validates `linter` top-level options.
// TODO(pq): move into `linter` package and plugin.
class LinterOptionsValidator extends TopLevelOptionValidator {
  LinterOptionsValidator() : super('linter', const ['rules']);
}

/// Validates `analyzer` optional-checks value configuration options.
class OptionalChecksValueValidator extends OptionsValidator {
  final ErrorBuilder _builder =
      ErrorBuilder(AnalyzerOptions.optionalChecksOptions);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var v = analyzer.valueAt(AnalyzerOptions.optionalChecks);
      if (v is YamlScalar) {
        var value = toLowerCase(v.value);
        if (value != AnalyzerOptions.chromeOsManifestChecks) {
          _builder.reportError(
              reporter, AnalyzerOptions.chromeOsManifestChecks, v);
        }
      } else if (v is YamlMap) {
        v.nodes.forEach((k, v) {
          String? key, value;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (key != AnalyzerOptions.chromeOsManifestChecks) {
              _builder.reportError(
                  reporter, AnalyzerOptions.chromeOsManifestChecks, k);
            } else {
              value = toLowerCase(v.value);
              if (!AnalyzerOptions.trueOrFalse.contains(value)) {
                reporter.atSourceSpan(
                  v.span,
                  AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
                  arguments: [
                    key!,
                    v.valueOrThrow,
                    AnalyzerOptions.trueOrFalseProposal
                  ],
                );
              }
            }
          }
        });
      } else if (v != null) {
        reporter.atSourceSpan(
          v.span,
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          arguments: [AnalyzerOptions.enableExperiment],
        );
      }
    }
  }
}

/// Validates options defined in an analysis options file.
class OptionsFileValidator {
  /// The source being validated.
  final Source source;

  final List<OptionsValidator> _validators;

  OptionsFileValidator(
    this.source, {
    required VersionConstraint? sdkVersionConstraint,
    required bool sourceIsOptionsForContextRoot,
    LintRuleProvider? provider,
  }) : _validators = [
          AnalyzerOptionsValidator(),
          CodeStyleOptionsValidator(),
          FormatterOptionsValidator(),
          LinterOptionsValidator(),
          LinterRuleOptionsValidator(
            provider: provider,
            sdkVersionConstraint: sdkVersionConstraint,
            sourceIsOptionsForContextRoot: sourceIsOptionsForContextRoot,
          ),
        ];

  List<AnalysisError> validate(YamlMap options) {
    RecordingErrorListener recorder = RecordingErrorListener();
    ErrorReporter reporter = ErrorReporter(recorder, source);
    for (var validator in _validators) {
      validator.validate(reporter, options);
    }
    return recorder.errors;
  }
}

/// Validates `analyzer` plugins configuration options.
class PluginsOptionValidator extends OptionsValidator {
  /// The name of the first included plugin, if there is one.
  ///
  /// If there are no included plugins, this is `null`.
  final String? _firstIncludedPluginName;

  PluginsOptionValidator(this._firstIncludedPluginName);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is! YamlMap) {
      return;
    }
    var plugins = analyzer.valueAt(AnalyzerOptions.plugins);
    if (plugins is YamlScalar && plugins.value != null) {
      if (_firstIncludedPluginName != null &&
          _firstIncludedPluginName != plugins.value) {
        reporter.atSourceSpan(
          plugins.span,
          AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
          arguments: [_firstIncludedPluginName],
        );
      }
    } else if (plugins is YamlList) {
      var pluginValues = plugins.nodes.whereType<YamlNode>().toList();
      if (_firstIncludedPluginName != null) {
        // There is already at least one plugin specified in included options.
        for (var plugin in pluginValues) {
          if (plugin.value != _firstIncludedPluginName) {
            reporter.atSourceSpan(
              plugin.span,
              AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
              arguments: [_firstIncludedPluginName],
            );
          }
        }
      } else if (plugins.length > 1) {
        String? firstPlugin;
        for (var plugin in pluginValues) {
          if (firstPlugin == null) {
            var pluginValue = plugin.value;
            if (pluginValue is String) {
              firstPlugin = pluginValue;
              continue;
            } else {
              // This plugin is bad and should not be marked as the first one.
              continue;
            }
          } else if (plugin.value != firstPlugin) {
            reporter.atSourceSpan(
              plugin.span,
              AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
              arguments: [firstPlugin],
            );
          }
        }
      }
    } else if (plugins is YamlMap) {
      var pluginValues = plugins.nodes.keys.cast<YamlNode?>();
      if (_firstIncludedPluginName != null) {
        // There is already at least one plugin specified in included options.
        for (var plugin in pluginValues) {
          if (plugin != null && plugin.value != _firstIncludedPluginName) {
            reporter.atSourceSpan(
              plugin.span,
              AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
              arguments: [_firstIncludedPluginName],
            );
          }
        }
      } else if (plugins.length > 1) {
        String? firstPlugin;
        for (var plugin in pluginValues) {
          if (firstPlugin == null) {
            var pluginValue = plugin?.value;
            if (pluginValue is String) {
              firstPlugin = pluginValue;
              continue;
            } else {
              // This plugin is bad and should not be marked as the first one.
              continue;
            }
          } else if (plugin != null && plugin.value != firstPlugin) {
            reporter.atSourceSpan(
              plugin.span,
              AnalysisOptionsWarningCode.MULTIPLE_PLUGINS,
              arguments: [firstPlugin],
            );
          }
        }
      }
    }
  }
}

/// Validates `analyzer` strong-mode value configuration options.
class StrongModeOptionValueValidator extends OptionsValidator {
  final ErrorBuilder _builder = ErrorBuilder(AnalyzerOptions.strongModeOptions);

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = options.valueAt(AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var strongModeNode = analyzer.valueAt(AnalyzerOptions.strongMode);
      if (strongModeNode is YamlMap) {
        return _validateStrongModeAsMap(reporter, strongModeNode);
      } else if (strongModeNode != null) {
        reporter.atSourceSpan(
          strongModeNode.span,
          AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
          arguments: [AnalyzerOptions.strongMode],
        );
      }
    }
  }

  void _validateStrongModeAsMap(
      ErrorReporter reporter, YamlMap strongModeNode) {
    strongModeNode.nodes.forEach((k, v) {
      if (k is YamlScalar) {
        var key = k.value?.toString();
        if (!AnalyzerOptions.strongModeOptions.contains(key)) {
          _builder.reportError(reporter, AnalyzerOptions.strongMode, k);
        } else if (key == AnalyzerOptions.declarationCasts) {
          reporter.atSourceSpan(
            v.span,
            AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
            arguments: [
              AnalyzerOptions.strongMode,
              v.valueOrThrow,
              AnalyzerOptions.trueOrFalseProposal
            ],
          );
        } else {
          // The key is valid.
          if (v is YamlScalar) {
            var value = toLowerCase(v.value);
            if (!AnalyzerOptions.trueOrFalse.contains(value)) {
              reporter.atSourceSpan(
                v.span,
                AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
                arguments: [
                  key!,
                  v.valueOrThrow,
                  AnalyzerOptions.trueOrFalseProposal
                ],
              );
            }
          }
        }
      }
    });
  }
}

/// Validates `analyzer` top-level options.
class TopLevelAnalyzerOptionsValidator extends TopLevelOptionValidator {
  TopLevelAnalyzerOptionsValidator()
      : super(AnalyzerOptions.analyzer, AnalyzerOptions.topLevel);
}

/// Validates top-level options. For example,
///     plugin:
///       top-level-option: true
class TopLevelOptionValidator extends OptionsValidator {
  final String pluginName;
  final List<String> supportedOptions;
  final String _valueProposal;
  final AnalysisOptionsWarningCode _warningCode;

  TopLevelOptionValidator(this.pluginName, this.supportedOptions)
      : assert(supportedOptions.isNotEmpty),
        _valueProposal = supportedOptions.quotedAndCommaSeparatedWithAnd,
        _warningCode = supportedOptions.length == 1
            ? AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE
            : AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES;

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var node = options.valueAt(pluginName);
    if (node is YamlMap) {
      node.nodes.forEach((k, v) {
        if (k is YamlScalar) {
          if (!supportedOptions.contains(k.value)) {
            reporter.atSourceSpan(
              k.span,
              _warningCode,
              arguments: [pluginName, k.valueOrThrow, _valueProposal],
            );
          }
        }
        // TODO(pq): consider an error if the node is not a Scalar.
      });
    }
    // TODO(srawlins): Report non-Map with
    //  AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT.
  }
}
