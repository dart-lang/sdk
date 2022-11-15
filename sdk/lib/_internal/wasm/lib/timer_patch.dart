// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "async_patch.dart";

// Implementation of `Timer` and `scheduleMicrotask` via the JS event loop.

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    return _OneShotTimer(duration, callback);
  }

  @patch
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    return _PeriodicTimer(duration, callback);
  }
}

abstract class _Timer implements Timer {
  final double milliseconds;
  bool isActive;
  int tick;

  _Timer(Duration duration)
      : milliseconds = duration.inMilliseconds.toDouble(),
        isActive = true,
        tick = 0 {
    _schedule();
  }

  void _schedule() {
    scheduleCallback(milliseconds, () {
      if (isActive) {
        tick++;
        _run();
      }
    });
  }

  void _run();

  @override
  void cancel() {
    isActive = false;
  }
}

class _OneShotTimer extends _Timer {
  final void Function() callback;

  _OneShotTimer(Duration duration, this.callback) : super(duration);

  void _run() {
    isActive = false;
    callback();
  }
}

class _PeriodicTimer extends _Timer {
  final void Function(Timer) callback;

  _PeriodicTimer(Duration duration, this.callback) : super(duration);

  void _run() {
    _schedule();
    callback(this);
  }
}

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    scheduleCallback(0, callback);
  }
}
