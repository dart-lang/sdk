// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.general;

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * The description of the task used to get the content of a source.
 */
final TaskDescriptor GET_CONTENT = new TaskDescriptor(
    'GET_CONTENT',
    GetContentTask.createTask,
    GetContentTask.buildInputs,
    <ResultDescriptor>[CONTENT, MODIFICATION_TIME]);

/**
 * A task that gets the contents of the source associated with an analysis
 * target.
 */
class GetContentTask extends AnalysisTask {
  /**
   * Initialize a newly created task to access the content of the source
   * associated with the given [target] in the given [context].
   */
  GetContentTask(InternalAnalysisContext context, AnalysisTarget target)
      : super(context, target);

  @override
  String get description {
    Source source = target.source;
    if (source == null) {
      return "get contents of <unknown source>";
    }
    return "get contents of ${source.fullName}";
  }

  @override
  internalPerform() {
    Source source = target.source;
    if (source == null) {
      throw new AnalysisException(
          "Could not get contents: no source associated with the target");
    }
    TimestampedData<String> data = context.getContents(source);
    outputs[CONTENT] = data.data;
    outputs[MODIFICATION_TIME] = data.modificationTime;
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    return <String, TaskInput>{};
  }

  /**
   * Create a [GetContentTask] based on the given [target] in the given
   * [context].
   */
  static GetContentTask createTask(AnalysisContext context,
      AnalysisTarget target) {
    return new GetContentTask(context, target);
  }
}
