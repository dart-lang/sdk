// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.model;

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/task/model.dart';

/**
 * A concrete implementation of a [CompositeResultDescriptor].
 */
class CompositeResultDescriptorImpl<V> extends ResultDescriptorImpl<V>
    implements CompositeResultDescriptor<V> {
  /**
   * The results that contribute to this result.
   */
  final List<ResultDescriptor<V>> contributors = <ResultDescriptor<V>>[];

  /**
   * Initialize a newly created composite result to have the given [name].
   */
  CompositeResultDescriptorImpl(String name) : super(name, null);

  /**
   * Record that the given analysis [result] contibutes to this result.
   */
  void recordContributor(ResultDescriptor<V> result) {
    contributors.add(result);
  }
}

/**
 * A concrete implementation of a [ListResultDescriptor].
 */
class ListResultDescriptorImpl<E> extends ResultDescriptorImpl<List<E>>
    implements ListResultDescriptor<E> {
  /**
   * Initialize a newly created analysis result to have the given [name] and
   * [defaultValue]. If a composite result is specified, then this result will
   * contribute to it.
   */
  ListResultDescriptorImpl(String name, List<E> defaultValue,
      {CompositeResultDescriptor contributesTo})
      : super(name, defaultValue, contributesTo: contributesTo);

  @override
  ListTaskInput<E> of(AnalysisTarget target) =>
      new ListTaskInputImpl<E>(target, this);
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
   * [defaultValue]. If a composite result is specified, then this result will
   * contribute to it.
   */
  ResultDescriptorImpl(this.name, this.defaultValue,
      {CompositeResultDescriptor contributesTo}) {
    if (contributesTo is CompositeResultDescriptorImpl) {
      contributesTo.recordContributor(this);
    }
  }

  @override
  TaskInput<V> of(AnalysisTarget target) =>
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
  TaskDescriptorImpl(
      this.name, this.buildTask, this.createTaskInputs, this.results);

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
