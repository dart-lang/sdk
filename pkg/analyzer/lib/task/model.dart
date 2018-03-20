// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:developer';

import 'package:analyzer/error/error.dart' show AnalysisError;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:front_end/src/base/analysis_target.dart';

export 'package:front_end/src/base/analysis_target.dart' show AnalysisTarget;

/**
 * A function that converts the given [key] and [value] into a [TaskInput].
 */
typedef TaskInput<E> BinaryFunction<K, V, E>(K key, V value);

/**
 * A function that takes an analysis [context] and an analysis [target] and
 * returns an analysis task. Such functions are passed to a [TaskDescriptor] to
 * be used to create the described task.
 */
typedef AnalysisTask BuildTask(AnalysisContext context, AnalysisTarget target);

/**
 * A function that takes the target for which a task will produce results and
 * returns a map from input names to descriptions of the analysis results needed
 * by the task in order for the task to be performed. Such functions are passed
 * to a [TaskDescriptor] to be used to determine the inputs needed by the task.
 */
typedef Map<String, TaskInput> CreateTaskInputs(AnalysisTarget target);

/**
 * A function that takes the target for which a task will produce results and
 * returns an indication of how suitable the task is for the target. Such
 * functions are passed to a [TaskDescriptor] to be used to determine their
 * suitability for computing results.
 */
typedef TaskSuitability SuitabilityFor(AnalysisTarget target);

/**
 * A function that converts an object of the type [B] into a [TaskInput].
 * This is used, for example, by a [ListTaskInput] to create task inputs
 * for each value in a list of values.
 */
typedef TaskInput<E> UnaryFunction<B, E>(B object);

/**
 * An [AnalysisTarget] wrapper for an [AnalysisContext].
 */
class AnalysisContextTarget implements AnalysisTarget {
  static final AnalysisContextTarget request = new AnalysisContextTarget(null);

  final AnalysisContext context;

  AnalysisContextTarget(this.context);

  @override
  Source get librarySource => null;

  @override
  Source get source => null;
}

/**
 * An object used to compute one or more analysis results associated with a
 * single target.
 *
 * Clients must extend this class when creating new tasks.
 */
abstract class AnalysisTask {
  /**
   * A queue storing the last 10 task descriptions for diagnostic purposes.
   */
  static final LimitedQueue<String> LAST_TASKS = new LimitedQueue<String>(10);

  /**
   * A table mapping the types of analysis tasks to the number of times each
   * kind of task has been performed.
   */
  static final Map<Type, int> countMap = new HashMap<Type, int>();

  /**
   * A table mapping the types of analysis tasks to user tags used to collect
   * timing data for the Observatory.
   */
  static Map<Type, UserTag> tagMap = new HashMap<Type, UserTag>();

  /**
   * A table mapping the types of analysis tasks to stopwatches used to compute
   * how much time was spent executing each kind of task.
   */
  static final Map<Type, Stopwatch> stopwatchMap =
      new HashMap<Type, Stopwatch>();

  /**
   * The context in which the task is to be performed.
   */
  final AnalysisContext context;

  /**
   * The target for which result values are being produced.
   */
  final AnalysisTarget target;

  /**
   * A table mapping input names to input values.
   */
  Map<String, dynamic> inputs;

  /**
   * A table mapping result descriptors whose values are produced by this task
   * to the values that were produced.
   */
  Map<ResultDescriptor, dynamic> outputs =
      new HashMap<ResultDescriptor, dynamic>();

  /**
   * The exception that was thrown while performing this task, or `null` if the
   * task completed successfully.
   */
  CaughtException caughtException;

  /**
   * If a dependency cycle was found while computing the inputs for the task,
   * the set of [WorkItem]s contained in the cycle (if there are overlapping
   * cycles, this is the set of all [WorkItem]s in the entire strongly
   * connected component).  Otherwise, `null`.
   */
  List<WorkItem> dependencyCycle;

  /**
   * Initialize a newly created task to perform analysis within the given
   * [context] in order to produce results for the given [target].
   */
  AnalysisTask(this.context, this.target);

  /**
   * Return a textual description of this task.
   */
  String get description;

  /**
   * Return the descriptor that describes this task.
   */
  TaskDescriptor get descriptor;

