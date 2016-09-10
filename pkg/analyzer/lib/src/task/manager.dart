// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.manager;

import 'dart:collection';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/task/model.dart';

/**
 * An object that manages the information about the tasks that have been
 * defined.
 */
class TaskManager {
  /**
   * A table mapping [ResultDescriptor]s to a list of [TaskDescriptor]s
   * for the tasks that can be used to compute the result.
   */
  Map<ResultDescriptor, List<TaskDescriptor>> taskMap =
      new HashMap<ResultDescriptor, List<TaskDescriptor>>();

  /**
   * A list of the results that are to be computed for all sources within an
   * analysis root.
   */
  Set<ResultDescriptor> generalResults = new Set<ResultDescriptor>();

  /**
   * A list of the results that are to be computed for priority sources.
   */
  Set<ResultDescriptor> priorityResults = new Set<ResultDescriptor>();

  /**
   * Add the given [result] to the list of results that are to be computed for
   * all sources within an analysis root.
   */
  void addGeneralResult(ResultDescriptor result) {
    generalResults.add(result);
  }

  /**
   * Add the given [result] to the list of results that are to be computed for
   * priority sources.
   */
  void addPriorityResult(ResultDescriptor result) {
    priorityResults.add(result);
  }

  /**
   * Add the given [descriptor] to the list of analysis task descriptors that
   * can be used to compute analysis results.
   */
  void addTaskDescriptor(TaskDescriptor descriptor) {
    descriptor.results.forEach((ResultDescriptor result) {
      //
      // Add the result to the task map.
      //
      List<TaskDescriptor> descriptors = taskMap[result];
      if (descriptors == null) {
        descriptors = <TaskDescriptor>[];
        taskMap[result] = descriptors;
      }
      descriptors.add(descriptor);
    });
  }

  /**
   * Add the task descriptors in the given list of [descriptors] to the list of
   * analysis task descriptors that can be used to compute analysis results.
   */
  void addTaskDescriptors(List<TaskDescriptor> descriptors) {
    descriptors.forEach(addTaskDescriptor);
  }

  /**
   * Find a task that will compute the given [result] for the given [target].
   */
  TaskDescriptor findTask(AnalysisTarget target, ResultDescriptor result) {
    List<TaskDescriptor> descriptors = taskMap[result];
    if (descriptors == null) {
      throw new AnalysisException(
          'No tasks registered to compute $result for $target');
    }
    return _findBestTask(descriptors, target);
  }

  /**
   * Remove the given [result] from the list of results that are to be computed
   * for all sources within an analysis root.
   */
  void removeGeneralResult(ResultDescriptor result) {
    generalResults.remove(result);
  }

  /**
   * Remove the given [result] from the list of results that are to be computed
   * for priority sources.
   */
  void removePriorityResult(ResultDescriptor result) {
    priorityResults.remove(result);
  }

  /**
   * Given a list of task [descriptors] that can be used to compute some
   * unspecified result for the given [target], return the descriptor that
   * should be used to compute the result.
   */
  TaskDescriptor _findBestTask(
      List<TaskDescriptor> descriptors, AnalysisTarget target) {
    TaskDescriptor best = null;
    for (TaskDescriptor descriptor in descriptors) {
      TaskSuitability suitability = descriptor.suitabilityFor(target);
      if (suitability == TaskSuitability.HIGHEST) {
        return descriptor;
      } else if (best == null && suitability == TaskSuitability.LOWEST) {
        best = descriptor;
      }
    }
    return best;
  }
}
