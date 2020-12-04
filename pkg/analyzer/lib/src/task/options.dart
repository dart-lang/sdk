// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/plugin/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

final _OptionsProcessor _processor = _OptionsProcessor();

List<AnalysisError> analyzeAnalysisOptions(
    Source source, String content, SourceFactory sourceFactory) {
  List<AnalysisError> errors = <AnalysisError>[];
  Source initialSource = source;
  SourceSpan initialIncludeSpan;
  AnalysisOptionsProvider optionsProvider =
      AnalysisOptionsProvider(sourceFactory);

  // Validate the specified options and any included option files
  void validate(Source source, YamlMap options) {
    List<AnalysisError> validationErrors =
        OptionsFileValidator(source).validate(options);
    if (initialIncludeSpan != null && validationErrors.isNotEmpty) {
      for (AnalysisError error in validationErrors) {
        var args = [
          source.fullName,
          error.offset.toString(),
          (error.offset + error.length - 1).toString(),
          error.message,
        ];
        errors.add(AnalysisError(
            initialSource,
            initialIncludeSpan.start.offset,
            initialIncludeSpan.length,
            AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING,
            args));
      }
    } else {
      errors.addAll(validationErrors);
    }

    YamlNode node = getValue(options, AnalyzerOptions.include);
    if (node == null) {
      return;
    }
    SourceSpan span = node.span;
    initialIncludeSpan ??= span;
    String includeUri = span.text;
    Source includedSource = sourceFactory.resolveUri(source, includeUri);
    if (includedSource == null || !includedSource.exists()) {
      errors.add(AnalysisError(
          initialSource,
          initialIncludeSpan.start.offset,
          initialIncludeSpan.length,
          AnalysisOptionsWarningCode.INCLUDE_FILE_NOT_FOUND,
          [includeUri, source.fullName]));
      return;
    }
    try {
      YamlMap options =
          optionsProvider.getOptionsFromString(includedSource.contents.data);
      validate(includedSource, options);
    } on OptionsFormatException catch (e) {
      var args = [
        includedSource.fullName,
        e.span.start.offset.toString(),
        e.span.end.offset.toString(),
        e.message,
      ];
      // Report errors for included option files
      // on the include directive located in the initial options file.
      errors.add(AnalysisError(
          initialSource,
          initialIncludeSpan.start.offset,
          initialIncludeSpan.length,
          AnalysisOptionsErrorCode.INCLUDED_FILE_PARSE_ERROR,
          args));
    }
  }

  try {
    YamlMap options = optionsProvider.getOptionsFromString(content);
    validate(source, options);
  } on OptionsFormatException catch (e) {
    SourceSpan span = e.span;
    errors.add(AnalysisError(source, span.start.offset, span.length,
        AnalysisOptionsErrorCode.PARSE_ERROR, [e.message]));
  }
  return errors;
}

void applyToAnalysisOptions(AnalysisOptionsImpl options, YamlMap optionMap) {
  _processor.applyToAnalysisOptions(options, optionMap);
}

/// `analyzer` analysis options constants.
class AnalyzerOptions {
  static const String analyzer = 'analyzer';
  static const String enableSuperMixins = 'enableSuperMixins';
  static const String enablePreviewDart2 = 'enablePreviewDart2';

  static const String enableExperiment = 'enable-experiment';
  static const String errors = 'errors';
  static const String exclude = 'exclude';
  static const String include = 'include';
  static const String language = 'language';
  static const String optionalChecks = 'optional-checks';
  static const String plugins = 'plugins';
  static const String strong_mode = 'strong-mode';

  // Optional checks options.
  static const String chromeOsManifestChecks = 'chrome-os-manifest-checks';

  // Strong mode options (see AnalysisOptionsImpl for documentation).
  static const String declarationCasts = 'declaration-casts';
  static const String implicitCasts = 'implicit-casts';
  static const String implicitDynamic = 'implicit-dynamic';

  // Language options (see AnalysisOptionsImpl for documentation).
  static const String strictInference = 'strict-inference';
  static const String strictRawTypes = 'strict-raw-types';

  /// Ways to say `ignore`.
  static const List<String> ignoreSynonyms = ['ignore', 'false'];

  /// Valid error `severity`s.
  static final List<String> severities = List.unmodifiable(severityMap.keys);

  /// Ways to say `include`.
  static const List<String> includeSynonyms = ['include', 'true'];

