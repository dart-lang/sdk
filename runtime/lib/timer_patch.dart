// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "async_patch.dart";

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    // TODO(iposva): Remove _TimerFactory and use VMLibraryHooks exclusively.
    if (_TimerFactory._factory == null) {
      _TimerFactory._factory = VMLibraryHooks.timerFactory;
    }
    if (_TimerFactory._factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return _TimerFactory._factory(milliseconds, (_) {
      callback();
    }, false);
  }

  @patch
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    // TODO(iposva): Remove _TimerFactory and use VMLibraryHooks exclusively.
    if (_TimerFactory._factory == null) {
      _TimerFactory._factory = VMLibraryHooks.timerFactory;
    }
    if (_TimerFactory._factory == null) {
      throw new UnsupportedError("Timer interface not supported.");
    }
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return _TimerFactory._factory(milliseconds, callback, true);
  }
}

typedef Timer _TimerFactoryClosure(
    int milliseconds, void callback(Timer timer), bool repeating);

// Warning: Dartium sets _TimerFactory._factory instead of setting things up
// through VMLibraryHooks.timerFactory.
class _TimerFactory {
  static _TimerFactoryClosure _factory;
}
