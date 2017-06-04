// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.driver;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/task/inputs.dart';
import 'package:analyzer/src/task/manager.dart';
import 'package:analyzer/task/model.dart';

final PerformanceTag _taskDriverTag =
    PerformanceStatistics.analyzer.createChild('taskDriver');

final PerformanceTag analysisDriverProcessOutputs =
    _taskDriverTag.createChild('processOutputs');

final PerformanceTag workOrderMoveNextPerformanceTag =
    _taskDriverTag.createChild('workOrderMoveNext');

/**
 * An object that is used to cause analysis to be performed until all of the
 * required analysis information has been computed.
 */
class AnalysisDriver {
  /**
   * The task manager used to figure out how to compute analysis results.
   */
  final TaskManager taskManager;

  /**
   * The list of [WorkManager] used to figure out which analysis results to
   * compute.
   */
  final List<WorkManager> workManagers;

  /**
   * The context in which analysis is to be performed.
   */
  final InternalAnalysisContext context;

  /**
   * The map of [ResultChangedEvent] controllers.
   */
  final Map<ResultDescriptor, StreamController<ResultChangedEvent>>
      resultComputedControllers =
      <ResultDescriptor, StreamController<ResultChangedEvent>>{};

  /**
   * The work order that was previously computed but that has not yet been
   * completed.
   */
  WorkOrder currentWorkOrder;

  /**
   * Indicates whether any tasks are currently being performed (or building
   * their inputs).  In debug builds, we use this to ensure that tasks don't
   * try to make use of the task manager in reentrant fashion.
   */
  bool isTaskRunning = false;

  /**
   * The controller that is notified when a task is started.
   */
  StreamController<AnalysisTask> _onTaskStartedController;

  /**
   * The controller that is notified when a task is complete.
   */
  StreamController<AnalysisTask> _onTaskCompletedController;

  /**
   * Initialize a newly created driver to use the tasks know to the given
   * [taskManager] to perform analysis in the given [context].
   */
  AnalysisDriver(this.taskManager, this.workManagers, this.context) {
    _onTaskStartedController = new StreamController.broadcast();
    _onTaskCompletedController = new StreamController.broadcast();
  }

  /**
   * The stream that is notified when a task is complete.
   */
  Stream<AnalysisTask> get onTaskCompleted => _onTaskCompletedController.stream;

  /**
   * The stream that is notified when a task is started.
   */
  Stream<AnalysisTask> get onTaskStarted => _onTaskStartedController.stream;

  /**
   * Perform work until the given [result] has been computed for the given
   * [target]. Return the last [AnalysisTask] that was performed.
   */
  AnalysisTask computeResult(AnalysisTarget target, ResultDescriptor result) {
    assert(!isTaskRunning);
    try {
      isTaskRunning = true;
      AnalysisTask task;
      while (true) {
        try {
          WorkOrder workOrder = createWorkOrderForResult(target, result);
          if (workOrder != null) {
            while (workOrder.moveNext()) {
              task = performWorkItem(workOrder.current);
            }
          }
          break;
        } on ModificationTimeMismatchError {
          // Cache inconsistency was detected and fixed by invalidating
          // corresponding results in cache. Computation must be restarted.
        }
      }
      return task;
    } finally {
      isTaskRunning = false;
    }
  }

  /**
   * Return the work order describing the work that should be getting worked on,
   * or `null` if there is currently no work to be done.
   */
  WorkOrder createNextWorkOrder() {
    while (true) {
      // Find the WorkManager with the highest priority.
      WorkOrderPriority highestPriority = null;
      WorkManager highestManager = null;
      for (WorkManager manager in workManagers) {
        WorkOrderPriority priority = manager.getNextResultPriority();
        if (highestPriority == null || highestPriority.index > priority.index) {
          highestPriority = priority;
          highestManager = manager;
        }
      }
      // Nothing to do.
      if (highestPriority == WorkOrderPriority.NONE) {
        return null;
      }
      // Create a new WorkOrder.
      TargetedResult request = highestManager.getNextResult();
//      print('request: $request');
      if (request != null) {
        WorkOrder workOrder =
            createWorkOrderForResult(request.target, request.result);
        if (workOrder != null) {
          return workOrder;
        }
      }
    }
  }

