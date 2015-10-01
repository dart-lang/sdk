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
    // Close it.
    block.close();
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
  // Has this block been closed?
  bool _closed = false;

  _SyncBlock._(this.name,
               this._start);

  /// Close this block of time. At this point, this block can no longer be
  /// used.
  void close() {
    if (_closed) {
      throw new StateError(
          'It is illegal to call close twice on the same _SyncBlock');
    }
    _closed = true;
    var end = _getTraceClock();

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

/// Returns the current value from the trace clock.
external int _getTraceClock();

/// Reports a complete synchronous event.
external void _reportCompleteEvent(int start,
                                   int end,
                                   String category,
                                   String name,
                                   String argumentsAsJson);
