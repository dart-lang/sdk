// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:analyzer/src/task/inputs.dart';

/**
 * The default [ResultCachingPolicy], results are never flushed.
 */
const ResultCachingPolicy DEFAULT_CACHING_POLICY =
    const SimpleResultCachingPolicy(-1, -1);

/**
 * A concrete implementation of a [ListResultDescriptor].
 */
class ListResultDescriptorImpl<E> extends ResultDescriptorImpl<List<E>>
    implements ListResultDescriptor<E> {
  /**
   * Initialize a newly created analysis result to have the given [name] and
   * [defaultValue]. If a [cachingPolicy] is provided, it will control how long
   * values associated with this result will remain in the cache.
   */
  ListResultDescriptorImpl(String name, List<E> defaultValue,
      {ResultCachingPolicy cachingPolicy: DEFAULT_CACHING_POLICY})
      : super(name, defaultValue, cachingPolicy: cachingPolicy);

  @override
  ListTaskInput<E> of(AnalysisTarget target, {bool flushOnAccess: false}) {
    if (flushOnAccess) {
      throw new StateError('Cannot flush a list of values');
    }
    return new ListTaskInputImpl<E>(target, this);
  }
}

/**
 * A concrete implementation of a [ResultDescriptor].
 */
class ResultDescriptorImpl<V> implements ResultDescriptor<V> {
  static int _NEXT_HASH = 0;

  @override
  final hashCode = _NEXT_HASH++;

  /**
   * The name of the result, used for debugging.
   */
  final String name;

  /**
   * Return the default value for results described by this descriptor.
   */
  final V defaultValue;

  /**
   * The caching policy for results described by this descriptor.
   */
  final ResultCachingPolicy cachingPolicy;

  /**
   * Initialize a newly created analysis result to have the given [name] and
   * [defaultValue]. If a [cachingPolicy] is provided, it will control how long
   * values associated with this result will remain in the cache.
   */
  ResultDescriptorImpl(this.name, this.defaultValue,
      {this.cachingPolicy: DEFAULT_CACHING_POLICY});

  @override
  bool operator ==(Object other) {
    return other is ResultDescriptorImpl && other.hashCode == hashCode;
  }

  @override
  TaskInput<V> of(AnalysisTarget target, {bool flushOnAccess: false}) =>
      new SimpleTaskInput<V>(target, this, flushOnAccess: flushOnAccess);

  @override
  String toString() => name;
}

/**
 * A simple [ResultCachingPolicy] implementation that consider all the objects
 * to be of the size `1`.
 */
class SimpleResultCachingPolicy implements ResultCachingPolicy {
  @override
  final int maxActiveSize;

  @override
  final int maxIdleSize;

  const SimpleResultCachingPolicy(this.maxActiveSize, this.maxIdleSize);

  @override
  int measure(Object object) => 1;
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
   * The function used to determine whether the described task is suitable for
   * a given target.
   */
  final SuitabilityFor _suitabilityFor;

  /**
   * Initialize a newly created task descriptor to have the given [name] and to
   * describe a task that takes the inputs built using the given [inputBuilder],
   * and produces the given [results]. The [buildTask] function will be used to
   * create the instance of [AnalysisTask] being described. If provided, the
   * [isAppropriateFor] function will be used to determine whether the task can
   * be used on a specific target.
   */
  TaskDescriptorImpl(
      this.name, this.buildTask, this.createTaskInputs, this.results,
      {SuitabilityFor suitabilityFor})
      : _suitabilityFor = suitabilityFor ?? _defaultSuitability;

  @override
  AnalysisTask createTask(AnalysisContext context, AnalysisTarget target,
      Map<String, dynamic> inputs) {
    AnalysisTask task = buildTask(context, target);
    task.inputs = inputs;
    return task;
  }

  @override
  TaskSuitability suitabilityFor(AnalysisTarget target) =>
      _suitabilityFor(target);

  @override
  String toString() => name;

  /**
   * The function that will be used to determine the suitability of a task if no
   * other function is provided.
   */
  static TaskSuitability _defaultSuitability(AnalysisTarget target) =>
      TaskSuitability.LOWEST;
}
