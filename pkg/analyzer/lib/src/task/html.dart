// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.html;

import 'dart:collection';

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:source_span/source_span.dart';

/**
 * The errors found while parsing an HTML file.
 */
final ListResultDescriptor<AnalysisError> HTML_DOCUMENT_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'HTML_DOCUMENT_ERRORS', AnalysisError.NO_ERRORS);

/**
 * A task that merges all of the errors for a single source into a single list
 * of errors.
 */
class HtmlErrorsTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [HTML_DOCUMENT_ERRORS] input.
   */
  static const String DOCUMENT_ERRORS_INPUT = 'DOCUMENT_ERRORS';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('HtmlErrorsTask',
      createTask, buildInputs, <ResultDescriptor>[HTML_ERRORS]);

  HtmlErrorsTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    List<AnalysisError> errors = getRequiredInput(DOCUMENT_ERRORS_INPUT);
    //
    // Record outputs.
    //
    outputs[HTML_ERRORS] = errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(Source target) {
    return <String, TaskInput>{
      DOCUMENT_ERRORS_INPUT: HTML_DOCUMENT_ERRORS.of(target)
    };
  }

  /**
   * Create an [HtmlErrorsTask] based on the given [target] in the given
   * [context].
   */
  static HtmlErrorsTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new HtmlErrorsTask(context, target);
  }
}

/**
 * A task that scans the content of a file, producing a set of Dart tokens.
 */
class ParseHtmlTask extends SourceBasedAnalysisTask {
  /**
   * The name of the input whose value is the content of the file.
   */
  static const String CONTENT_INPUT_NAME = 'CONTENT_INPUT_NAME';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor('ParseHtmlTask',
      createTask, buildInputs, <ResultDescriptor>[
    HTML_DOCUMENT,
    HTML_DOCUMENT_ERRORS
  ]);

  /**
   * Initialize a newly created task to access the content of the source
   * associated with the given [target] in the given [context].
   */
  ParseHtmlTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    String content = getRequiredInput(CONTENT_INPUT_NAME);

    HtmlParser parser = new HtmlParser(content);
    parser.compatMode = 'quirks';
    Document document = parser.parse();
    List<ParseError> parseErrors = parser.errors;
    List<AnalysisError> errors = <AnalysisError>[];
    for (ParseError parseError in parseErrors) {
      SourceSpan span = parseError.span;
      errors.add(new AnalysisError(target.source, span.start.offset,
          span.length, HtmlErrorCode.PARSE_ERROR, [parseError.message]));
    }

    outputs[HTML_DOCUMENT] = document;
    outputs[HTML_DOCUMENT_ERRORS] = errors;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [source].
   */
  static Map<String, TaskInput> buildInputs(Source source) {
    return <String, TaskInput>{CONTENT_INPUT_NAME: CONTENT.of(source)};
  }

  /**
   * Create a [ParseHtmlTask] based on the given [target] in the given [context].
   */
  static ParseHtmlTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ParseHtmlTask(context, target);
  }
}

/**
 * A task that computes the Dart libraries that are referenced by an HTML file.
 */
class ReferencedLibrariesTask extends SourceBasedAnalysisTask {
  /**
   * The name of the [HTML_DOCUMENT] input.
   */
  static const String DOCUMENT_INPUT = 'DOCUMENT';

  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ReferencedLibrariesTask', createTask, buildInputs,
      <ResultDescriptor>[REFERENCED_LIBRARIES]);

  ReferencedLibrariesTask(
      InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //
    // Prepare inputs.
    //
    List<Source> libraries = <Source>[];
    Document document = getRequiredInput(DOCUMENT_INPUT);
    List<Element> scripts = document.getElementsByTagName('script');
    for (Element script in scripts) {
      LinkedHashMap<dynamic, String> attributes = script.attributes;
      if (attributes['type'] == 'application/dart') {
        String src = attributes['src'];
        if (AnalysisEngine.isDartFileName(src)) {
          Source source = context.sourceFactory.resolveUri(target.source, src);
          if (source != null) {
            libraries.add(source);
          }
        }
      }
    }
    //
    // Record outputs.
    //
    outputs[REFERENCED_LIBRARIES] =
        libraries.isEmpty ? Source.EMPTY_LIST : libraries;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the
   * given [target].
   */
  static Map<String, TaskInput> buildInputs(Source target) {
    return <String, TaskInput>{DOCUMENT_INPUT: HTML_DOCUMENT.of(target)};
  }

  /**
   * Create a [ReferencedLibrariesTask] based on the given [target] in the given
   * [context].
   */
  static ReferencedLibrariesTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ReferencedLibrariesTask(context, target);
  }
}
