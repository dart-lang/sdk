// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.task.model;

import 'dart:collection';

import 'package:analyzer/src/generated/engine.dart' hide AnalysisTask;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/model.dart';

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
  Source get source => null;
}

/**
 * An object with which an analysis result can be associated.
 *
 * Clients are allowed to subtype this class when creating new kinds of targets.
 * Instances of this type are used in hashed data structures, so subtypes are
 * required to correctly implement [==] and [hashCode].
 */
abstract class AnalysisTarget {
  /**
   * Return the source associated with this target, or `null` if this target is
   * not associated with a source.
   */
  Source get source;
}

/**
 * An object used to compute one or more analysis results associated with a
 * single target.
 *
 * Clients are expected to extend this class when creating new tasks.
 */
abstract class AnalysisTask {
  /**
   * A table mapping the types of analysis tasks to the number of times each
   * kind of task has been performed.
   */
  static final Map<Type, int> countMap = new HashMap<Type, int>();

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
   * Return the value of the input with the given [name]. Throw an exception if
   * the input value is not defined.
   */
  Object getRequiredInput(String name) {
    if (inputs == null || !inputs.containsKey(name)) {
      throw new AnalysisException("Could not $description: missing $name");
    }
    return inputs[name];
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
   * Clients should not override this method.
   */
  void perform() {
    try {
      _safelyPerform();
    } on AnalysisException catch (exception, stackTrace) {
      caughtException = new CaughtException(exception, stackTrace);
      AnalysisEngine.instance.logger.logInformation(
          "Task failed: ${description}", caughtException);
    }
  }

  @override
  String toString() => description;

  /**
   * Perform this analysis task, ensuring that all exceptions are wrapped in an
   * [AnalysisException].
   *
   * Clients should not override this method.
   */
  void _safelyPerform() {
    try {
      //
      // Report that this task is being performed.
      //
      String contextName = context.name;
      if (contextName == null) {
        contextName = 'unnamed';
      }
      AnalysisEngine.instance.instrumentationService.logAnalysisTask(
          contextName, description);
      //
      // Gather statistics on the performance of the task.
      //
      int count = countMap[runtimeType];
      countMap[runtimeType] = count == null ? 1 : count + 1;
      Stopwatch stopwatch = stopwatchMap[runtimeType];
      if (stopwatch == null) {
        stopwatch = new Stopwatch();
        stopwatchMap[runtimeType] = stopwatch;
      }
      stopwatch.start();
      //
      // Actually perform the task.
      //
      try {
        internalPerform();
      } finally {
        stopwatch.stop();
      }
    } on AnalysisException {
      rethrow;
    } catch (exception, stackTrace) {
      throw new AnalysisException(
          'Unexpected exception while performing $description',
          new CaughtException(exception, stackTrace));
    }
  }
}

/**
 * A [ResultDescriptor] that denotes an analysis result that is a union of
 * one or more other results.
 *
 * Clients are not expected to subtype this class.
 */
abstract class CompositeResultDescriptor<V> extends ResultDescriptor<V> {
  /**
   * Initialize a newly created composite result to have the given [name].
   */
  factory CompositeResultDescriptor(
      String name) = CompositeResultDescriptorImpl;

  /**
   * Return a list containing the descriptors of the results that are unioned
   * together to compose the value of this result.
   *
   * Clients must not modify the returned list.
   */
  List<ResultDescriptor<V>> get contributors;
}

/**
 * A description of a [List]-based analysis result that can be computed by an
 * [AnalysisTask].
 *
 * Clients are not expected to subtype this class.
 */
abstract class ListResultDescriptor<E> implements ResultDescriptor<List<E>> {
  /**
   * Initialize a newly created analysis result to have the given [name]. If a
   * composite result is specified, then this result will contribute to it.
   */
  factory ListResultDescriptor(String name, List<E> defaultValue,
      {CompositeResultDescriptor<List<E>> contributesTo}) = ListResultDescriptorImpl<E>;

  @override
  ListTaskInput<E> of(AnalysisTarget target);
}

/**
 * A description of an input to an [AnalysisTask] that can be used to compute
 * that input.
 *
 * Clients are not expected to subtype this class.
 */
abstract class ListTaskInput<E> extends TaskInput<List<E>> {
  /**
   * Return a task input that can be used to compute a list whose elements are
   * the result of passing the elements of this input to the [mapper] function.
   */
  ListTaskInput /*<V>*/ toList(UnaryFunction<E, dynamic /*<V>*/ > mapper);

  /**
   * Return a task input that can be used to compute a list whose elements are
   * [valueResult]'s associated with those elements.
   */
  ListTaskInput /*<V>*/ toListOf(ResultDescriptor /*<V>*/ valueResult);

  /**
   * Return a task input that can be used to compute a map whose keys are the
   * elements of this input and whose values are the result of passing the
   * corresponding key to the [mapper] function.
   */
  MapTaskInput<E, dynamic /*V*/ > toMap(
      UnaryFunction<E, dynamic /*<V>*/ > mapper);

  /**
   * Return a task input that can be used to compute a map whose keys are the
   * elements of this input and whose values are the [valueResult]'s associated
   * with those elements.
   */
  MapTaskInput<AnalysisTarget, dynamic /*V*/ > toMapOf(
      ResultDescriptor /*<V>*/ valueResult);
}

/**
 * A description of an input with a [Map] based values.
 *
 * Clients are not expected to subtype this class.
 */
abstract class MapTaskInput<K, V> extends TaskInput<Map<K, V>> {
  /**
   * [V] must be a [List].
   * Return a task input that can be used to compute a list whose elements are
   * the result of passing keys [K] and the corresponding elements of [V] to
   * the [mapper] function.
   */
  TaskInput<List /*<E>*/ > toFlattenList(
      BinaryFunction<K, dynamic /*element of V*/, dynamic /*<E>*/ > mapper);
}

/**
 * A description of an analysis result that can be computed by an [AnalysisTask].
 *
 * Clients are not expected to subtype this class.
 */
abstract class ResultDescriptor<V> {
  /**
   * Initialize a newly created analysis result to have the given [name]. If a
   * composite result is specified, then this result will contribute to it.
   */
  factory ResultDescriptor(String name, V defaultValue,
      {CompositeResultDescriptor<V> contributesTo}) = ResultDescriptorImpl;

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
   * [target].
   */
  TaskInput<V> of(AnalysisTarget target);
}

/**
 * A description of an [AnalysisTask].
 */
abstract class TaskDescriptor {
  /**
   * Initialize a newly created task descriptor to have the given [name] and to
   * describe a task that takes the inputs built using the given [inputBuilder],
   * and produces the given [results]. The [buildTask] will be used to create
   * the instance of [AnalysisTask] thusly described.
   */
  factory TaskDescriptor(String name, BuildTask buildTask,
      CreateTaskInputs inputBuilder,
      List<ResultDescriptor> results) = TaskDescriptorImpl;

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
}

/**
 * A description of an input to an [AnalysisTask] that can be used to compute
 * that input.
 *
 * Clients are not expected to subtype this class.
 */
abstract class TaskInput<V> {
  /**
   * Create and return a builder that can be used to build this task input.
   */
  TaskInputBuilder<V> createBuilder();
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
 * Clients are not expected to subtype this class.
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
   * Return the [value] that was computed by this builder.
   *
   * Throws a [StateError] if [moveNext] has not been invoked or if the last
   * invocation of [moveNext] returned `true`.
   */
  V get inputValue;

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
