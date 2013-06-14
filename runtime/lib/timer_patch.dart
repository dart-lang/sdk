// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Timer {
  /* patch */ factory Timer(Duration duration, void callback()) {
    if (_TimerFactory._factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return _TimerFactory._factory(milliseconds, (_) { callback(); }, false);
  }

  /* patch */ factory Timer.periodic(Duration duration,
                                     void callback(Timer timer)) {
    if (_TimerFactory._factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    int milliseconds = duration.inMilliseconds;
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
