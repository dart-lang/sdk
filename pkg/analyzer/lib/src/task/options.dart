// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.options;

import 'dart:collection';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// The errors produced while parsing an analysis options file.
///
/// The list will be empty if there were no errors, but will not be `null`.
final ListResultDescriptor<AnalysisError> ANALYSIS_OPTIONS_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'ANALYSIS_OPTIONS_ERRORS', AnalysisError.NO_ERRORS);

final _OptionsProcessor _processor = new _OptionsProcessor();

void applyToAnalysisOptions(
    AnalysisOptionsImpl options, Map<String, Object> optionMap) {
  _processor.applyToAnalysisOptions(options, optionMap);
}

/// `analyzer` analysis options constants.
class AnalyzerOptions {
  static const String analyzer = 'analyzer';
  static const String enableAsync = 'enableAsync';
  static const String enableGenericMethods = 'enableGenericMethods';
  static const String enableInitializingFormalAccess =
      'enableInitializingFormalAccess';
  static const String enableStrictCallChecks = 'enableStrictCallChecks';
  static const String enableSuperMixins = 'enableSuperMixins';
  static const String enablePreviewDart2 = 'enablePreviewDart2';

  static const String errors = 'errors';
  static const String exclude = 'exclude';
  static const String include = 'include';
  static const String language = 'language';
  static const String plugins = 'plugins';
  static const String strong_mode = 'strong-mode';

  // Strong mode options, see AnalysisOptionsImpl for documentation.
  static const String declarationCasts = 'declaration-casts';
  static const String implicitCasts = 'implicit-casts';
  static const String implicitDynamic = 'implicit-dynamic';

  /// Ways to say `ignore`.
  static const List<String> ignoreSynonyms = const ['ignore', 'false'];

  /// Valid error `severity`s.
  static final List<String> severities =
      new List.unmodifiable(severityMap.keys);

  /// Ways to say `include`.
  static const List<String> includeSynonyms = const ['include', 'true'];

  /// Ways to say `true` or `false`.
  static const List<String> trueOrFalse = const ['true', 'false'];

  /// Supported top-level `analyzer` options.
  static const List<String> topLevel = const [
    errors,
    exclude,
    language,
    plugins,
    strong_mode
  ];

  /// Supported `analyzer` language configuration options.
  static const List<String> languageOptions = const [
    enableAsync,
    enableGenericMethods,
    enableStrictCallChecks,
    enableSuperMixins,
    enablePreviewDart2
  ];
}

/// Validates `analyzer` options.
class AnalyzerOptionsValidator extends CompositeValidator {
  AnalyzerOptionsValidator()
      : super([
          new TopLevelAnalyzerOptionsValidator(),
          new StrongModeOptionValueValidator(),
          new ErrorFilterOptionValidator(),
          new LanguageOptionValidator()
        ]);
}

/// Convenience class for composing validators.
class CompositeValidator extends OptionsValidator {
  final List<OptionsValidator> validators;

  CompositeValidator(this.validators);

  @override
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) =>
      validators.forEach((v) => v.validate(reporter, options));
}

/// Builds error reports with value proposals.
class ErrorBuilder {
  String proposal;
  AnalysisOptionsWarningCode code;

  /// Create a builder for the given [supportedOptions].
  ErrorBuilder(List<String> supportedOptions) {
    assert(supportedOptions != null && !supportedOptions.isEmpty);
    if (supportedOptions.length > 1) {
      proposal = StringUtilities.printListOfQuotedNames(supportedOptions);
      code = pluralProposalCode;
    } else {
      proposal = "'${supportedOptions.join()}'";
      code = singularProposalCode;
    }
  }

  AnalysisOptionsWarningCode get pluralProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES;

  AnalysisOptionsWarningCode get singularProposalCode =>
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE;

  /// Report an unsupported [node] value, defined in the given [scopeName].
  void reportError(ErrorReporter reporter, String scopeName, YamlNode node) {
    reporter
        .reportErrorForSpan(code, node.span, [scopeName, node.value, proposal]);
  }
}

