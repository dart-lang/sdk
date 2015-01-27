// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.general;

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';

/**
 * A task that gets the contents of the source associated with an analysis
 * target.
 */
class GetContentTask extends AnalysisTask {
  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GET_CONTENT',
      createTask,
      buildInputs,
      <ResultDescriptor>[CONTENT, MODIFICATION_TIME]);

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
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  internalPerform() {
    Source source = getRequiredSource();

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
