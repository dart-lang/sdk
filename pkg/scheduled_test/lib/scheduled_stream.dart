// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_test.scheduled_stream;

import 'dart:async';
import 'dart:collection';

import 'package:stack_trace/stack_trace.dart';

import 'scheduled_test.dart';
import 'src/stream_matcher.dart';
import 'src/utils.dart';

export 'src/stream_matcher.dart';

/// A wrapper for streams that supports a pull-based model of retrieving values
/// as well as a set of [StreamMatcher]s for testing the values emitted by the
/// stream.
///
/// The only method on [ScheduledStream] that's actually scheduled is [expect],
/// which is the method that users testing streaming code are most likely to
/// want to use.
class ScheduledStream<T> {
  /// The underlying stream.
  final Stream<T> _stream;

  /// The subscription to [_stream].
  StreamSubscription<T> _subscription;

  /// The completer for emitting a value requested by [next].
  ///
  /// If this is non-null, [_pendingValues] will always be empty, since any
  /// value coming in will be passed to this completer.
  Completer<T> _nextCompleter;

  /// The completer for emitting a value requested by [hasNext].
  Completer<bool> _hasNextCompleter;

  /// The set of all streams forked from this one.
  final _forks = new Set<ScheduledStream<T>>();
  final _forkControllers = new Set<StreamController<T>>();

  /// The queue of values emitted by [_stream] but not yet emitted through
  /// [next].
  final _pendingValues = new Queue<Fallible<T>>();

  /// All values emitted by this stream so far.
  ///
  /// This does not include values emitted by the underlying stream but not yet
  /// emitted through [next].
  List<T> get emittedValues => new UnmodifiableListView(_emittedValues);
  final _emittedValues = new List<T>();

  /// All values emitted by the underlying stream.
  ///
  /// This is intended primarily for providing debugging information.
  List<T> get allValues {
    var list = new List<T>.from(_emittedValues);
    list.addAll(_pendingValues.where((value) => value.hasValue)
        .map((value) => value.value));
    return new UnmodifiableListView(list);
  }

  /// Whether the wrapped stream has been closed.
  bool _isDone = false;

  /// Whether [next] has been called but has not yet returned.
  ///
  /// This is distinct from `_nextCompleter != null` when [next] is called while
  /// there are pending values available, until the future it returns completes.
  bool _isNextPending = false;

  /// Creates a new scheduled stream wrapping [stream].
  ScheduledStream(this._stream) {
    _subscription = _stream.listen((value) {
      for (var c in _forkControllers) {
        c.add(value);
      }
      if (_hasNextCompleter != null) {
        _hasNextCompleter.complete(true);
        _hasNextCompleter = null;
      }

      if (_nextCompleter != null) {
        _nextCompleter.complete(value);
        _emittedValues.add(value);
        _nextCompleter = null;
        _isNextPending = false;
      } else {
        _pendingValues.add(new Fallible.withValue(value));
      }
    }, onError: (error, stackTrace) {
      for (var c in _forkControllers) {
        c.addError(error, stackTrace);
      }
      if (_hasNextCompleter != null) {
        _hasNextCompleter.completeError(error, stackTrace);
        _hasNextCompleter = null;
      }

      if (_nextCompleter != null) {
        _nextCompleter.completeError(error, stackTrace);
        _nextCompleter = null;
      } else {
        _pendingValues.add(new Fallible.withError(error, stackTrace));
      }
    }, onDone: _onDone);
  }

