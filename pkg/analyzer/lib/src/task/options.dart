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

/// `analyzer` analysis options constants.
class AnalyzerOptions {
  static const String errors = 'errors';
  static const String exclude = 'exclude';
  static const String plugins = 'plugins';
  static const String strong_mode = 'strong-mode';

  /// Supported top-level `analyzer` options.
  static const List<String> top_level = const [
    errors,
    exclude,
    plugins,
    strong_mode
  ];
}

/// Validates `analyzer` top-level options.
class AnalyzerOptionsValidator extends TopLevelOptionValidator {
  AnalyzerOptionsValidator() : super('analyzer', AnalyzerOptions.top_level);
}

/// Convenience class for composing validators.
class CompositeValidator extends OptionsValidator {
  final List<OptionsValidator> validators;
  CompositeValidator(this.validators);

  @override
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) =>
      validators.forEach((v) => v.validate(reporter, options));
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

/// Validates top-level options. For example,
///     plugin:
///       top-level-option: true
class TopLevelOptionValidator extends OptionsValidator {
  final String pluginName;
  final List<String> supportedOptions;

  TopLevelOptionValidator(this.pluginName, this.supportedOptions);
  @override
  void validate(ErrorReporter reporter, Map<String, YamlNode> options) {
    YamlNode node = options[pluginName];
    if (node is YamlMap) {
      node.nodes.forEach((k, v) {
        if (k is YamlScalar) {
          if (!supportedOptions.contains(k.value)) {
            reporter.reportErrorForSpan(
                AnalysisOptionsWarningCode.UNSUPPORTED_OPTION,
                k.span,
                [pluginName, k.value]);
          }
        }
        //TODO(pq): consider an error if the node is not a Scalar.
      });
    }
  }
}