  /**
   * Create a work order that will produce the given [result] for the given
   * [target]. Return the work order that was created, or `null` if the result
   * has either already been computed or cannot be computed.
   */
  WorkOrder createWorkOrderForResult(
      AnalysisTarget target, ResultDescriptor result) {
    CacheEntry entry = context.getCacheEntry(target);
    CacheState state = entry.getState(result);
    if (state == CacheState.VALID ||
        state == CacheState.ERROR ||
        state == CacheState.IN_PROCESS) {
      return null;
    }
    if (context.aboutToComputeResult(entry, result)) {
      return null;
    }
    TaskDescriptor taskDescriptor = taskManager.findTask(target, result);
    if (taskDescriptor == null) {
      return null;
    }
    try {
      WorkItem workItem =
          new WorkItem(context, target, taskDescriptor, result, 0, null);
      return new WorkOrder(taskManager, workItem);
    } catch (exception, stackTrace) {
      throw new AnalysisException(
          'Could not create work order (target = $target; taskDescriptor = $taskDescriptor; result = $result)',
          new CaughtException(exception, stackTrace));
    }
  }

  /**
   * Create a work order that will produce the required analysis results for
   * the given [target]. If [isPriority] is true, then the target is a priority
   * target. Return the work order that was created, or `null` if there is no
   * further work that needs to be done for the given target.
   */
  WorkOrder createWorkOrderForTarget(AnalysisTarget target, bool isPriority) {
    for (ResultDescriptor result in taskManager.generalResults) {
      WorkOrder workOrder = createWorkOrderForResult(target, result);
      if (workOrder != null) {
        return workOrder;
      }
    }
    if (isPriority) {
      for (ResultDescriptor result in taskManager.priorityResults) {
        WorkOrder workOrder = createWorkOrderForResult(target, result);
        if (workOrder != null) {
          return workOrder;
        }
      }
    }
    return null;
  }

  /**
   * Return the stream that is notified when a new value for the given
   * [descriptor] is computed.
   */
  Stream<ResultChangedEvent> onResultComputed(ResultDescriptor descriptor) {
    return resultComputedControllers.putIfAbsent(descriptor, () {
      return new StreamController<ResultChangedEvent>.broadcast(sync: true);
    }).stream;
  }

  /**
   * Perform the next analysis task, and return `true` if there is more work to
   * be done in order to compute all of the required analysis information.
   */
  bool performAnalysisTask() {
    //
    // TODO(brianwilkerson) This implementaiton does not allow us to prioritize
    // work across contexts. What we need is a way for an external client to ask
    // to have all priority files analyzed for each context, then ask for normal
    // files to be analyzed. There are a couple of ways to do this.
    //
    // First, we could add a "bool priorityOnly" parameter to this method and
    // return null here when it is true.
    //
    // Second, we could add a concept of a priority order and (externally) run
    // through the priorities from highest to lowest. That would be a nice
    // generalization of the previous idea, but it isn't clear that we need the
    // generality.
    //
    // Third, we could move performAnalysisTask and createNextWorkOrder to an
    // object that knows about all sources in all contexts, so that instead of
    // the client choosing a context and telling it do to some work, the client
    // simply says "do some work", and the engine chooses the best thing to do
    // next regardless of what context it's in.
    //
    assert(!isTaskRunning);
    try {
      isTaskRunning = true;
      if (currentWorkOrder == null) {
        currentWorkOrder = createNextWorkOrder();
      } else if (currentWorkOrder.moveNext()) {
        try {
          performWorkItem(currentWorkOrder.current);
        } on ModificationTimeMismatchError {
          reset();
          return true;
        }
      } else {
        currentWorkOrder = createNextWorkOrder();
      }
      return currentWorkOrder != null;
    } finally {
      isTaskRunning = false;
    }
  }

