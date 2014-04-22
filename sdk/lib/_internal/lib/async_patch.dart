// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_js_helper' show
    Primitives,
    convertDartClosureToJS,
    loadDeferredLibrary;
import 'dart:_isolate_helper' show
    IsolateNatives,
    TimerImpl,
    leaveJsAsync,
    enterJsAsync,
    isWorker,
    globalThis;

import 'dart:_foreign_helper' show JS;

patch Timer _createTimer(Duration duration, void callback()) {
  int milliseconds = duration.inMilliseconds;
  if (milliseconds < 0) milliseconds = 0;
  return new TimerImpl(milliseconds, callback);
}

patch Timer _createPeriodicTimer(Duration duration,
                                 void callback(Timer timer)) {
  int milliseconds = duration.inMilliseconds;
  if (milliseconds < 0) milliseconds = 0;
  return new TimerImpl.periodic(milliseconds, callback);
}

patch class _AsyncRun {
  patch static void _scheduleImmediate(void callback()) {
    scheduleImmediateClosure(callback);
  }

  // Lazily initialized.
  static final Function scheduleImmediateClosure =
      _initializeScheduleImmediate();

  static Function _initializeScheduleImmediate() {
    if (JS('', '#.scheduleImmediate', globalThis) != null) {
      return _scheduleImmediateJsOverride;
    }
    // TODO(9002): don't use the Timer to enqueue the immediate callback.
    // Also check for other JS options like mutation observer or runImmediate.
    return _scheduleImmediateWithTimer;
  }

  static void _scheduleImmediateJsOverride(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    };
    enterJsAsync();
    JS('void', '#.scheduleImmediate(#)',
       globalThis,
       convertDartClosureToJS(internalCallback, 0));
  }

  static void _scheduleImmediateWithTimer(void callback()) {
    _createTimer(Duration.ZERO, callback);
  }
}

patch class DeferredLibrary {
  patch Future<Null> load() {
    return loadDeferredLibrary(libraryName, uri);
  }
}

bool get _hasDocument => JS('String', 'typeof document') == 'object';
