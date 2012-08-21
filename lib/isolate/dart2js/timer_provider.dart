// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// We don't want to import the DOM library just because of window.setTimeout,
// so we reconstruct the Window class here. The only conflict that could happen
// with the other DOMWindow class would be because of subclasses.
// Currently, none of the two Dart classes have subclasses.
typedef void _TimeoutHandler();

class _Window native "@*DOMWindow" {
  int setTimeout(_TimeoutHandler handler, int timeout) native;
  int setInterval(_TimeoutHandler handler, int timeout) native;
}

_Window get _window() =>
  JS('bool', 'typeof window != "undefined"') ? JS('_Window', 'window') : null;

class _Timer implements Timer {
  final bool _once;
  int _handle;

  _Timer(int milliSeconds, void callback(Timer timer))
      : _once = true {
    _handle = _window.setTimeout(() => callback(this), milliSeconds);
  }

  _Timer.repeating(int milliSeconds, void callback(Timer timer))
      : _once = false {
    _handle = _window.setInterval(() => callback(this), milliSeconds);
  }

  void cancel() {
    if (_once) {
      _window.clearTimeout(_handle);
    } else {
      _window.clearInterval(_handle);
    }
  }
}

Timer _timerFactory(int millis, void callback(Timer timer), bool repeating) =>
  repeating ? new _Timer.repeating(millis, callback)
            : new _Timer(millis, callback);