  /**
   * Indicates whether the task is capable of handling dependency cycles.  A
   * task that overrides this getter to return `true` must be prepared for the
   * possibility that it will be invoked with a non-`null` value of
   * [dependencyCycle], and with not all of its inputs computed.
   */
  bool get handlesDependencyCycles => false;

  /**
   * Return the value of the input with the given [name], or `null` if the input
   * value is not defined.
   */
  Object getOptionalInput(String name) {
    if (inputs == null || !inputs.containsKey(name)) {
      return null;
    }
    return inputs[name];
  }

  /**
   * Return the value of the input with the given [name]. Throw an exception if
   * the input value is not defined.
   */
  E getRequiredInput<E>(String name) {
    if (inputs == null || !inputs.containsKey(name)) {
      throw new AnalysisException("Could not $description: missing $name");
    }
    if (inputs[name] is! E) {
      throw new AnalysisException(
          "Could not $description: $name is a ${inputs[name].runtimeType} rather than a $E");
    }
    return inputs[name] as E;
  }

  /**
   * Return the source associated with the target. Throw an exception if
   * the target is not associated with a source.
   */
  Source getRequiredSource() {
    Source source = target.source;
    if (source == null) {
      throw new AnalysisException("Could not $description: missing source");
    }
    return source;
  }

  /**
   * Perform this analysis task, protected by an exception handler.
   *
   * This method should throw an [AnalysisException] if an exception occurs
   * while performing the task. If other kinds of exceptions are thrown they
   * will be wrapped in an [AnalysisException].
   *
   * If no exception is thrown, this method must fully populate the [outputs]
   * map (have a key/value pair for each result that this task is expected to
   * produce).
   */
  void internalPerform();

  /**
   * Perform this analysis task. When this method returns, either the [outputs]
   * map should be fully populated (have a key/value pair for each result that
   * this task is expected to produce) or the [caughtException] should be set.
   *
   * Clients may not override this method.
   */
  void perform() {
    try {
      _safelyPerform();
    } on AnalysisException catch (exception, stackTrace) {
      caughtException = new CaughtException(exception, stackTrace);
      AnalysisEngine.instance.logger
          .logError("Task failed: $description", caughtException);
    }
  }

  @override
  String toString() => description;

  /**
   * Given a strongly connected component, find and return a list of
   * [TargetedResult]s that describes a cyclic path within the cycle.  Returns
   * null if no cyclic path is found.
   */
  List<TargetedResult> _findCyclicPath(List<WorkItem> cycle) {
    WorkItem findInCycle(AnalysisTarget target, ResultDescriptor descriptor) {
      for (WorkItem item in cycle) {
        if (target == item.target && descriptor == item.spawningResult) {
          return item;
        }
      }
      return null;
    }

    HashSet<WorkItem> active = new HashSet<WorkItem>();
    List<TargetedResult> path = null;
    bool traverse(WorkItem item) {
      if (!active.add(item)) {
        // We've found a cycle
        path = <TargetedResult>[];
        return true;
      }
      for (TargetedResult result in item.inputTargetedResults) {
        WorkItem item = findInCycle(result.target, result.result);
        // Ignore edges that leave the cycle.
        if (item != null) {
          if (traverse(item)) {
            // This edge is in a cycle (or leads to a cycle) so add it to the
            // path
            path.add(result);
            return true;
          }
        }
      }
      // There was no cycle.
      return false;
    }

    if (cycle.length > 0) {
      traverse(cycle[0]);
    }
    return path;
  }

  /**
   * Perform this analysis task, ensuring that all exceptions are wrapped in an
   * [AnalysisException].
   *
   * Clients may not override this method.
   */
  void _safelyPerform() {
    try {
      //
      // Store task description for diagnostics.
      //
      LAST_TASKS.add(description);

      //
      // Report that this task is being performed.
      //
      String contextName = context.name;
      if (contextName == null) {
        contextName = 'unnamed';
      }
      AnalysisEngine.instance.instrumentationService
          .logAnalysisTask(contextName, this);
      //
      // Gather statistics on the performance of the task.
      //
      int count = countMap[runtimeType];
      countMap[runtimeType] = count == null ? 1 : count + 1;
//      UserTag tag = tagMap.putIfAbsent(
//          runtimeType, () => new UserTag(runtimeType.toString()));
      Stopwatch stopwatch = stopwatchMap[runtimeType];
      if (stopwatch == null) {
        stopwatch = new Stopwatch();
        stopwatchMap[runtimeType] = stopwatch;
      }
//      UserTag previousTag = tag.makeCurrent();
//      try {
      stopwatch.start();
      //
      // Actually perform the task.
      //
      try {
        if (dependencyCycle != null && !handlesDependencyCycles) {
          throw new InfiniteTaskLoopException(
              this, dependencyCycle, _findCyclicPath(dependencyCycle));
        }
        internalPerform();
      } finally {
        stopwatch.stop();
      }
//      } finally {
//        previousTag.makeCurrent();
//      }
    } on AnalysisException {
      rethrow;
    } on ModificationTimeMismatchError {
      rethrow;
    } catch (exception, stackTrace) {
      throw new AnalysisException(
          'Unexpected exception while performing $description',
          new CaughtException(exception, stackTrace));
    }
  }
}