  /**
   * Perform the given work item.
   * Return the performed [AnalysisTask].
   */
  AnalysisTask performWorkItem(WorkItem item) {
    if (item.exception != null) {
      // Mark all of the results that the task would have computed as being in
      // ERROR with the exception recorded on the work item.
      CacheEntry targetEntry = context.getCacheEntry(item.target);
      targetEntry.setErrorState(item.exception, item.descriptor.results);
      return null;
    }
    // Otherwise, perform the task.
    AnalysisTask task = item.buildTask();
    _onTaskStartedController.add(task);
    task.perform();
    analysisDriverProcessOutputs.makeCurrentWhile(() {
      AnalysisTarget target = task.target;
      CacheEntry entry = context.getCacheEntry(target);
      if (task.caughtException == null) {
        List<TargetedResult> dependedOn =
            context.analysisOptions.trackCacheDependencies
                ? item.inputTargetedResults.toList()
                : const <TargetedResult>[];
        Map<ResultDescriptor, dynamic> outputs = task.outputs;
        List<ResultDescriptor> results = task.descriptor.results;
        int resultLength = results.length;
        for (int i = 0; i < resultLength; i++) {
          ResultDescriptor result = results[i];
          // TODO(brianwilkerson) We could check here that a value was produced
          // and throw an exception if not (unless we want to allow null values).
          entry.setValue(result, outputs[result], dependedOn);
        }
        outputs.forEach((ResultDescriptor descriptor, value) {
          StreamController<ResultChangedEvent> controller =
              resultComputedControllers[descriptor];
          if (controller != null) {
            ResultChangedEvent event = new ResultChangedEvent(
                context, target, descriptor, value, true);
            controller.add(event);
          }
        });
        for (WorkManager manager in workManagers) {
          manager.resultsComputed(target, outputs);
        }
      } else {
        entry.setErrorState(task.caughtException, item.descriptor.results);
      }
    });
    _onTaskCompletedController.add(task);
    return task;
  }

  /**
   * Reset the state of the driver in response to a change in the state of one
   * or more analysis targets. This will cause any analysis that was currently
   * in process to be stopped and for analysis to resume based on the new state.
   */
  void reset() {
    currentWorkOrder = null;
  }
}

/**
 * Generic dependency walker suitable for use in the analysis task driver.
 * This class implements a variant of the path-based strong component algorithm
 * (described here: http://www.cs.colorado.edu/~hal/Papers/DFS/ipl.ps.gz), with
 * the following differences:
 *
 * - The algorithm is non-recursive so that it can be used in a coroutine
 *   fashion (each call to [getNextStronglyConnectedComponent] computes a
 *   single strongly connected component and then waits to be called again)
 *
 * - Instead of keeping a temporary array which maps nodes to their locations
 *   in the [path] array, we simply search the array when necessary.  This
 *   allows us to begin finding strongly connected components without having to
 *   know the size of the whole graph.
 *
 * - This algorithm does not compute all strongly connected components; only
 *   those reachable from the starting point which are as yet unevaluated.
 *
 * The algorithm, in essence, is to traverse the dependency graph in
 * depth-first fashion from a starting node.  If the path from the starting
 * node ever encounters the same node twice, then a cycle has been found, and
 * all the nodes comprising the cycle are (conceptually) contracted into a
 * single node.  The algorithm yields possibly-collapsed nodes in proper
 * topological sort order (all the dependencies of a node are yielded before,
 * or in the same contracted component as, the node itself).
 */
abstract class CycleAwareDependencyWalker<Node> {
  /**
   * The path through the dependency graph that is currently being considered,
   * with un-collapsed nodes.
   */
  final List<Node> _path;

  /**
   * For each node in [_path], a list of the unevaluated nodes which it is
   * already known to depend on.
   */
  final List<List<Node>> _provisionalDependencies;

  /**
   * Indices into [_path] of the nodes which begin a new strongly connected
   * component, in order.  The first index in [_contractedPath] is always 0.
   *
   * For all i < contractedPath.length - 1, at least one node in the strongly
   * connected component represented by [contractedPath[i]] depends directly
   * on at least one node in the strongly connected component represented by
   * [contractedPath[i+1]].
   */
  final List<int> _contractedPath;

