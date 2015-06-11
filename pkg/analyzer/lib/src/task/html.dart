// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.html;

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/html.dart';
import 'package:analyzer/task/model.dart';
//import 'package:html/dom.dart';
//import 'package:html/parser.dart';

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
      createTask, buildInputs,
      <ResultDescriptor>[/*DOCUMENT, DOCUMENT_ERRORS*/]);

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
//    String content = getRequiredInput(CONTENT_INPUT_NAME);
//
//    HtmlParser parser = new HtmlParser(content);
//    Document document = parser.parse();
//    List<ParseError> errors = parser.errors;
//
//    outputs[DOCUMENT] = document;
//    outputs[DOCUMENT_ERRORS] = errors;
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
