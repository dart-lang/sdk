// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_js_helper' show
    patch,
    Primitives;
import 'dart:_isolate_helper' show
    IsolateNatives,
    TimerImpl,
    leaveJsAsync,
    enterJsAsync,
    isWorker;

import 'dart:_foreign_helper' show JS;

typedef void _Callback();
typedef void _TakeCallback(_Callback callback);

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    _scheduleImmediateClosure(callback);
  }

  // Lazily initialized.
  static final _TakeCallback _scheduleImmediateClosure =
      _initializeScheduleImmediate();

  static _TakeCallback _initializeScheduleImmediate() {
    // TODO(rnystrom): Not needed by dev_compiler.
    // requiresPreamble();
    if (JS('', 'self.scheduleImmediate') != null) {
      return _scheduleImmediateJsOverride;
    }
    if (JS('', 'self.MutationObserver') != null &&
        JS('', 'self.document') != null) {
      // Use mutationObservers.
      var div = JS('', 'self.document.createElement("div")');
      var span = JS('', 'self.document.createElement("span")');
      _Callback storedCallback;

      internalCallback(_) {
        leaveJsAsync();
        var f = storedCallback;
        storedCallback = null;
        f();
      };

      var observer = JS('', 'new self.MutationObserver(#)', internalCallback);
      JS('', '#.observe(#, { childList: true })',
          observer, div);

      return (void callback()) {
        assert(storedCallback == null);
        enterJsAsync();
        storedCallback = callback;
        // Because of a broken shadow-dom polyfill we have to change the
        // children instead a cheap property.
        // See https://github.com/Polymer/ShadowDOM/issues/468
        JS('', '#.firstChild ? #.removeChild(#): #.appendChild(#)',
            div, div, span, div, span);
      };
    } else if (JS('', 'self.setImmediate') != null) {
      return _scheduleImmediateWithSetImmediate;
    }
    // TODO(20055): We should use DOM promises when available.
    return _scheduleImmediateWithTimer;
  }

  static void _scheduleImmediateJsOverride(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    };
    enterJsAsync();
    JS('void', 'self.scheduleImmediate(#)', internalCallback);
  }

  static void _scheduleImmediateWithSetImmediate(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    };
    enterJsAsync();
    JS('void', 'self.setImmediate(#)', internalCallback);
  }

  static void _scheduleImmediateWithTimer(void callback()) {
    Timer._createTimer(Duration.ZERO, callback);
  }
}

@patch
class DeferredLibrary {
  @patch
  Future<Null> load() {
    throw 'DeferredLibrary not supported. '
          'please use the `import "lib.dart" deferred as lib` syntax.';
  }
}

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return new TimerImpl(milliseconds, callback);
  }

  @patch
  static Timer _createPeriodicTimer(Duration duration,
                             void callback(Timer timer)) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return new TimerImpl.periodic(milliseconds, callback);
  }
}

@patch
void _rethrow(Object error, StackTrace stackTrace) {
  // TODO(rnystrom): Not needed by dev_compiler.
  // error = wrapException(error);
  JS("void", "#.stack = #", error, stackTrace.toString());
  JS("void", "throw #", error);
}