  /// Enqueue an expectation that [streamMatcher] will match the value(s)
  /// emitted by the stream at this point in the schedule.
  ///
  /// If [streamMatcher] is a [StreamMatcher], it will match the stream as a
  /// whole. If it's a [Matcher] or another object, it will match the next value
  /// emitted by the stream (as though it were a [nextValue] matcher).
  ///
  /// This call is scheduled; the expectation won't be added until the schedule
  /// reaches this point, and the schedule won't continue until the matcher has
  /// matched the stream.
  void expect(streamMatcher) {
    streamMatcher = new StreamMatcher.wrap(streamMatcher);
    var description = 'stream emits $streamMatcher';
    schedule(() {
      return streamMatcher.tryMatch(this).then((description) {
        if (description == null) return;

        var expected = prefixLines(streamMatcher.toString(),
            firstPrefix: 'Expected: ',
            prefix:      '        | ');

        var actual = prefixLines(allValues.map((value) {
          return prefixLines(value.toString(), firstPrefix: '* ');
        }).join('\n'),
            firstPrefix: ' Emitted: ',
            prefix:      '          ');

        var which = '';
        if (description.length > 0) {
          which = '\n' + prefixLines(description.toString(),
              firstPrefix: '   Which: ',
              prefix:      '        | ');
        }

        fail("$expected\n$actual$which");
      });
    }, description);
  }

  /// Returns a Future that completes to the next value emitted by this stream.
  ///
  /// It's a [StateError] to call [next] when another call's Future has not yet
  /// completed, or when the stream has no more values. The latter can be
  /// checked using [hasNext].
  Future<T> next() {
    if (_isNextPending) {
      return new Future.error(
          new StateError("There's already a pending call to "
              "ScheduledStream.next."),
          new Chain.current());
    }

    if (_pendingValues.isNotEmpty) {
      _isNextPending = true;

      var valueOrError = _pendingValues.removeFirst();
      if (valueOrError.hasValue) {
        _emittedValues.add(valueOrError.value);
      }
      return valueOrError.toFuture().whenComplete(() {
        _isNextPending = false;
      });
    } else if (_isDone) {
      return new Future.error(
          new StateError("ScheduledStream has no more elements."),
          new Chain.current());
    }

    _isNextPending = true;
    _nextCompleter = new Completer();
    return _nextCompleter.future;
  }

  /// Returns a Future that completes to a boolean indicating whether the stream
  /// has additional values or not.
  Future<bool> get hasNext {
    if (_hasNextCompleter != null) return _hasNextCompleter.future;

    if (_pendingValues.isNotEmpty) {
      return _pendingValues.first.toFuture().then((_) => true);
    } else if (_isDone) {
      return new Future.value(false);
    }

    _hasNextCompleter = new Completer();
    return _hasNextCompleter.future;
  }

  /// Returns a fork of this stream.
  ///
  /// The fork begins at the same point [this] is at. Values can be read from it
  /// without consuming values in [this]. If [this] is closed, the fork will be
  /// closed at whatever point it's currently at.
  ScheduledStream<T> fork() {
    var controller = new StreamController<T>();
    for (var valueOrError in _pendingValues) {
      if (valueOrError.hasValue) {
        controller.add(valueOrError.value);
      } else {
        controller.addError(valueOrError.error, valueOrError.stackTrace);
      }
    }
    if (_isDone) {
      controller.close();
    } else {
      _forkControllers.add(controller);
    }

    var fork = new ScheduledStream<T>(controller.stream);
    _forks.add(fork);
    return fork;
  }

  /// Closes this stream.
  ///
  /// This cancels the subscription to the underlying stream and acts as though
  /// [this] was closed immediately after the current position, regardless of
  /// whether the underlying stream has emitted additional events.
  void close() {
    _subscription.cancel();
    _pendingValues.clear();

    for (var fork in _forks) {
      fork.close();
    }
    _forks.clear();

    if (!_isDone) _onDone();
  }

  /// Handles a "done" event from the underlying stream, as well as [this] being
  /// closed.
  void _onDone() {
    for (var c in _forkControllers) {
      c.close();
    }
    _forkControllers.clear();

    if (_hasNextCompleter != null) {
      _hasNextCompleter.complete(false);
      _hasNextCompleter = null;
    }

    if (_nextCompleter != null) {
      _nextCompleter.completeError(
          new StateError("ScheduledStream has no more elements."),
          new Chain.current());
      _nextCompleter = null;
      _isNextPending = false;
    }

    _isDone = true;
  }
}
