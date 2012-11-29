// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_isolate;

abstract class Timer {
  /**
   * Creates a new timer. The [callback] callback is invoked after
   * [milliSeconds] milliseconds.
   */
  factory Timer(int milliSeconds, void callback(Timer timer)) {
    if (_TimerFactory._factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    return _TimerFactory._factory(milliSeconds, callback, false);
  }

  /**
   * Creates a new repeating timer. The [callback] is invoked every
   * [milliSeconds] millisecond until cancelled.
   */
  factory Timer.repeating(int milliSeconds, void callback(Timer timer)) {
    if (_TimerFactory._factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    return _TimerFactory._factory(milliSeconds, callback, true);
  }

  /**
   * Cancels the timer.
   */
  void cancel();
}

// TODO(ajohnsen): Patch timer once we have support for patching named
//                 factory constructors in the VM.

typedef Timer _TimerFactoryClosure(int milliSeconds,
                                   void callback(Timer timer),
                                   bool repeating);

class _TimerFactory {
  static _TimerFactoryClosure _factory;
}

// TODO(ahe): Warning: this is NOT called by Dartium. Instead, it sets
// [_TimerFactory._factory] directly.
void _setTimerFactoryClosure(_TimerFactoryClosure closure) {
  _TimerFactory._factory = closure;
}
