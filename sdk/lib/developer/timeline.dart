// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

const bool _isProduct = const bool.fromEnvironment("dart.vm.product");

typedef dynamic TimelineSyncFunction();
typedef Future TimelineAsyncFunction();

/// A class to represent Flow events.
///
/// [Flow] objects are used to thread flow events between timeline slices,
/// for example, those created with the [Timeline] class below. Adding
/// [Flow] objects cause arrows to be drawn between slices in Chrome's trace
/// viewer. The arrows start at e.g [Timeline] events that are passed a
/// [Flow.begin] object, go through [Timeline] events that are passed a
/// [Flow.step] object, and end at [Timeline] events that are passed a
/// [Flow.end] object, all having the same [Flow.id]. For example:
///
/// ```dart
/// var flow = Flow.begin();
/// Timeline.timeSync('flow_test', () {
///   doSomething();
/// }, flow: flow);
///
/// Timeline.timeSync('flow_test', () {
///   doSomething();
/// }, flow: Flow.step(flow.id));
///
/// Timeline.timeSync('flow_test', () {
///   doSomething();
/// }, flow: Flow.end(flow.id));
/// ```
class Flow {
  // These values must be kept in sync with the enum "EventType" in
  // runtime/vm/timeline.h.
  static const int _begin = 9;
  static const int _step = 10;
  static const int _end = 11;

  final int _type;

  /// The flow id of the flow event.
  final int id;

  Flow._(this._type, this.id);

  /// A "begin" Flow event.
  ///
  /// When passed to a [Timeline] method, generates a "begin" Flow event.
  /// If [id] is not provided, an id that conflicts with no other Dart-generated
  /// flow id's will be generated.
  static Flow begin({int id}) {
    return new Flow._(_begin, id ?? _getNextAsyncId());
  }

  /// A "step" Flow event.
  ///
  /// When passed to a [Timeline] method, generates a "step" Flow event.
  /// The [id] argument is required. It can come either from another [Flow]
  /// event, or some id that comes from the environment.
  static Flow step(int id) => new Flow._(_step, id);

  /// An "end" Flow event.
  ///
  /// When passed to a [Timeline] method, generates a "end" Flow event.
  /// The [id] argument is required. It can come either from another [Flow]
  /// event, or some id that comes from the environment.
  static Flow end(int id) => new Flow._(_end, id);
}

/// Add to the timeline.
///
/// [Timeline]'s methods add synchronous events to the timeline. When
/// generating a timeline in Chrome's tracing format, using [Timeline] generates
/// "Complete" events. [Timeline]'s [startSync] and [endSync] can be used
/// explicitly, or implicitly by wrapping a closure in [timeSync]. For exmaple:
///
/// ```dart
/// Timeline.startSync("Doing Something");
/// doSomething();
/// Timeline.finishSync();
/// ```
///
/// Or:
///
/// ```dart
/// Timeline.timeSync("Doing Something", () {
///   doSomething();
/// });
/// ```
class Timeline {
  /// Start a synchronous operation labeled [name]. Optionally takes
  /// a [Map] of [arguments]. This slice may also optionally be associated with
  /// a [Flow] event. This operation must be finished before
  /// returning to the event queue.
  static void startSync(String name, {Map arguments, Flow flow}) {
    if (_isProduct) {
      return;
    }
    if (name is! String) {
      throw new ArgumentError.value(name, 'name', 'Must be a String');
    }
    if (!_isDartStreamEnabled()) {
      // Push a null onto the stack and return.
      _stack.add(null);
      return;
    }
    var block = new _SyncBlock._(name, _getTraceClock(), _getThreadCpuClock());
    if (arguments is Map) {
      block._arguments = arguments;
    }
    if (flow is Flow) {
      block.flow = flow;
    }
    _stack.add(block);
  }

  /// Finish the last synchronous operation that was started.
  static void finishSync() {
    if (_isProduct) {
      return;
    }
    if (_stack.length == 0) {
      throw new StateError('Uneven calls to startSync and finishSync');
    }
    // Pop top item off of stack.
    var block = _stack.removeLast();
    if (block == null) {
      // Dart stream was disabled when startSync was called.
      return;
    }
    // Finish it.
    block.finish();
  }

  /// Emit an instant event.
  static void instantSync(String name, {Map arguments}) {
    if (_isProduct) {
      return;
    }
    if (name is! String) {
      throw new ArgumentError.value(name, 'name', 'Must be a String');
    }
    if (!_isDartStreamEnabled()) {
      // Stream is disabled.
      return;
    }
    Map instantArguments;
    if (arguments is Map) {
      instantArguments = new Map.from(arguments);
    }
    _reportInstantEvent(
        _getTraceClock(), 'Dart', name, _argumentsAsJson(instantArguments));
  }

  /// A utility method to time a synchronous [function]. Internally calls
  /// [function] bracketed by calls to [startSync] and [finishSync].
  static dynamic timeSync(String name, TimelineSyncFunction function,
      {Map arguments, Flow flow}) {
    startSync(name, arguments: arguments, flow: flow);
    try {
      return function();
    } finally {
      finishSync();
    }
  }

  /// The current time stamp from the clock used by the timeline. Units are
  /// microseconds.
  static int get now => _getTraceClock();
  static final List<_SyncBlock> _stack = new List<_SyncBlock>();
}