  /**
   * Index into [_path] of the nodes which we are currently in the process of
   * querying for their dependencies.
   *
   * [currentIndices.last] always refers to a member of the last strongly
   * connected component indicated by [_contractedPath].
   */
  final List<int> _currentIndices;

  /**
   * Begin walking dependencies starting at [startingNode].
   */
  CycleAwareDependencyWalker(Node startingNode)
      : _path = <Node>[startingNode],
        _provisionalDependencies = <List<Node>>[<Node>[]],
        _contractedPath = <int>[0],
        _currentIndices = <int>[0];

  /**
   * Determine the next unevaluated input for [node], skipping any inputs in
   * [skipInputs], and return it.  If [node] has no further inputs, return
   * `null`.
   */
  Node getNextInput(Node node, List<Node> skipInputs);

  /**
   * Determine the next strongly connected component in the graph, and return
   * it.  The client is expected to evaluate this component before calling
   * [getNextStronglyConnectedComponent] again.
   */
  StronglyConnectedComponent<Node> getNextStronglyConnectedComponent() {
    while (_currentIndices.isNotEmpty) {
      Node nextUnevaluatedInput = getNextInput(_path[_currentIndices.last],
          _provisionalDependencies[_currentIndices.last]);
      // If the assertion below fails, it indicates that [getNextInput] did not
      // skip an input that we asked it to skip.
      assert(!_provisionalDependencies[_currentIndices.last]
          .contains(nextUnevaluatedInput));
      if (nextUnevaluatedInput != null) {
        // TODO(paulberry): the call to _path.indexOf makes the algorithm
        // O(n^2) in the depth of the dependency graph.  If this becomes a
        // problem, consider maintaining a map from node to index.
        int previousIndex = _path.indexOf(nextUnevaluatedInput);
        if (previousIndex != -1) {
          // Update contractedPath to indicate that all nodes in the path
          // between previousIndex and currentIndex are part of the same
          // strongly connected component.
          while (_contractedPath.last > previousIndex) {
            _contractedPath.removeLast();
          }
          // Store nextUnevaluatedInput as a provisional dependency so that we
          // can move on to computing other dependencies.
          _provisionalDependencies[_currentIndices.last]
              .add(nextUnevaluatedInput);
          // And loop to move on to the node's next input.
          continue;
        } else {
          // This is a brand new input and there's no reason (yet) to believe
          // that it is in the same strongly connected component as any other
          // node, so push it onto the end of the path.
          int newIndex = _path.length;
          _path.add(nextUnevaluatedInput);
          _provisionalDependencies.add(<Node>[]);
          _contractedPath.add(newIndex);
          _currentIndices.add(newIndex);
          // And loop to move on to the new node's inputs.
          continue;
        }
      } else {
        // The node has no more inputs.  Figure out if there are any more nodes
        // in the current strongly connected component that need to have their
        // indices examined.
        _currentIndices.removeLast();
        if (_currentIndices.isEmpty ||
            _currentIndices.last < _contractedPath.last) {
          // No more nodes in the current strongly connected component need to
          // have their indices examined.  We can now yield this component to
          // the caller.
          List<Node> nodes = _path.sublist(_contractedPath.last);
          bool containsCycle = nodes.length > 1;
          if (!containsCycle) {
            if (_provisionalDependencies.last.isNotEmpty) {
              containsCycle = true;
            }
          }
          _path.length = _contractedPath.last;
          _provisionalDependencies.length = _contractedPath.last;
          _contractedPath.removeLast();
          return new StronglyConnectedComponent<Node>(nodes, containsCycle);
        } else {
          // At least one node in the current strongly connected component
          // still needs to have its inputs examined.  So loop and allow the
          // inputs to be examined.
          continue;
        }
      }
    }
    // No further strongly connected components found.
    return null;
  }
}

/**
 * A place to define the behaviors that need to be added to
 * [InternalAnalysisContext].
 */
abstract class ExtendedAnalysisContext implements InternalAnalysisContext {
  List<AnalysisTarget> get explicitTargets;
  List<AnalysisTarget> get priorityTargets;
  void set typeProvider(TypeProvider typeProvider);
  CacheEntry getCacheEntry(AnalysisTarget target);
}