/**
 * A description of a [List]-based analysis result that can be computed by an
 * [AnalysisTask].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ListResultDescriptor<E> implements ResultDescriptor<List<E>> {
  /**
   * Initialize a newly created analysis result to have the given [name] and
   * [defaultValue]. If a [cachingPolicy] is provided, it will control how long
   * values associated with this result will remain in the cache.
   */
  factory ListResultDescriptor(String name, List<E> defaultValue,
      {ResultCachingPolicy cachingPolicy}) = ListResultDescriptorImpl<E>;

  @override
  ListTaskInput<E> of(AnalysisTarget target, {bool flushOnAccess: false});
}

/**
 * A description of an input to an [AnalysisTask] that can be used to compute
 * that input.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ListTaskInput<E> implements TaskInput<List<E>> {
  /**
   * Return a task input that can be used to compute a flatten list whose
   * elements are combined [subListResult]'s associated with those elements.
   */
  ListTaskInput<V> toFlattenListOf<V>(ListResultDescriptor<V> subListResult);

  /**
   * Return a task input that can be used to compute a list whose elements are
   * the result of passing the elements of this input to the [mapper] function.
   */
  ListTaskInput<V> toList<V>(UnaryFunction<E, V> mapper);

  /**
   * Return a task input that can be used to compute a list whose elements are
   * [valueResult]'s associated with those elements.
   */
  ListTaskInput<V> toListOf<V>(ResultDescriptor<V> valueResult);

  /**
   * Return a task input that can be used to compute a map whose keys are the
   * elements of this input and whose values are the result of passing the
   * corresponding key to the [mapper] function.
   */
  MapTaskInput<E, V> toMap<V>(UnaryFunction<E, V> mapper);

  /**
   * Return a task input that can be used to compute a map whose keys are the
   * elements of this input and whose values are the [valueResult]'s associated
   * with those elements.
   */
  MapTaskInput<AnalysisTarget, V> toMapOf<V>(ResultDescriptor<V> valueResult);
}

/**
 * A description of an input with a [Map] based values.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MapTaskInput<K, V> implements TaskInput<Map<K, V>> {
  /**
   * [V] must be a [List].
   * Return a task input that can be used to compute a list whose elements are
   * the result of passing keys [K] and the corresponding elements of [V] to
   * the [mapper] function.
   */
  TaskInput<List<E>> toFlattenList<E>(
      BinaryFunction<K, dynamic /*element of V*/, E> mapper);
}

/**
 * Instances of this class are thrown when a task detects that the modification
 * time of a cache entry is not the same as the actual modification time.  This
 * means that any analysis results based on the content of the target cannot be
 * used anymore and must be invalidated.
 */
class ModificationTimeMismatchError {
  final Source source;

  ModificationTimeMismatchError(this.source);
}

/**
 * A policy object that can compute sizes of results and provide the maximum
 * active and idle sizes that can be kept in the cache.
 *
 * All the [ResultDescriptor]s with the same [ResultCachingPolicy] instance
 * share the same total size in a cache.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class ResultCachingPolicy {
  /**
   * Return the maximum total size of results that can be kept in the cache
   * while analysis is in progress.
   */
  int get maxActiveSize;

  /**
   * Return the maximum total size of results that can be kept in the cache
   * while analysis is idle.
   */
  int get maxIdleSize;

  /**
   * Return the size of the given [object].
   */
  int measure(Object object);
}

