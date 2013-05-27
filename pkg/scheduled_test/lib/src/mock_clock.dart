// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library that wraps [Timer] in a way that can be mocked out in test code.
/// Application code only needs to use [newTimer] to get an instance of [Timer].
/// Then test code can call [mock] to mock out all new [Timer] instances so that
/// they're controllable by a returned [Clock] object.
library mock_clock;

import 'dart:async';

import 'utils.dart';

/// The mock clock object. New [Timer]s will be mocked if and only if this is
/// non-`null`.
Clock _clock;

/// Whether or not mocking is active.
bool get _mocked => _clock != null;

/// Causes all future calls to [newTimer] to return mock [Timer] objects that
/// are controlled by the returned [Clock]. This may only be called once.
Clock mock() {
  if (_mocked) {
    throw new StateError("mock_clock.mock() has already been called.");
  }

  _clock = new Clock._();
  return _clock;
}

typedef void TimerCallback();

/// Returns a new (possibly mocked) [Timer]. Works the same as [new Timer].
Timer newTimer(Duration duration, TimerCallback callback) =>
  _mocked ? new _MockTimer(duration, callback) : new Timer(duration, callback);

/// A clock that controls when mocked [Timer]s move forward in time. It starts
/// at time 0 and advances forward millisecond-by-millisecond, broadcasting each
/// tick on the [onTick] stream.
class Clock {
  /// The current time of the clock, in milliseconds. Starts at 0.
  int get time => _time;
  int _time = 0;

  /// The stream of millisecond ticks of the clock.
  Stream<int> get onTick {
    if (_onTickControllerStream == null) {
      _onTickControllerStream = _onTickController.stream.asBroadcastStream();
    }
    return _onTickControllerStream;
  }

  final _onTickController = new StreamController<int>();
  Stream<int> _onTickControllerStream;

  Clock._();

  /// Advances the clock forward by [milliseconds]. This works like synchronous
  /// code that takes [milliseconds] to execute; any [Timer]s that are scheduled
  /// to fire during the interval will do so asynchronously once control returns
  /// to the event loop.
  void tick([int milliseconds=1]) {
    for (var i = 0; i < milliseconds; i++) {
      var tickTime = ++_time;
      new Future.value().then((_) => _onTickController.add(tickTime));
    }
  }

  /// Automatically progresses forward in time as long as there are still
  /// subscribers to [onTick] (that is, [Timer]s waiting to fire). After each
  /// tick, this pumps the event loop repeatedly so that all non-clock-dependent
  /// code runs before the next tick.
  void run() {
    pumpEventQueue().then((_) {
      if (!_onTickController.hasListener) return;
      tick();
      return run();
    });
  }
}

/// A mock implementation of [Timer] that uses [Clock] to keep time, rather than
/// the system clock.
class _MockTimer implements Timer {
  /// The time at which the timer should fire.
  final int _time;

  /// The callback to run when the timer fires.
  final TimerCallback _callback;

  /// The subscription to the [Clock.onTick] stream.
  StreamSubscription _subscription;

  _MockTimer(Duration duration, this._callback)
      : _time = _clock.time + duration.inMilliseconds {
    _subscription = _clock.onTick.listen((time) {
      if (time < _time) return;
      _subscription.cancel();
      _callback();
    });
  }

  void cancel() => _subscription.cancel();
}