  /// Ways to say `true` or `false`.
  static const List<String> trueOrFalse = ['true', 'false'];

  /// Supported top-level `analyzer` options.
  static const List<String> topLevel = [
    enableExperiment,
    errors,
    exclude,
    language,
    optionalChecks,
    plugins,
    strong_mode,
  ];

  /// Supported `analyzer` strong-mode options.
  static const List<String> strongModeOptions = [
    declarationCasts, // deprecated
    implicitCasts,
    implicitDynamic,
  ];

  /// Supported `analyzer` language options.
  static const List<String> languageOptions = [strictInference, strictRawTypes];

  // Supported 'analyzer' optional checks options.
  static const List<String> optionalChecksOptions = [
    chromeOsManifestChecks,
  ];
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
          OptionalChecksValueValidator()
        ]);
}

/// Convenience class for composing validators.
class CompositeValidator extends OptionsValidator {
  final List<OptionsValidator> validators;

  CompositeValidator(this.validators);

  @override
  void validate(ErrorReporter reporter, YamlMap options) =>
      validators.forEach((v) => v.validate(reporter, options));
}

/// Validates `analyzer` language configuration options.
class EnabledExperimentsValidator extends OptionsValidator {
  ErrorBuilder builder = ErrorBuilder(AnalyzerOptions.languageOptions);
  ErrorBuilder trueOrFalseBuilder = TrueOrFalseValueErrorBuilder();

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = getValue(options, AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var experimentNames =
          getValue(analyzer, AnalyzerOptions.enableExperiment);
      if (experimentNames is YamlList) {
        var flags =
            experimentNames.nodes.map((node) => node.toString()).toList();
        for (var validationResult in validateFlags(flags)) {
          var flagIndex = validationResult.stringIndex;
          var span = experimentNames.nodes[flagIndex].span;
          if (validationResult is UnrecognizedFlag) {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES,
                span,
                [AnalyzerOptions.enableExperiment, flags[flagIndex]]);
          } else {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.INVALID_OPTION,
                span,
                [AnalyzerOptions.enableExperiment, validationResult.message]);
          }
        }
      } else if (experimentNames != null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            experimentNames.span,
            [AnalyzerOptions.enableExperiment]);
      }
    }
  }
}

/// Builds error reports with value proposals.
class ErrorBuilder {
  String proposal;
  AnalysisOptionsWarningCode code;

  /// Create a builder for the given [supportedOptions].
  ErrorBuilder(List<String> supportedOptions) {
    assert(supportedOptions != null);
    if (supportedOptions.isEmpty) {
      code = noProposalCode;
    } else if (supportedOptions.length == 1) {
      proposal = "'${supportedOptions.join()}'";
      code = singularProposalCode;
    } else {
      proposal = StringUtilities.printListOfQuotedNames(supportedOptions);
      code = pluralProposalCode;
    }
  }

  AnalysisOptionsWarningCode get noProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES;

  AnalysisOptionsWarningCode get pluralProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES;

  AnalysisOptionsWarningCode get singularProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE;

  /// Report an unsupported [node] value, defined in the given [scopeName].
  void reportError(ErrorReporter reporter, String scopeName, YamlNode node) {
    if (proposal != null) {
      reporter.reportErrorForSpan(
          code, node.span, [scopeName, node.value, proposal]);
    } else {
      reporter.reportErrorForSpan(code, node.span, [scopeName, node.value]);
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
      StringUtilities.printListOfQuotedNames(legalValues);

  /// Lazily populated set of error codes (hashed for speedy lookup).
  static HashSet<String> _errorCodes;

  /// Legal error code names.
  static Set<String> get errorCodes {
    if (_errorCodes == null) {
      _errorCodes = HashSet<String>();
      // Engine codes.
      _errorCodes.addAll(errorCodeValues.map((ErrorCode code) => code.name));
    }
    return _errorCodes;
  }

  /// Lazily populated set of lint codes.
  Set<String> _lintCodes;

  Set<String> get lintCodes {
    return _lintCodes ??= Set.from(
        Registry.ruleRegistry.rules.map((rule) => rule.name.toUpperCase()));
  }

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = getValue(options, AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var filters = getValue(analyzer, AnalyzerOptions.errors);
      if (filters is YamlMap) {
        String value;
        filters.nodes.forEach((k, v) {
          if (k is YamlScalar) {
            value = toUpperCase(k.value);
            if (!errorCodes.contains(value) && !lintCodes.contains(value)) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE,
                  k.span,
                  [k.value?.toString()]);
            }
          }
          if (v is YamlScalar) {
            value = toLowerCase(v.value);
            if (!legalValues.contains(value)) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsWarningCode
                      .UNSUPPORTED_OPTION_WITH_LEGAL_VALUES,
                  v.span,
                  [
                    AnalyzerOptions.errors,
                    v.value?.toString(),
                    legalValueString
                  ]);
            }
          }
        });
      }
    }
  }
}