/**
 * A description of an analysis result that can be computed by an [AnalysisTask].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ResultDescriptor<V> {
  /**
   * A comparator that can be used to sort result descriptors by their name.
   */
  static final Comparator<ResultDescriptor> SORT_BY_NAME =
      (ResultDescriptor first, ResultDescriptor second) =>
          first.name.compareTo(second.name);

  /**
   * Initialize a newly created analysis result to have the given [name] and
   * [defaultValue].
   *
   * The given [cachingPolicy] is used to limit the total size of results
   * described by this descriptor. If no policy is specified, the results are
   * never evicted from the cache, and removed only when they are invalidated.
   */
  factory ResultDescriptor(String name, V defaultValue,
      {ResultCachingPolicy cachingPolicy}) = ResultDescriptorImpl<V>;

  /**
   * Return the caching policy for results described by this descriptor.
   */
  ResultCachingPolicy get cachingPolicy;

  /**
   * Return the default value for results described by this descriptor.
   */
  V get defaultValue;

  /**
   * Return the name of this descriptor.
   */
  String get name;

  /**
   * Return a task input that can be used to compute this result for the given
   * [target]. If [flushOnAccess] is `true` then the value of this result that
   * is associated with the [target] will be flushed when it is accessed.
   */
  TaskInput<V> of(AnalysisTarget target, {bool flushOnAccess: false});
}

/**
 * A specification of the given [result] for the given [target].
 *
 * Clients may not extend, implement or mix-in this class.
 */
class TargetedResult {
  /**
   * An empty list of results.
   */
  static final List<TargetedResult> EMPTY_LIST = const <TargetedResult>[];

  /**
   * The target with which the result is associated.
   */
  final AnalysisTarget target;

  /**
   * The result associated with the target.
   */
  final ResultDescriptor result;

  /**
   * Initialize a new targeted result.
   */
  TargetedResult(this.target, this.result);

  @override
  int get hashCode {
    return JenkinsSmiHash.combine(target.hashCode, result.hashCode);
  }

  @override
  bool operator ==(other) {
    return other is TargetedResult &&
        other.target == target &&
        other.result == result;
  }

  @override
  String toString() => '$result for $target';
}

/**
 * A description of an [AnalysisTask].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TaskDescriptor {
  /**
   * Initialize a newly created task descriptor to have the given [name] and to
   * describe a task that takes the inputs built using the given [inputBuilder],
   * and produces the given [results]. The [buildTask] function will be used to
   * create the instance of [AnalysisTask] being described. If provided, the
   * [isAppropriateFor] function will be used to determine whether the task can
   * be used on a specific target.
   */
  factory TaskDescriptor(String name, BuildTask buildTask,
      CreateTaskInputs inputBuilder, List<ResultDescriptor> results,
      {SuitabilityFor suitabilityFor}) = TaskDescriptorImpl;

  /**
   * Return the builder used to build the inputs to the task.
   */
  CreateTaskInputs get createTaskInputs;

  /**
   * Return the name of the task being described.
   */
  String get name;

  /**
   * Return a list of the analysis results that will be computed by this task.
   */
  List<ResultDescriptor> get results;

  /**
   * Create and return a task that is described by this descriptor that can be
   * used to compute results based on the given [inputs].
   */
  AnalysisTask createTask(AnalysisContext context, AnalysisTarget target,
      Map<String, dynamic> inputs);

  /**
   * Return an indication of how suitable this task is for the given [target].
   */
  TaskSuitability suitabilityFor(AnalysisTarget target);
}

/**
 * A description of an input to an [AnalysisTask] that can be used to compute
 * that input.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TaskInput<V> {
  /**
   * Create and return a builder that can be used to build this task input.
   */
  TaskInputBuilder<V> createBuilder();

  /**
   * Return a task input that can be used to compute a list whose elements are
   * the result of passing the result of this input to the [mapper] function.
   */
  ListTaskInput<E> mappedToList<E>(List<E> mapper(V value));
}