/**
 * An exception indicating that an attempt was made to perform a task on a
 * target while gathering the inputs to perform the same task for the same
 * target.
 */
class InfiniteTaskLoopException extends AnalysisException {
  /**
   * A concrete cyclic path of [TargetedResults] within the [dependencyCycle],
   * `null` if no such path exists.  All nodes in the path are in the
   * dependencyCycle, but the path is not guaranteed to cover the
   * entire cycle.
   */
  final List<TargetedResult> cyclicPath;

  /**
   * If a dependency cycle was found while computing the inputs for the task,
   * the set of [WorkItem]s contained in the cycle (if there are overlapping
   * cycles, this is the set of all [WorkItem]s in the entire strongly
   * connected component).  Otherwise, `null`.
   */
  final List<WorkItem> dependencyCycle;

  /**
   * Initialize a newly created exception to represent a failed attempt to
   * perform the given [task] due to the given [dependencyCycle].
   */
  InfiniteTaskLoopException(AnalysisTask task, List<WorkItem> dependencyCycle,
      [List<TargetedResult> cyclicPath])
      : this.dependencyCycle = dependencyCycle,
        this.cyclicPath = cyclicPath,
        super(_composeMessage(task, dependencyCycle, cyclicPath));

  /**
   * Compose an error message based on the data we have available.
   */
  static String _composeMessage(AnalysisTask task,
      List<WorkItem> dependencyCycle, List<TargetedResult> cyclicPath) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Infinite loop while performing task ');
    buffer.write(task.descriptor.name);
    buffer.write(' for ');
    buffer.writeln(task.target);
    buffer.writeln('  Dependency Cycle:');
    for (WorkItem item in dependencyCycle) {
      buffer.write('    ');
      buffer.writeln(item);
    }
    if (cyclicPath != null) {
      buffer.writeln('  Cyclic Path:');
      for (TargetedResult result in cyclicPath) {
        buffer.write('    ');
        buffer.writeln(result);
      }
    }
    return buffer.toString();
  }
}

/**
 * Object used by [CycleAwareDependencyWalker] to report a single strongly
 * connected component of nodes.
 */
class StronglyConnectedComponent<Node> {
  /**
   * The nodes contained in the strongly connected component.
   */
  final List<Node> nodes;

  /**
   * Indicates whether the strongly component contains any cycles.  Note that
   * if [nodes] has multiple elements, this will always be `true`.  However, if
   * [nodes] has exactly one element, this may be either `true` or `false`
   * depending on whether the node has a dependency on itself.
   */
  final bool containsCycle;

  StronglyConnectedComponent(this.nodes, this.containsCycle);
}

/**
 * A description of a single analysis task that can be performed to advance
 * analysis.
 */
class WorkItem {
  /**
   * The context in which the task will be performed.
   */
  final InternalAnalysisContext context;

  /**
   * The target for which a task is to be performed.
   */
  final AnalysisTarget target;

  /**
   * A description of the task to be performed.
   */
  final TaskDescriptor descriptor;

  /**
   * The [ResultDescriptor] which was led to this work item being spawned.
   */
  final ResultDescriptor spawningResult;

  /**
   * The level of this item in its [WorkOrder].
   */
  final int level;

  /**
   * The work order that this item is part of, may be `null`.
   */
  WorkOrder workOrder;

  /**
   * An iterator used to iterate over the descriptors of the inputs to the task,
   * or `null` if all of the inputs have been collected and the task can be
   * created.
   */
  TopLevelTaskInputBuilder builder;

  /**
   * The [TargetedResult]s outputs of this task depends on.
   */
  final HashSet<TargetedResult> inputTargetedResults =
      new HashSet<TargetedResult>();

  /**
   * The inputs to the task that have been computed.
   */
  Map<String, dynamic> inputs = const <String, dynamic>{};

  /**
   * The exception that was found while trying to populate the inputs. If this
   * field is non-`null`, then the task cannot be performed and all of the
   * results that this task would have computed need to be marked as being in
   * ERROR with this exception.
   */
  CaughtException exception = null;