/// Validates `analyzer` language configuration options.
class LanguageOptionValidator extends OptionsValidator {
  ErrorBuilder builder = ErrorBuilder(AnalyzerOptions.languageOptions);
  ErrorBuilder trueOrFalseBuilder = TrueOrFalseValueErrorBuilder();

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = getValue(options, AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var language = getValue(analyzer, AnalyzerOptions.language);
      if (language is YamlMap) {
        language.nodes.forEach((k, v) {
          String key, value;
          bool validKey = false;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (AnalyzerOptions.enablePreviewDart2 == key) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsHintCode.PREVIEW_DART_2_SETTING_DEPRECATED,
                  k.span);
            } else if (AnalyzerOptions.enableSuperMixins == key) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsHintCode.SUPER_MIXINS_SETTING_DEPRECATED,
                  k.span);
            } else if (!AnalyzerOptions.languageOptions.contains(key)) {
              builder.reportError(reporter, AnalyzerOptions.language, k);
            } else {
              // If we have a valid key, go on and check the value.
              validKey = true;
            }
          }
          if (validKey && v is YamlScalar) {
            value = toLowerCase(v.value);
            if (!AnalyzerOptions.trueOrFalse.contains(value)) {
              trueOrFalseBuilder.reportError(reporter, key, v);
            }
          }
        });
      } else if (language is YamlScalar && language.value != null) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            language.span,
            [AnalyzerOptions.language]);
      } else if (language is YamlList) {
        reporter.reportErrorForSpan(
            AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT,
            language.span,
            [AnalyzerOptions.language]);
      }
    }
  }
}

/// Validates `linter` top-level options.
/// TODO(pq): move into `linter` package and plugin.
class LinterOptionsValidator extends TopLevelOptionValidator {
  LinterOptionsValidator() : super('linter', const ['rules']);
}

/// Validates `analyzer` optional-checks value configuration options.
class OptionalChecksValueValidator extends OptionsValidator {
  ErrorBuilder builder = ErrorBuilder(AnalyzerOptions.optionalChecksOptions);
  ErrorBuilder trueOrFalseBuilder = TrueOrFalseValueErrorBuilder();

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = getValue(options, AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var v = getValue(analyzer, AnalyzerOptions.optionalChecks);
      if (v is YamlScalar) {
        var value = toLowerCase(v.value);
        if (value != AnalyzerOptions.chromeOsManifestChecks) {
          builder.reportError(
              reporter, AnalyzerOptions.chromeOsManifestChecks, v);
        }
      } else if (v is YamlMap) {
        v.nodes.forEach((k, v) {
          String key, value;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (key != AnalyzerOptions.chromeOsManifestChecks) {
              builder.reportError(
                  reporter, AnalyzerOptions.chromeOsManifestChecks, k);
            } else {
              value = toLowerCase(v.value);
              if (!AnalyzerOptions.trueOrFalse.contains(value)) {
                trueOrFalseBuilder.reportError(reporter, key, v);
              }
            }
          }
        });
      }
    }
  }
}

/// Validates options defined in an analysis options file.
class OptionsFileValidator {
  /// The source being validated.
  final Source source;

  final List<OptionsValidator> _validators = [
    AnalyzerOptionsValidator(),
    LinterOptionsValidator(),
    LinterRuleOptionsValidator()
  ];

  OptionsFileValidator(this.source);

  List<AnalysisError> validate(YamlMap options) {
    RecordingErrorListener recorder = RecordingErrorListener();
    ErrorReporter reporter = ErrorReporter(
      recorder,
      source,
      isNonNullableByDefault: false,
    );
    _validators.forEach((OptionsValidator v) => v.validate(reporter, options));
    return recorder.errors;
  }
}