/// An asynchronous task on the timeline. An asynchronous task can have many
/// (nested) synchronous operations. Synchronous operations can live longer than
/// the current isolate event. To pass a [TimelineTask] to another isolate,
/// you must first call [pass] to get the task id and then construct a new
/// [TimelineTask] in the other isolate.
class TimelineTask {
  /// Create a task. The task ID will be set by the system.
  TimelineTask() : _taskId = _getNextAsyncId() {}

  /// Create a task with an explicit [taskId]. This is useful if you are
  /// passing a task from one isolate to another.
  TimelineTask.withTaskId(int taskId) : _taskId = taskId {
    if (taskId is! int) {
      throw new ArgumentError.value(taskId, 'taskId', 'Must be an int');
    }
  }

  /// Start a synchronous operation within this task named [name].
  /// Optionally takes a [Map] of [arguments].
  void start(String name, {Map arguments}) {
    if (_isProduct) {
      return;
    }
    if (name is! String) {
      throw new ArgumentError.value(name, 'name', 'Must be a String');
    }
    var block = new _AsyncBlock._(name, _taskId);
    if (arguments is Map) {
      block._arguments = arguments;
    }
    _stack.add(block);
    block._start();
  }

  /// Emit an instant event for this task.
  void instant(String name, {Map arguments}) {
    if (_isProduct) {
      return;
    }
    if (name is! String) {
      throw new ArgumentError.value(name, 'name', 'Must be a String');
    }
    Map instantArguments;
    if (arguments is Map) {
      instantArguments = new Map.from(arguments);
    }
    _reportTaskEvent(_getTraceClock(), _taskId, 'n', 'Dart', name,
        _argumentsAsJson(instantArguments));
  }

  /// Finish the last synchronous operation that was started.
  void finish() {
    if (_isProduct) {
      return;
    }
    if (_stack.length == 0) {
      throw new StateError('Uneven calls to start and finish');
    }
    // Pop top item off of stack.
    var block = _stack.removeLast();
    block._finish();
  }

  /// Retrieve the [TimelineTask]'s task id. Will throw an exception if the
  /// stack is not empty.
  int pass() {
    if (_stack.length > 0) {
      throw new StateError(
          'You cannot pass a TimelineTask without finishing all started '
          'operations');
    }
    int r = _taskId;
    return r;
  }

  final int _taskId;
  final List<_AsyncBlock> _stack = [];
}

/// An asynchronous block of time on the timeline. This block can be kept
/// open across isolate messages.
class _AsyncBlock {
  /// The category this block belongs to.
  final String category = 'Dart';

  /// The name of this block.
  final String name;

  /// The asynchronous task id.
  final int _taskId;

  /// An (optional) set of arguments which will be serialized to JSON and
  /// associated with this block.
  Map _arguments;

  _AsyncBlock._(this.name, this._taskId);

  // Emit the start event.
  void _start() {
    _reportTaskEvent(_getTraceClock(), _taskId, 'b', category, name,
        _argumentsAsJson(_arguments));
  }

  // Emit the finish event.
  void _finish() {
    _reportTaskEvent(
        _getTraceClock(), _taskId, 'e', category, name, _argumentsAsJson(null));
  }
}

/// A synchronous block of time on the timeline. This block should not be
/// kept open across isolate messages.
class _SyncBlock {
  /// The category this block belongs to.
  final String category = 'Dart';

  /// The name of this block.
  final String name;

  /// An (optional) set of arguments which will be serialized to JSON and
  /// associated with this block.
  Map _arguments;
  // The start time stamp.
  final int _start;
  // The start time stamp of the thread cpu clock.
  final int _startCpu;

  /// An (optional) flow event associated with this block.
  Flow _flow;

  _SyncBlock._(this.name, this._start, this._startCpu);

  /// Finish this block of time. At this point, this block can no longer be
  /// used.
  void finish() {
    // Report event to runtime.
    _reportCompleteEvent(
        _start, _startCpu, category, name, _argumentsAsJson(_arguments));
    if (_flow != null) {
      _reportFlowEvent(_start, _startCpu, category, name, _flow._type, _flow.id,
          _argumentsAsJson(null));
    }
  }

  void set flow(Flow f) {
    _flow = f;
  }
}

String _argumentsAsJson(Map arguments) {
  if ((arguments == null) || (arguments.length == 0)) {
    // Fast path no arguments. Avoid calling JSON.encode.
    return '{}';
  }
  return json.encode(arguments);
}

/// Returns true if the Dart Timeline stream is enabled.
external bool _isDartStreamEnabled();

/// Returns the next async task id.
external int _getNextAsyncId();

/// Returns the current value from the trace clock.
external int _getTraceClock();

/// Returns the current value from the thread CPU usage clock.
external int _getThreadCpuClock();

/// Reports an event for a task.
external void _reportTaskEvent(int start, int taskId, String phase,
    String category, String name, String argumentsAsJson);

/// Reports a complete synchronous event.
external void _reportCompleteEvent(int start, int startCpu, String category,
    String name, String argumentsAsJson);

/// Reports a flow event.
external void _reportFlowEvent(int start, int startCpu, String category,
    String name, int type, int id, String argumentsAsJson);

/// Reports an instant event.
external void _reportInstantEvent(
    int start, String category, String name, String argumentsAsJson);