  /**
   * If a dependency cycle was found while computing the inputs for the task,
   * the set of [WorkItem]s contained in the cycle (if there are overlapping
   * cycles, this is the set of all [WorkItem]s in the entire strongly
   * connected component).  Otherwise, `null`.
   */
  List<WorkItem> dependencyCycle;

  /**
   * Initialize a newly created work item to compute the inputs for the task
   * described by the given descriptor.
   */
  WorkItem(this.context, this.target, this.descriptor, this.spawningResult,
      this.level, this.workOrder) {
    AnalysisTarget actualTarget =
        identical(target, AnalysisContextTarget.request)
            ? new AnalysisContextTarget(context)
            : target;
//    print('${'\t' * level}$spawningResult of $actualTarget');
    Map<String, TaskInput> inputDescriptors =
        descriptor.createTaskInputs(actualTarget);
    builder = new TopLevelTaskInputBuilder(inputDescriptors);
    if (!builder.moveNext()) {
      builder = null;
    }
  }

  @override
  int get hashCode =>
      JenkinsSmiHash.hash2(descriptor.hashCode, target.hashCode);

  @override
  bool operator ==(other) {
    if (other is WorkItem) {
      return this.descriptor == other.descriptor && this.target == other.target;
    } else {
      return false;
    }
  }

  /**
   * Build the task represented by this work item.
   */
  AnalysisTask buildTask() {
    if (builder != null) {
      throw new StateError("some inputs have not been computed");
    }
    AnalysisTask task = descriptor.createTask(context, target, inputs);
    task.dependencyCycle = dependencyCycle;
    return task;
  }

  /**
   * Gather all of the inputs needed to perform the task.
   *
   * If at least one of the inputs have not yet been computed, return a work
   * item that can be used to generate that input to indicate that the caller
   * should perform the returned item's task before returning to gathering
   * inputs for this item's task.
   *
   * If all of the inputs have been gathered, return `null` to indicate that the
   * client should build and perform the task. A value of `null` will also be
   * returned if some of the inputs cannot be computed and the task cannot be
   * performed. Callers can differentiate between these cases by checking the
   * [exception] field. If the field is `null`, then the task can be performed;
   * if the field is non-`null` then the task cannot be performed and all of the
   * tasks' results should be marked as being in ERROR.
   */
  WorkItem gatherInputs(TaskManager taskManager, List<WorkItem> skipInputs) {
    while (builder != null) {
      AnalysisTarget inputTarget = builder.currentTarget;
      ResultDescriptor inputResult = builder.currentResult;

      // TODO(scheglov) record information to debug
      // https://github.com/dart-lang/sdk/issues/24939
      if (inputTarget == null || inputResult == null) {
        try {
          String message =
              'Invalid input descriptor ($inputTarget, $inputResult) for $this';
          if (workOrder != null) {
            message += '\nPath:\n' + workOrder.workItems.join('|\n');
          }
          throw new AnalysisException(message);
        } catch (exception, stackTrace) {
          this.exception = new CaughtException(exception, stackTrace);
          AnalysisEngine.instance.logger
              .logError('Task failed: $this', this.exception);
        }
        return null;
      }

      inputTargetedResults.add(new TargetedResult(inputTarget, inputResult));
      CacheEntry inputEntry = context.getCacheEntry(inputTarget);
      CacheState inputState = inputEntry.getState(inputResult);
      if (inputState == CacheState.ERROR) {
        exception = inputEntry.exception;
        return null;
      } else if (inputState == CacheState.IN_PROCESS) {
        //
        // TODO(brianwilkerson) Implement this case.
        //
        // One possibility would be to return a WorkItem that would perform a
        // no-op task in order to cause us to come back to this work item on the
        // next iteration. It would be more efficient, in general, to push this
        // input onto a waiting list and proceed to the next input so that work
        // could proceed, but given that the only result that can currently be
        // IN_PROCESS is CONTENT, I don't know that it's worth the extra effort
        // to implement the general solution at this point.
        //
        throw new UnimplementedError();
      } else if (inputState != CacheState.VALID) {
        if (context.aboutToComputeResult(inputEntry, inputResult)) {
          inputState = CacheState.VALID;
          builder.currentValue = inputEntry.getValue(inputResult);
        } else {
          try {
            TaskDescriptor descriptor =
                taskManager.findTask(inputTarget, inputResult);
            if (descriptor == null) {
              throw new AnalysisException(
                  'Cannot find task to build $inputResult for $inputTarget');
            }
            if (skipInputs.any((WorkItem item) =>
                item.target == inputTarget && item.descriptor == descriptor)) {
              // This input is being skipped due to a circular dependency.  Tell
              // the builder that it's not available so we can move on to other
              // inputs.
              builder.currentValueNotAvailable();
            } else {
              return new WorkItem(context, inputTarget, descriptor, inputResult,
                  level + 1, workOrder);
            }
          } on AnalysisException catch (exception, stackTrace) {
            this.exception = new CaughtException(exception, stackTrace);
            return null;
          } catch (exception, stackTrace) {
            this.exception = new CaughtException(exception, stackTrace);
            throw new AnalysisException(
                'Cannot create work order to build $inputResult for $inputTarget',
                this.exception);
          }
        }
      } else {
        builder.currentValue = inputEntry.getValue(inputResult);
        if (builder.flushOnAccess) {
          inputEntry.setState(inputResult, CacheState.FLUSHED);
        }
      }
      if (!builder.moveNext()) {
        inputs = builder.inputValue;
        builder = null;
      }
    }
    return null;
  }

