// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Timer default _TimerFactory {
  /**
   * Creates a new timer. The [callback] callback is invoked after
   * [milliSeconds] milliseconds.
   */
  Timer(int milliSeconds, void callback(Timer timer));

  /**
   * Creates a new repeating timer. The [callback] is invoked every
   * [milliSeconds] millisecond until cancelled.
   */
  Timer.repeating(int milliSeconds, void callback(Timer timer));

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

// _TimerFactory provides a hook which allows various implementations of this
// library to provide a concrete class for the Timer interface.
class _TimerFactory {
  factory Timer(int milliSeconds, void callback(Timer timer)) {
    if (_factory == null) {
      throw new UnsupportedOperationException("Timer interface not supported.");
    }
    return _factory(milliSeconds, callback, false);
  }

  factory Timer.repeating(int milliSeconds, void callback(Timer timer)) {
    if (_factory == null) {
      throw new UnsupportedOperationException("Timer interface not supported.");
    }
    return _factory(milliSeconds, callback, true);
  }

  static _TimerFactoryClosure _factory;
}

void _setTimerFactoryClosure(_TimerFactoryClosure closure) {
  _TimerFactory._factory = closure;
}
