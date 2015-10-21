// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.options;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
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

/// A task that generates errors for an `.analysis_options` file.
class GenerateOptionsErrorsTask extends SourceBasedAnalysisTask {
  /// The name of the input whose value is the content of the file.
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

  /// The task descriptor describing this kind of task.
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GenerateOptionsErrorsTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[ANALYSIS_OPTIONS_ERRORS]);

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
  }

  List<AnalysisError> _validate(Map<String, YamlNode> options) =>
      new OptionsFileValidator(source).validate(options);

  /// Return a map from the names of the inputs of this kind of task to the
  /// task input descriptors describing those inputs for a task with the
  /// given [target].
  static Map<String, TaskInput> buildInputs(Source source) =>
      <String, TaskInput>{CONTENT_INPUT_NAME: CONTENT.of(source)};

  /// Create a task based on the given [target] in the given [context].
  static GenerateOptionsErrorsTask createTask(
          AnalysisContext context, AnalysisTarget target) =>
      new GenerateOptionsErrorsTask(context, target);
}

/// Validates options defined in an `.analysis_options` file.
class OptionsFileValidator {
  // TODO(pq): consider an extension point.
  static final List<OptionsValidator> _validators = [
    new AnalyzerOptionsValidator()
  ];

  final Source source;
  OptionsFileValidator(this.source);

  List<AnalysisError> validate(Map<String, YamlNode> options) {
    List<AnalysisError> errors = <AnalysisError>[];
    _validators.forEach(
        (OptionsValidator v) => errors.addAll(v.validate(source, options)));
    return errors;
  }
}

AnalysisError _unsupportedOption(
    Source source, YamlScalar key, String pluginName) {
  SourceSpan span = key.span;
  return new AnalysisError(source, span.start.column + 1, span.length,
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION, [pluginName, key.value]);
}

/// Validates options.
abstract class OptionsValidator {
  List<AnalysisError> validate(Source source, Map<String, YamlNode> options);
}

/// Validates `analyzer` options.
class AnalyzerOptionsValidator extends OptionsValidator {
  static const List<String> _supportedOptions = const [
    'exclude',
    'strong-mode'
  ];

  @override
  List<AnalysisError> validate(Source source, Map<String, YamlNode> options) {
    List<AnalysisError> errors = <AnalysisError>[];
    YamlNode node = options['analyzer'];
    if (node is YamlMap) {
      node.nodes.forEach((k, v) {
        if (k is YamlScalar) {
          if (!_supportedOptions.contains(k.value)) {
            errors.add(_unsupportedOption(source, k, 'analyzer'));
          }
        }
      });
    }
    return errors;
  }
}