/// Validates `analyzer` strong-mode value configuration options.
class StrongModeOptionValueValidator extends OptionsValidator {
  ErrorBuilder builder = ErrorBuilder(AnalyzerOptions.strongModeOptions);
  ErrorBuilder trueOrFalseBuilder = TrueOrFalseValueErrorBuilder();

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    var analyzer = getValue(options, AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      var v = getValue(analyzer, AnalyzerOptions.strong_mode);
      if (v is YamlScalar) {
        var value = toLowerCase(v.value);
        if (!AnalyzerOptions.trueOrFalse.contains(value)) {
          trueOrFalseBuilder.reportError(
              reporter, AnalyzerOptions.strong_mode, v);
        } else if (value == 'false') {
          reporter.reportErrorForSpan(
              AnalysisOptionsWarningCode.SPEC_MODE_REMOVED, v.span);
        } else if (value == 'true') {
          reporter.reportErrorForSpan(
              AnalysisOptionsHintCode.STRONG_MODE_SETTING_DEPRECATED, v.span);
        }
      } else if (v is YamlMap) {
        v.nodes.forEach((k, v) {
          String key, value;
          bool validKey = false;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (!AnalyzerOptions.strongModeOptions.contains(key)) {
              builder.reportError(reporter, AnalyzerOptions.strong_mode, k);
            } else if (key == AnalyzerOptions.declarationCasts) {
              reporter.reportErrorForSpan(
                  AnalysisOptionsWarningCode.ANALYSIS_OPTION_DEPRECATED,
                  k.span,
                  [key]);
            } else {
              // If we have a valid key, go on and check the value.
              validKey = true;
            }
          }
          if (validKey && v is YamlScalar) {
            value = toLowerCase(v.value);
            if (!AnalyzerOptions.trueOrFalse.contains(value)) {
              trueOrFalseBuilder.reportError(reporter, key, v);
            }
          }
        });
      }
    }
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
  String _valueProposal;
  AnalysisOptionsWarningCode _warningCode;

  TopLevelOptionValidator(this.pluginName, this.supportedOptions) {
    assert(supportedOptions != null && supportedOptions.isNotEmpty);
    if (supportedOptions.length > 1) {
      _valueProposal = StringUtilities.printListOfQuotedNames(supportedOptions);
      _warningCode =
          AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES;
    } else {
      _valueProposal = "'${supportedOptions.join()}'";
      _warningCode =
          AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE;
    }
  }

  @override
  void validate(ErrorReporter reporter, YamlMap options) {
    YamlNode node = getValue(options, pluginName);
    if (node is YamlMap) {
      node.nodes.forEach((k, v) {
        if (k is YamlScalar) {
          if (!supportedOptions.contains(k.value)) {
            reporter.reportErrorForSpan(
                _warningCode, k.span, [pluginName, k.value, _valueProposal]);
          }
        }
        //TODO(pq): consider an error if the node is not a Scalar.
      });
    }
  }
}

/// An error-builder that knows about `true` and `false` legal values.
class TrueOrFalseValueErrorBuilder extends ErrorBuilder {
  TrueOrFalseValueErrorBuilder() : super(AnalyzerOptions.trueOrFalse);

  @override
  AnalysisOptionsWarningCode get pluralProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_VALUE;
}

class _OptionsProcessor {
  /// Apply the options in the given [optionMap] to the given analysis
  /// [options].
  void applyToAnalysisOptions(AnalysisOptionsImpl options, YamlMap optionMap) {
    if (optionMap == null) {
      return;
    }
    var analyzer = getValue(optionMap, AnalyzerOptions.analyzer);
    if (analyzer is YamlMap) {
      // Process strong mode option.
      var strongMode = getValue(analyzer, AnalyzerOptions.strong_mode);
      _applyStrongOptions(options, strongMode);

      // Process filters.
      var filters = getValue(analyzer, AnalyzerOptions.errors);
      _applyProcessors(options, filters);

      // Process enabled experiments.
      var experimentNames =
          getValue(analyzer, AnalyzerOptions.enableExperiment);
      if (experimentNames is YamlList) {
        List<String> enabledExperiments = <String>[];
        for (var element in experimentNames.nodes) {
          String experimentName = _toString(element);
          if (experimentName != null) {
            enabledExperiments.add(experimentName);
          }
        }
        options.contextFeatures = FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: ExperimentStatus.currentVersion,
          flags: enabledExperiments,
        );
      }

      // Process optional checks options.
      var optionalChecks = getValue(analyzer, AnalyzerOptions.optionalChecks);
      _applyOptionalChecks(options, optionalChecks);

      // Process language options.
      var language = getValue(analyzer, AnalyzerOptions.language);
      _applyLanguageOptions(options, language);

      // Process excludes.
      var excludes = getValue(analyzer, AnalyzerOptions.exclude);
      _applyExcludes(options, excludes);

      // Process plugins.
      var names = getValue(analyzer, AnalyzerOptions.plugins);
      List<String> pluginNames = <String>[];
      String pluginName = _toString(names);
      if (pluginName != null) {
        pluginNames.add(pluginName);
      } else if (names is YamlList) {
        for (var element in names.nodes) {
          String pluginName = _toString(element);
          if (pluginName != null) {
            pluginNames.add(pluginName);
          }
        }
      } else if (names is YamlMap) {
        for (var key in names.nodes.keys) {
          String pluginName = _toString(key);
          if (pluginName != null) {
            pluginNames.add(pluginName);
          }
        }
      }
      options.enabledPluginNames = pluginNames;
    }

