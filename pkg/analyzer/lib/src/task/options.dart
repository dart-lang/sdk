// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.options;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// The errors produced while parsing `.analysis_options` files.
///
/// The list will be empty if there were no errors, but will not be `null`.
final ListResultDescriptor<AnalysisError> ANALYSIS_OPTIONS_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'ANALYSIS_OPTIONS_ERRORS', AnalysisError.NO_ERRORS);

final _OptionsProcessor _processor = new _OptionsProcessor();

/// Configure this [context] based on configuration details specified in
/// the given [options].
void configureContextOptions(
        AnalysisContext context, Map<String, YamlNode> options) =>
    _processor.configure(context, options);

/// `analyzer` analysis options constants.
class AnalyzerOptions {
  static const String analyzer = 'analyzer';
  static const String enableSuperMixins = 'enableSuperMixins';
  static const String errors = 'errors';
  static const String exclude = 'exclude';
  static const String language = 'language';
  static const String plugins = 'plugins';
  static const String strong_mode = 'strong-mode';

  /// Ways to say `ignore`.
  static const List<String> ignoreSynonyms = const ['ignore', 'false'];

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
  static const List<String> languageOptions = const [enableSuperMixins];
}

/// Validates `analyzer` options.
class AnalyzerOptionsValidator extends CompositeValidator {
  AnalyzerOptionsValidator()
      : super([
          new TopLevelAnalyzerOptionsValidator(),
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
    reporter.reportErrorForSpan(
        code, node.span, [scopeName, node.value, proposal]);
  }
}

/// Validates `analyzer` error filter options.
class ErrorFilterOptionValidator extends OptionsValidator {
  /// Pretty list of legal includes.
  static final String legalIncludes = StringUtilities.printListOfQuotedNames(
      new List.from(AnalyzerOptions.ignoreSynonyms)
        ..addAll(AnalyzerOptions.includeSynonyms));

  @override
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) {
    YamlMap analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer == null) {
      return;
    }

    YamlNode filters = analyzer[AnalyzerOptions.errors];
    if (filters is YamlMap) {
      String value;
      filters.nodes.forEach((k, v) {
        if (k is YamlScalar) {
          value = toUpperCase(k.value);
          if (!ErrorCode.values.any((ErrorCode code) => code.name == value)) {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE,
                k.span,
                [k.value?.toString()]);
          }
        }
        if (v is YamlScalar) {
          value = toLowerCase(v.value);
          if (!AnalyzerOptions.ignoreSynonyms.contains(value) &&
              !AnalyzerOptions.includeSynonyms.contains(value)) {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES,
                v.span,
                [AnalyzerOptions.errors, v.value?.toString(), legalIncludes]);
          }
        }
      });
    }
  }
}

/// A task that generates errors for an `.analysis_options` file.
class GenerateOptionsErrorsTask extends SourceBasedAnalysisTask {
  /// The name of the input whose value is the content of the file.
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

  /// The task descriptor describing this kind of task.
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GenerateOptionsErrorsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[ANALYSIS_OPTIONS_ERRORS, LINE_INFO]);

  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();

  GenerateOptionsErrorsTask(AnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  Source get source => target.source;

  @override
  void internalPerform() {
    String content = getRequiredInput(CONTENT_INPUT_NAME);

    List<AnalysisError> errors = <AnalysisError>[];

    try {
      Map<String, YamlNode> options =
          optionsProvider.getOptionsFromString(content);
      errors.addAll(_validate(options));
    } on OptionsFormatException catch (e) {
      SourceSpan span = e.span;
      var error = new AnalysisError(source, span.start.column + 1, span.length,
          AnalysisOptionsErrorCode.PARSE_ERROR, [e.message]);
      errors.add(error);
    }

    //
    // Record outputs.
    //
    outputs[ANALYSIS_OPTIONS_ERRORS] = errors;
    outputs[LINE_INFO] = computeLineInfo(content);
  }

  List<AnalysisError> _validate(Map<String, YamlNode> options) =>
      new OptionsFileValidator(source).validate(options);

  /// Return a map from the names of the inputs of this kind of task to the
  /// task input descriptors describing those inputs for a task with the
  /// given [target].
  static Map<String, TaskInput> buildInputs(Source source) =>
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
}