  @override
  String toString() => 'Run $descriptor on $target';
}

/**
 * A description of the work to be done to compute a desired analysis result.
 * The class implements a lazy depth-first traversal of the work item's input.
 */
class WorkOrder implements Iterator<WorkItem> {
  /**
   * The dependency walker which is being used to determine what work to do
   * next.
   */
  final _WorkOrderDependencyWalker _dependencyWalker;

  /**
   * The strongly connected component most recently returned by
   * [_dependencyWalker], minus any [WorkItem]s that the iterator has already
   * moved past.
   *
   * Null if the [_dependencyWalker] hasn't been used yet.
   */
  List<WorkItem> currentItems;

  /**
   * Initialize a newly created work order to compute the result described by
   * the given work item.
   */
  WorkOrder(TaskManager taskManager, WorkItem item)
      : _dependencyWalker = new _WorkOrderDependencyWalker(taskManager, item) {
    item.workOrder = this;
  }

  @override
  WorkItem get current {
    if (currentItems == null) {
      return null;
    } else {
      return currentItems.last;
    }
  }

  List<WorkItem> get workItems => _dependencyWalker._path;

  @override
  bool moveNext() {
    return workOrderMoveNextPerformanceTag.makeCurrentWhile(() {
      if (currentItems != null && currentItems.length > 1) {
        // Yield more items.
        currentItems.removeLast();
        return true;
      } else {
        // Get a new strongly connected component.
        StronglyConnectedComponent<WorkItem> nextStronglyConnectedComponent =
            _dependencyWalker.getNextStronglyConnectedComponent();
        if (nextStronglyConnectedComponent == null) {
          currentItems = null;
          return false;
        }
        currentItems = nextStronglyConnectedComponent.nodes;
        if (nextStronglyConnectedComponent.containsCycle) {
          // A cycle has been found.
          for (WorkItem item in currentItems) {
            item.dependencyCycle = currentItems.toList();
          }
        } else {
          assert(currentItems.length == 1);
        }
        return true;
      }
    });
  }
}

/**
 * Specialization of [CycleAwareDependencyWalker] for use by [WorkOrder].
 */
class _WorkOrderDependencyWalker extends CycleAwareDependencyWalker<WorkItem> {
  /**
   * The task manager used to build work items.
   */
  final TaskManager taskManager;

  _WorkOrderDependencyWalker(this.taskManager, WorkItem startingNode)
      : super(startingNode);

  @override
  WorkItem getNextInput(WorkItem node, List<WorkItem> skipInputs) {
    return node.gatherInputs(taskManager, skipInputs);
  }
}
