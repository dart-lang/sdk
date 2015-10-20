// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

typedef dynamic TimelineSyncFunction();

/// Add to the timeline.
class Timeline {
  /// Start a synchronous operation labeled [name]. Optionally takes
  /// a [Map] of [arguments]. This operation must be finished before
  /// returning to the event queue.
  static void startSync(String name, {Map arguments}) {
    if (name is! String) {
      throw new ArgumentError.value(name,
                                    'name',
                                    'Must be a String');
    }
    var block = new _SyncBlock._(name, _getTraceClock());
    if (arguments is Map) {
      block.arguments.addAll(arguments);
    }
    _stack.add(block);
  }

  /// Finish the last synchronous operation that was started.
  static void finishSync() {
    if (_stack.length == 0) {
      throw new StateError(
          'Uneven calls to startSync and finishSync');
    }
    // Pop top item off of stack.
    var block = _stack.removeLast();
    // Finish it.
    block.finish();
  }

  /// A utility method to time a synchronous [function]. Internally calls
  /// [function] bracketed by calls to [startSync] and [finishSync].
  static dynamic timeSync(String name,
                          TimelineSyncFunction function,
                          {Map arguments}) {
    startSync(name, arguments: arguments);
    try {
      return function();
    } finally {
      finishSync();
    }
  }

  static final List<_SyncBlock> _stack = new List<_SyncBlock>();

  static final int _isolateId = _getIsolateNum();
}

/// An asynchronous task on the timeline. Asynchronous tasks can live
/// longer than the current event and can even be shared between isolates.
/// An asynchronous task can have many (nested) blocks. To share a
/// [TimelineTask] across isolates, you must construct a [TimelineTask] in
/// both isolates using the same [taskId] and [category].
class TimelineTask {
  /// Create a task. [taskId] will be set by the system.
  /// Optionally you can specify a [category] name.
  TimelineTask({String category: 'Dart'})
      : _taskId = _getNextAsyncId(),
        category = category {
    if (category is! String) {
      throw new ArgumentError.value(category,
                                    'category',
                                    'Must be a String');
    }
  }

  /// Create a task with an explicit [taskId]. This is useful if you are
  /// passing a task between isolates. Optionally you can specify a [category]
  /// name.
  TimelineTask.withTaskId(int taskId, {String category: 'Dart'})
      : _taskId = taskId,
        category = category {
    if (taskId is! int) {
      throw new ArgumentError.value(taskId,
                                    'taskId',
                                    'Must be an int');
    }
    if (category is! String) {
      throw new ArgumentError.value(category,
                                    'category',
                                    'Must be a String');
    }
  }

  /// Start a block in this task named [name]. Optionally takes
  /// a [Map] of [arguments].
  /// Returns an [AsyncBlock] which is used to finish this block.
  AsyncBlock start(String name, {Map arguments}) {
    if (name is! String) {
      throw new ArgumentError.value(name,
                                    'name',
                                    'Must be a String');
    }
    var block = new AsyncBlock._(name, _taskId, category);
    if (arguments is Map) {
      block.arguments.addAll(arguments);
    }
    /// Emit start event.
    block._start();
    return block;
  }

  /// Retrieve the asynchronous task's id. Can be used to construct a
  /// [TimelineTask] in another isolate.
  int get taskId => _taskId;
  final int _taskId;
  /// Retrieve the asynchronous task's category. Can be used to construct a
  /// [TimelineTask] in another isolate.
  final String category;
}

/// An asynchronous block of time on the timeline. This block can be kept
/// open across isolate messages.
class AsyncBlock {
  /// The category this block belongs to.
  final String category;
  /// The name of this block.
  final String name;
  /// The asynchronous task id.
  final int _taskId;
  /// An (optional) set of arguments which will be serialized to JSON and
  /// associated with this block.
  final Map arguments = {};
  bool _finished = false;

  AsyncBlock._(this.name, this._taskId, this.category);

  // Emit the start event.
  void _start() {
    arguments['isolateNumber'] = '${Timeline._isolateId}';
    String argumentsAsJson = JSON.encode(arguments);
    _reportTaskEvent(_getTraceClock(),
                     _taskId,
                     'b',
                     category,
                     name,
                     argumentsAsJson);
  }

  // Emit the finish event.
  void _finish() {
    _reportTaskEvent(_getTraceClock(),
                     _taskId,
                     'e',
                     category,
                     name,
                     JSON.encode({}));
  }

  /// Finish this block. Cannot be called twice.
  void finish() {
    if (_finished) {
      throw new StateError(
          'It is illegal to call finish twice on the same AsyncBlock');
    }
    _finished = true;
    _finish();
  }

  /// Finishes this block when [future] completes. Returns a [Future]
  /// chained to [future].
  Future finishWhenComplete(Future future) {
    if (future is! Future) {
      throw new ArgumentError.value(future,
                                    'future',
                                    'Must be a Future');
    }
    return future.whenComplete(() {
      finish();
    });
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
  final Map arguments = {};
  // The start time stamp.
  final int _start;

  _SyncBlock._(this.name,
               this._start);

  /// Finish this block of time. At this point, this block can no longer be
  /// used.
  void finish() {
    var end = _getTraceClock();

    arguments['isolateNumber'] = '${Timeline._isolateId}';

    // Encode arguments map as JSON before reporting.
    var argumentsAsJson = JSON.encode(arguments);

    // Report event to runtime.
    _reportCompleteEvent(_start,
                         end,
                         category,
                         name,
                         argumentsAsJson);
  }
}

/// Returns the next async task id.
external int _getNextAsyncId();

/// Returns the current value from the trace clock.
external int _getTraceClock();

/// Returns the isolate's main port number.
external int _getIsolateNum();

/// Reports an event for a task.
external void _reportTaskEvent(int start,
                               int taskId,
                               String phase,
                               String category,
                               String name,
                               String argumentsAsJson);

/// Reports a complete synchronous event.
external void _reportCompleteEvent(int start,
                                   int end,
                                   String category,
                                   String name,
                                   String argumentsAsJson);