/// Validates `analyzer` language configuration options.
class LanguageOptionValidator extends OptionsValidator {
  ErrorBuilder builder = new ErrorBuilder(AnalyzerOptions.languageOptions);
  ErrorBuilder trueOrFalseBuilder = new TrueOrFalseValueErrorBuilder();

  @override
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) {
    YamlMap analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer == null) {
      return;
    }

    YamlNode language = analyzer[AnalyzerOptions.language];
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

/// Validates `linter` top-level options.
/// TODO(pq): move into `linter` package and plugin.
class LinterOptionsValidator extends TopLevelOptionValidator {
  LinterOptionsValidator() : super('linter', const ['rules']);
}

/// Validates options defined in an `.analysis_options` file.
class OptionsFileValidator {
  // TODO(pq): move to an extension point.
  final List<OptionsValidator> _validators = [
    new AnalyzerOptionsValidator(),
    new LinterOptionsValidator()
  ];

  final Source source;
  OptionsFileValidator(this.source) {
    _validators.addAll(AnalysisEngine.instance.optionsPlugin.optionsValidators);
  }

  List<AnalysisError> validate(Map<String, YamlNode> options) {
    RecordingErrorListener recorder = new RecordingErrorListener();
    ErrorReporter reporter = new ErrorReporter(recorder, source);
    _validators.forEach((OptionsValidator v) => v.validate(reporter, options));
    return recorder.errors;
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
  void configure(AnalysisContext context, Map<String, YamlNode> options) {
    if (options == null) {
      return;
    }

    YamlMap analyzer = options[AnalyzerOptions.analyzer];
    if (analyzer == null) {
      return;
    }

    // Set strong mode (default is false).
    bool strongMode = analyzer[AnalyzerOptions.strong_mode] ?? false;
    setStrongMode(context, strongMode);

    // Set filters.
    YamlNode filters = analyzer[AnalyzerOptions.errors];
    setFilters(context, filters);

    // Process language options.
    YamlNode language = analyzer[AnalyzerOptions.language];
    setLanguageOptions(context, language);
  }

  void setFilters(AnalysisContext context, YamlNode codes) {
    List<ErrorFilter> filters = <ErrorFilter>[];
    // If codes are enumerated, collect them as filters; else leave filters
    // empty to overwrite previous value.
    if (codes is YamlMap) {
      String value;
      codes.nodes.forEach((k, v) {
        if (k is YamlScalar && v is YamlScalar) {
          value = toLowerCase(v.value);
          if (AnalyzerOptions.ignoreSynonyms.contains(value)) {
            // Case-insensitive.
            String code = toUpperCase(k.value);
            filters.add((AnalysisError error) => error.errorCode.name == code);
          }
        }
      });
    }
    context.setConfigurationData(CONFIGURED_ERROR_FILTERS, filters);
  }

  void setLanguageOptions(AnalysisContext context, YamlNode configs) {
    if (configs is YamlMap) {
      configs.nodes.forEach((k, v) {
        String feature;
        if (k is YamlScalar && v is YamlScalar) {
          feature = k.value?.toString();
          if (feature == AnalyzerOptions.enableSuperMixins) {
            if (isTrue(v.value)) {
              AnalysisOptionsImpl options =
                  new AnalysisOptionsImpl.from(context.analysisOptions);
              options.enableSuperMixins = true;
              context.analysisOptions = options;
            }
          }
        }
      });
    }
  }

  void setStrongMode(AnalysisContext context, bool strongMode) {
    if (context.analysisOptions.strongMode != strongMode) {
      AnalysisOptionsImpl options =
          new AnalysisOptionsImpl.from(context.analysisOptions);
      options.strongMode = strongMode;
      context.analysisOptions = options;
    }
  }
}