/**
 * An object used to build the value associated with a single [TaskInput].
 *
 * All builders work by requesting one or more results (each result being
 * associated with a target). The interaction pattern is modeled after the class
 * [Iterator], in which the method [moveNext] is invoked to move from one result
 * request to the next. The getters [currentResult] and [currentTarget] are used
 * to get the result and target of the current request. The value of the result
 * must be supplied using the [currentValue] setter before [moveNext] can be
 * invoked to move to the next request. When [moveNext] returns `false`,
 * indicating that there are no more requests, the method [inputValue] can be
 * used to access the value of the input that was built.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TaskInputBuilder<V> {
  /**
   * Return the result that needs to be computed, or `null` if [moveNext] has
   * not been invoked or if the last invocation of [moveNext] returned `false`.
   */
  ResultDescriptor get currentResult;

  /**
   * Return the target for which the result needs to be computed, or `null` if
   * [moveNext] has not been invoked or if the last invocation of [moveNext]
   * returned `false`.
   */
  AnalysisTarget get currentTarget;

  /**
   * Set the [value] that was computed for the current result.
   *
   * Throws a [StateError] if [moveNext] has not been invoked or if the last
   * invocation of [moveNext] returned `false`.
   */
  void set currentValue(Object value);

  /**
   * Return `true` if the value accessed by this input builder should be flushed
   * from the cache at the time it is retrieved.
   */
  bool get flushOnAccess;

  /**
   * Return the [value] that was computed by this builder.
   *
   * Throws a [StateError] if [moveNext] has not been invoked or if the last
   * invocation of [moveNext] returned `true`.
   *
   * Returns `null` if no value could be computed due to a circular dependency.
   */
  V get inputValue;

  /**
   * Record that no value is available for the current result, due to a
   * circular dependency.
   *
   * Throws a [StateError] if [moveNext] has not been invoked or if the last
   * invocation of [moveNext] returned `false`.
   */
  void currentValueNotAvailable();

  /**
   * Move to the next result that needs to be computed in order to build the
   * inputs for a task. Return `true` if there is another result that needs to
   * be computed, or `false` if the inputs have been computed.
   *
   * It is safe to invoke [moveNext] after it has returned `false`. In this case
   * [moveNext] has no effect and will again return `false`.
   *
   * Throws a [StateError] if the value of the current result has not been
   * provided using [currentValue].
   */
  bool moveNext();
}

/**
 * An indication of how suitable a task is for a given target.
 */
enum TaskSuitability { NONE, LOWEST, HIGHEST }

/**
 * [WorkManager]s are used to drive analysis.
 *
 * They know specific of the targets and results they care about,
 * so they can request analysis results in optimal order.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class WorkManager {
  /**
   * Notifies the manager about changes in the explicit source list.
   */
  void applyChange(List<Source> addedSources, List<Source> changedSources,
      List<Source> removedSources);

  /**
   * Notifies the managers that the given set of priority [targets] was set.
   */
  void applyPriorityTargets(List<AnalysisTarget> targets);

  /**
   * Return a list of all of the errors associated with the given [source].
   * The list of errors will be empty if the source is not known to the context
   * or if there are no errors in the source. The errors contained in the list
   * can be incomplete.
   */
  List<AnalysisError> getErrors(Source source);

  /**
   * Return the next [TargetedResult] that this work manager wants to be
   * computed, or `null` if this manager doesn't need any new results.
   *
   * Note, that it is not guaranteed that this result will be computed, it is
   * up to the work manager to check whether the result is already computed
   * (for example during the next [getNextResult] invocation) or computation
   * of the same result should be requested again.
   */
  TargetedResult getNextResult();

  /**
   * Return the priority if the next work order this work manager want to be
   * computed. The [AnalysisDriver] will perform the work order with
   * the highest priority.
   *
   * Even if the returned value is [WorkOrderPriority.NONE], it still does not
   * guarantee that [getNextResult] will return not `null`.
   */
  WorkOrderPriority getNextResultPriority();

  /**
   * Notifies the manager about analysis options changes.
   */
  void onAnalysisOptionsChanged();

  /**
   * Notifies the manager about [SourceFactory] changes.
   */
  void onSourceFactoryChanged();

  /**
   * Notifies the manager that the given [outputs] were produced for
   * the given [target].
   */
  void resultsComputed(
      AnalysisTarget target, Map<ResultDescriptor, dynamic> outputs);
}

/**
 * The priorities of work orders returned by [WorkManager]s.
 *
 * New priorities may be added with time, clients need to tolerate this.
 */
enum WorkOrderPriority {
  /**
   * Responding to an user's action.
   */
  INTERACTIVE,

  /**
   * Computing information for priority sources.
   */
  PRIORITY,

  /**
   * A work should be done, but without any special urgency.
   */
  NORMAL,

  /**
   * Nothing to do.
   */
  NONE
}