    LintConfig config = parseConfig(optionMap);
    if (config != null) {
      Iterable<LintRule> lintRules = Registry.ruleRegistry.enabled(config);
      if (lintRules.isNotEmpty) {
        options.lint = true;
        options.lintRules = lintRules.toList();
      }
    }
  }

  void _applyExcludes(AnalysisOptionsImpl options, YamlNode excludes) {
    if (excludes is YamlList) {
      List<String> excludeList = toStringList(excludes);
      if (excludeList != null) {
        options.excludePatterns = excludeList;
      }
    }
  }

  void _applyLanguageOption(
      AnalysisOptionsImpl options, Object feature, Object value) {
    bool boolValue = toBool(value);
    if (boolValue != null) {
      if (feature == AnalyzerOptions.strictInference) {
        options.strictInference = boolValue;
      }
      if (feature == AnalyzerOptions.strictRawTypes) {
        options.strictRawTypes = boolValue;
      }
    }
  }

  void _applyLanguageOptions(AnalysisOptionsImpl options, YamlNode configs) {
    if (configs is YamlMap) {
      configs.nodes.forEach((key, value) {
        if (key is YamlScalar && value is YamlScalar) {
          String feature = key.value?.toString();
          _applyLanguageOption(options, feature, value.value);
        }
      });
    }
  }

  void _applyOptionalChecks(AnalysisOptionsImpl options, YamlNode config) {
    if (config is YamlMap) {
      config.nodes.forEach((k, v) {
        if (k is YamlScalar && v is YamlScalar) {
          _applyOptionalChecksOption(options, k.value?.toString(), v.value);
        }
      });
    }
    if (config is YamlScalar) {
      if (config.value?.toString() == AnalyzerOptions.chromeOsManifestChecks) {
        options.chromeOsManifestChecks = true;
      }
    }
  }

  void _applyOptionalChecksOption(
      AnalysisOptionsImpl options, String feature, Object value) {
    bool boolValue = toBool(value);
    if (boolValue != null) {
      if (feature == AnalyzerOptions.chromeOsManifestChecks) {
        options.chromeOsManifestChecks = boolValue;
      }
    }
  }

  void _applyProcessors(AnalysisOptionsImpl options, YamlNode codes) {
    ErrorConfig config = ErrorConfig(codes);
    options.errorProcessors = config.processors;
  }

  void _applyStrongModeOption(
      AnalysisOptionsImpl options, String feature, Object value) {
    bool boolValue = toBool(value);
    if (boolValue != null) {
      if (feature == AnalyzerOptions.implicitCasts) {
        options.implicitCasts = boolValue;
      }
      if (feature == AnalyzerOptions.implicitDynamic) {
        options.implicitDynamic = boolValue;
      }
    }
  }

  void _applyStrongOptions(AnalysisOptionsImpl options, YamlNode config) {
    if (config is YamlMap) {
      config.nodes.forEach((k, v) {
        if (k is YamlScalar && v is YamlScalar) {
          _applyStrongModeOption(options, k.value?.toString(), v.value);
        }
      });
    }
  }

  String _toString(YamlNode node) {
    if (node is YamlScalar) {
      var value = node.value;
      if (value is String) {
        return value;
      }
    }
    return null;
  }
}