/// Validates `analyzer` error filter options.
class ErrorFilterOptionValidator extends OptionsValidator {
  /// Legal values.
  static final List<String> legalValues =
      new List.from(AnalyzerOptions.ignoreSynonyms)
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
      _errorCodes = new HashSet<String>();
      // Engine codes.
      _errorCodes.addAll(errorCodeValues.map((ErrorCode code) => code.name));
    }
    return _errorCodes;
  }

  @override
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) {
    var analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer is YamlMap) {
      var filters = analyzer[AnalyzerOptions.errors];
      if (filters is YamlMap) {
        String value;
        filters.nodes.forEach((k, v) {
          if (k is YamlScalar) {
            value = toUpperCase(k.value);
            if (!errorCodes.contains(value)) {
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

/// A task that generates errors for an analysis options file.
class GenerateOptionsErrorsTask extends SourceBasedAnalysisTask {
  /// The name of the input whose value is the content of the file.
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

  /// The task descriptor describing this kind of task.
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GenerateOptionsErrorsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[ANALYSIS_OPTIONS_ERRORS, LINE_INFO],
      suitabilityFor: suitabilityFor);

  AnalysisOptionsProvider optionsProvider;

  GenerateOptionsErrorsTask(AnalysisContext context, AnalysisTarget target)
      : super(context, target) {
    optionsProvider = new AnalysisOptionsProvider(context?.sourceFactory);
  }

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  Source get source => target.source;

  @override
  void internalPerform() {
    String content = getRequiredInput(CONTENT_INPUT_NAME);
    //
    // Record outputs.
    //
    outputs[ANALYSIS_OPTIONS_ERRORS] =
        analyzeAnalysisOptions(source, content, context?.sourceFactory);
    outputs[LINE_INFO] = computeLineInfo(content);
  }

  static List<AnalysisError> analyzeAnalysisOptions(
      Source source, String content, SourceFactory sourceFactory) {
    List<AnalysisError> errors = <AnalysisError>[];
    Source initialSource = source;
    SourceSpan initialIncludeSpan;
    AnalysisOptionsProvider optionsProvider =
        new AnalysisOptionsProvider(sourceFactory);

    // Validate the specified options and any included option files
    void validate(Source source, Map<String, YamlNode> options) {
      List<AnalysisError> validationErrors =
          new OptionsFileValidator(source).validate(options);
      if (initialIncludeSpan != null && validationErrors.isNotEmpty) {
        for (AnalysisError error in validationErrors) {
          var args = [
            source.fullName,
            error.offset.toString(),
            (error.offset + error.length - 1).toString(),
            error.message,
          ];
          errors.add(new AnalysisError(
              initialSource,
              initialIncludeSpan.start.column + 1,
              initialIncludeSpan.length,
              AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING,
              args));
        }
      } else {
        errors.addAll(validationErrors);
      }

      YamlNode node = options[AnalyzerOptions.include];
      if (node == null) {
        return;
      }
      SourceSpan span = node.span;
      initialIncludeSpan ??= span;
      String includeUri = span.text;
      Source includedSource = sourceFactory.resolveUri(source, includeUri);
      if (includedSource == null || !includedSource.exists()) {
        errors.add(new AnalysisError(
            initialSource,
            initialIncludeSpan.start.column + 1,
            initialIncludeSpan.length,
            AnalysisOptionsWarningCode.INCLUDE_FILE_NOT_FOUND,
            [includeUri, source.fullName]));
        return;
      }
      try {
        Map<String, YamlNode> options =
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
        errors.add(new AnalysisError(
            initialSource,
            initialIncludeSpan.start.column + 1,
            initialIncludeSpan.length,
            AnalysisOptionsErrorCode.INCLUDED_FILE_PARSE_ERROR,
            args));
      }
    }

    try {
      Map<String, YamlNode> options =
          optionsProvider.getOptionsFromString(content);
      validate(source, options);
    } on OptionsFormatException catch (e) {
      SourceSpan span = e.span;
      errors.add(new AnalysisError(source, span.start.column + 1, span.length,
          AnalysisOptionsErrorCode.PARSE_ERROR, [e.message]));
    }
    return errors;
  }

  /// Return a map from the names of the inputs of this kind of task to the
  /// task input descriptors describing those inputs for a task with the
  /// given [target].
  static Map<String, TaskInput> buildInputs(AnalysisTarget source) =>
      <String, TaskInput>{CONTENT_INPUT_NAME: CONTENT.of(source)};

  /// Compute [LineInfo] for the given [content].
  static LineInfo computeLineInfo(String content) {
    List<int> lineStarts = StringUtilities.computeLineStarts(content);
    return new LineInfo(lineStarts);
  }

  /// Create a task based on the given [target] in the given [context].
  static GenerateOptionsErrorsTask createTask(
          AnalysisContext context, AnalysisTarget target) =>
      new GenerateOptionsErrorsTask(context, target);

  /**
   * Return an indication of how suitable this task is for the given [target].
   */
  static TaskSuitability suitabilityFor(AnalysisTarget target) {
    if (target is Source &&
        (target.shortName == AnalysisEngine.ANALYSIS_OPTIONS_FILE ||
            target.shortName == AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE)) {
      return TaskSuitability.HIGHEST;
    }
    return TaskSuitability.NONE;
  }
}

/// Validates `analyzer` language configuration options.
class LanguageOptionValidator extends OptionsValidator {
  ErrorBuilder builder = new ErrorBuilder(AnalyzerOptions.languageOptions);
  ErrorBuilder trueOrFalseBuilder = new TrueOrFalseValueErrorBuilder();

  @override
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) {
    var analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer is YamlMap) {
      var language = analyzer[AnalyzerOptions.language];
      if (language is YamlMap) {
        language.nodes.forEach((k, v) {
          String key, value;
          bool validKey = false;
          if (k is YamlScalar) {
            key = k.value?.toString();
            if (!AnalyzerOptions.languageOptions.contains(key)) {
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
      }
    }
  }
}

/// Validates `linter` top-level options.
/// TODO(pq): move into `linter` package and plugin.
class LinterOptionsValidator extends TopLevelOptionValidator {
  LinterOptionsValidator() : super('linter', const ['rules']);
}

/// Validates options defined in an analysis options file.
class OptionsFileValidator {
  /// The source being validated.
  final Source source;

  final List<OptionsValidator> _validators = [
    new AnalyzerOptionsValidator(),
    new LinterOptionsValidator(),
    new LinterRuleOptionsValidator()
  ];

  OptionsFileValidator(this.source);

  List<AnalysisError> validate(Map<String, YamlNode> options) {
    RecordingErrorListener recorder = new RecordingErrorListener();
    ErrorReporter reporter = new ErrorReporter(recorder, source);
    if (AnalysisEngine.ANALYSIS_OPTIONS_FILE == source.shortName) {
      reporter.reportError(new AnalysisError(
          source,
          0, // offset
          1, // length
          AnalysisOptionsHintCode.DEPRECATED_ANALYSIS_OPTIONS_FILE_NAME,
          [source.shortName]));
    }
    _validators.forEach((OptionsValidator v) => v.validate(reporter, options));
    return recorder.errors;
  }
}

/// Validates `analyzer` strong-mode value configuration options.
class StrongModeOptionValueValidator extends OptionsValidator {
  ErrorBuilder trueOrFalseBuilder = new TrueOrFalseValueErrorBuilder();

  @override
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) {
    var analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer is YamlMap) {
      var v = analyzer.nodes[AnalyzerOptions.strong_mode];
      if (v is YamlScalar) {
        var value = toLowerCase(v.value);
        if (!AnalyzerOptions.trueOrFalse.contains(value)) {
          trueOrFalseBuilder.reportError(
              reporter, AnalyzerOptions.strong_mode, v);
        } else if (value == 'false') {
          reporter.reportErrorForSpan(
              AnalysisOptionsHintCode.SPEC_MODE_DEPRECATED, v.span);
        }
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
    assert(supportedOptions != null && !supportedOptions.isEmpty);
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
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) {
    YamlNode node = options[pluginName];
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
  static final Map<String, Object> defaults = {'analyzer': {}};

  /**
   * Apply the options in the given [optionMap] to the given analysis [options].
   */
  void applyToAnalysisOptions(
      AnalysisOptionsImpl options, Map<String, Object> optionMap) {
    if (optionMap == null) {
      return;
    }
    var analyzer = optionMap[AnalyzerOptions.analyzer];
    if (analyzer is Map) {
      // Process strong mode option.
      var strongMode = analyzer[AnalyzerOptions.strong_mode];
      _applyStrongOptions(options, strongMode);

      // Set filters.
      var filters = analyzer[AnalyzerOptions.errors];
      _applyProcessors(options, filters);

      // Process language options.
      var language = analyzer[AnalyzerOptions.language];
      _applyLanguageOptions(options, language);

      // Process excludes.
      var excludes = analyzer[AnalyzerOptions.exclude];
      _applyExcludes(options, excludes);

      // Process plugins.
      var names = analyzer[AnalyzerOptions.plugins];
      List<String> pluginNames = <String>[];
      if (names is String) {
        pluginNames.add(names);
      } else if (names is YamlList) {
        for (var element in names) {
          if (element is String) {
            pluginNames.add(element);
          }
        }
      } else if (names is YamlMap) {
        for (var key in names.keys) {
          if (key is String) {
            pluginNames.add(key);
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

  void _applyExcludes(AnalysisOptionsImpl options, Object excludes) {
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
      if (feature == AnalyzerOptions.enableStrictCallChecks) {
        options.enableStrictCallChecks = boolValue;
      } else if (feature == AnalyzerOptions.enableSuperMixins) {
        options.enableSuperMixins = boolValue;
      } else if (feature == AnalyzerOptions.enablePreviewDart2) {
        options.previewDart2 = boolValue;
      }
    }
  }

  void _applyLanguageOptions(AnalysisOptionsImpl options, Object configs) {
    if (configs is YamlMap) {
      configs.nodes.forEach((key, value) {
        if (key is YamlScalar && value is YamlScalar) {
          String feature = key.value?.toString();
          _applyLanguageOption(options, feature, value.value);
        }
      });
    } else if (configs is Map) {
      configs
          .forEach((key, value) => _applyLanguageOption(options, key, value));
    }
  }

  void _applyProcessors(AnalysisOptionsImpl options, Object codes) {
    ErrorConfig config = new ErrorConfig(codes);
    options.errorProcessors = config.processors;
  }

  void _applyStrongModeOption(
      AnalysisOptionsImpl options, Object feature, Object value) {
    bool boolValue = toBool(value);
    if (boolValue != null) {
      if (feature == AnalyzerOptions.declarationCasts) {
        options.declarationCasts = boolValue;
      }
      if (feature == AnalyzerOptions.implicitCasts) {
        options.implicitCasts = boolValue;
      }
      if (feature == AnalyzerOptions.implicitDynamic) {
        options.implicitDynamic = boolValue;
      }
    }
  }

  void _applyStrongOptions(AnalysisOptionsImpl options, Object config) {
    if (config is YamlMap) {
      options.strongMode = true;
      config.nodes.forEach((k, v) {
        if (k is YamlScalar && v is YamlScalar) {
          _applyStrongModeOption(options, k.value?.toString(), v.value);
        }
      });
    } else if (config is Map) {
      options.strongMode = true;
      config.forEach((k, v) => _applyStrongModeOption(options, k, v));
    } else {
      options.strongMode = config is bool ? config : false;
    }
  }
}
