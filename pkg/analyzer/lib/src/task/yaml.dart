// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/api/general.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:analyzer/src/task/api/yaml.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/**
 * A task that scans the content of a YAML file, producing a YAML document.
 */
class ParseYamlTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the content of the file.
   */
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ParseYamlTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[YAML_DOCUMENT, YAML_ERRORS, LINE_INFO],
      suitabilityFor: suitabilityFor);

  /**
   * Initialize a newly created task to access the content of the source
   * associated with the given [target] in the given [context].
   */
  ParseYamlTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    Source source = target.source;
    String uri = source.uri.toString();
    String content = getRequiredInput(CONTENT_INPUT_NAME);

    if (context.getModificationStamp(source) < 0) {
      String message = 'Content could not be read';
      if (context is InternalAnalysisContext) {
        CacheEntry entry =
            (context as InternalAnalysisContext).getCacheEntry(target);
        CaughtException exception = entry.exception;
        if (exception != null) {
          message = exception.toString();
        }
      }
      //
      // Record outputs.
      //
      outputs[YAML_DOCUMENT] = loadYamlDocument('', sourceUrl: uri);
      outputs[YAML_ERRORS] = <AnalysisError>[
        new AnalysisError(
            source, 0, 0, ScannerErrorCode.UNABLE_GET_CONTENT, [message])
      ];
      outputs[LINE_INFO] = new LineInfo(<int>[0]);
    } else {
      YamlDocument document;
      List<AnalysisError> errors = <AnalysisError>[];
      try {
        document = loadYamlDocument(content, sourceUrl: uri);
      } on YamlException catch (exception) {
        SourceSpan span = exception.span;
        int offset = span.start.offset;
        int length = span.end.offset - offset;
        errors.add(new AnalysisError(source, offset, length,
            YamlErrorCode.PARSE_ERROR, [exception.message]));
      } catch (exception, stackTrace) {
        throw new AnalysisException('Error while parsing ${source.fullName}',
            new CaughtException(exception, stackTrace));
      }
      //
      // Record outputs.
      //
      outputs[YAML_DOCUMENT] = document;
      outputs[YAML_ERRORS] = errors;
      outputs[LINE_INFO] = new LineInfo.fromContent(content);
    }
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [source].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget source) {
    return <String, TaskInput>{CONTENT_INPUT_NAME: CONTENT.of(source)};
  }

  /**
   * Create a [ParseYamlTask] based on the given [target] in the given [context].
   */
  static ParseYamlTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ParseYamlTask(context, target);
  }

  /**
   * Return an indication of how suitable this task is for the given [target].
   */
  static TaskSuitability suitabilityFor(AnalysisTarget target) {
    if (target is Source && target.shortName.endsWith('.yaml')) {
      return TaskSuitability.HIGHEST;
    }
    return TaskSuitability.NONE;
  }
}

/**
 * The error codes used for errors in YAML files.
 */
class YamlErrorCode extends ErrorCode {
  // TODO(brianwilkerson) Move this class to error.dart.

  /**
   * An error code indicating that there is a syntactic error in the file.
   *
   * Parameters:
   * 0: the error message from the parse error
   */
  static const YamlErrorCode PARSE_ERROR =
      const YamlErrorCode('PARSE_ERROR', '{0}');

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const YamlErrorCode(String name, String message, {String correction})
      : super.temporary(name, message, correction: correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}
