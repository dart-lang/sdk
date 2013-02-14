// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void _TimerCallback0();
typedef void _TimerCallback1(Timer timer);

patch class Timer {
  /* patch */ factory Timer(var duration, Function callback) {
    // TODO(floitsch): remove these checks when we remove the deprecated
    // millisecond argument and the 1-argument callback. Also remove
    // the int-test below.
    if (callback is! _TimerCallback0 && callback is! _TimerCallback1) {
      throw new ArgumentError(callback);
    }
    int milliseconds = duration is int ? duration : duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    _TimerCallback1 oneArgumentCallback =
        callback is _TimerCallback1 ? callback : (_) { callback(); };
    if (_TimerFactory._factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    return _TimerFactory._factory(milliseconds, oneArgumentCallback, false);
  }

  /**
   * Creates a new repeating timer. The [callback] is invoked every
   * [milliseconds] millisecond until cancelled.
   */
  /* patch */ factory Timer.repeating(var duration,
                                      void callback(Timer timer)) {
    if (_TimerFactory._factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    // TODO(floitsch): remove this check when we remove the deprecated
    // millisecond argument.
    int milliseconds = duration is int ? duration : duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return _TimerFactory._factory(milliseconds, callback, true);
  }
}

typedef Timer _TimerFactoryClosure(int milliseconds,
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
