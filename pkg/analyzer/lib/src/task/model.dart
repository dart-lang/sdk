// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.model;

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/task/model.dart';

/**
 * A concrete implementation of a [ContributionPoint].
 */
class ContributionPointImpl<V> extends ResultDescriptorImpl<V> implements
    ContributionPoint<V> {
  /**
   * The results that contribute to this result.
   */
  final List<ResultDescriptor<V>> contributors = <ResultDescriptor<V>>[];

  /**
   * Initialize a newly created contribution point to have the given [name].
   */
  ContributionPointImpl(String name) : super(name, null);

  /**
   * Record that the given analysis [result] contibutes to this result.
   */
  void recordContributor(ResultDescriptor<V> result) {
    contributors.add(result);
  }
}

/**
 * A concrete implementation of a [ResultDescriptor].
 */
class ResultDescriptorImpl<V> implements ResultDescriptor<V> {
  /**
   * The name of the result, used for debugging.
   */
  final String name;

  /**
   * Return the default value for results described by this descriptor.
   */
  final V defaultValue;

  /**
   * Initialize a newly created analysis result to have the given [name] and
   * [defaultValue]. If a contribution point is specified, then this result will
   * contribute to it.
   */
  ResultDescriptorImpl(this.name, this.defaultValue,
      {ContributionPoint contributesTo}) {
    if (contributesTo is ContributionPointImpl) {
      contributesTo.recordContributor(this);
    }
  }

  @override
  TaskInput<V> inputFor(AnalysisTarget target) =>
      new SimpleTaskInput<V>(target, this);

  @override
  String toString() => name;
}

/**
 * A concrete implementation of a [TaskDescriptor].
 */
class TaskDescriptorImpl implements TaskDescriptor {
  /**
   * The name of the described task, used for debugging.
   */
  final String name;

  /**
   * The function used to build the analysis task.
   */
  final BuildTask buildTask;

  /**
   * The function used to build the inputs to the task.
   */
  @override
  final CreateTaskInputs createTaskInputs;

  /**
   * A list of the analysis results that will be computed by the described task.
   */
  @override
  final List<ResultDescriptor> results;

  /**
   * Initialize a newly created task descriptor to have the given [name] and to
   * describe a task that takes the inputs built using the given [createTaskInputs],
   * and produces the given [results]. The [buildTask] will be used to create
   * the instance of [AnalysisTask] thusly described.
   */
  TaskDescriptorImpl(this.name, this.buildTask, this.createTaskInputs,
      this.results);

  @override
  AnalysisTask createTask(AnalysisContext context, AnalysisTarget target,
      Map<String, dynamic> inputs) {
    AnalysisTask task = buildTask(context, target);
    task.inputs = inputs;
    return task;
  }

  @override
  String toString() => name;
}
