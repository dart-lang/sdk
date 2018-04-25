// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._isolate_helper;

import 'dart:_runtime' as dart;
import 'dart:async';
import 'dart:_foreign_helper' show JS;

/// Marks entering a JavaScript async operation to keep the worker alive.
///
/// To be called by library code before starting an async operation controlled
/// by the JavaScript event handler.
///
/// Also call [leaveJsAsync] in all callback handlers marking the end of that
/// async operation (also error handlers) so the worker can be released.
///
/// These functions only has to be called for code that can be run from a
/// worker-isolate (so not for general dom operations).
///
// TODO(jmesserly): we could potentially use this to track when all async
// operations have completed, for example, to run a bunch of test `main()`
// methods in batch mode the same V8 process.
enterJsAsync() {}

/// Marks leaving a javascript async operation.
///
/// See [enterJsAsync].
leaveJsAsync() {}

/// Deprecated way of initializing `main()` in DDC, typically called from JS.
@deprecated
void startRootIsolate(main, args) {
  if (args == null) args = <String>[];
  if (args is List) {
    if (args is! List<String>) args = new List<String>.from(args);
    // DDC attaches signatures only when torn off, and the typical way of
    // getting `main` via the JS ABI won't do this. So use JS to invoke main.
    if (JS<bool>('!', 'typeof # == "function"', main)) {
      // JS will ignore extra arguments.
      JS('', '#(#, #)', main, args, null);
    } else {
      // Not a function. Use a dynamic call to throw an error.
      (main as dynamic)(args);
    }
  } else {
    throw new ArgumentError("Arguments to main must be a List: $args");
  }
}

// TODO(vsm): Other libraries import global from here.  Consider replacing
// those uses to just refer to the one in dart:runtime.
final global = dart.global_;

class TimerImpl implements Timer {
  final bool _once;
  int _handle;
  int _tick = 0;

  TimerImpl(int milliseconds, void callback()) : _once = true {
    if (hasTimer()) {
      void internalCallback() {
        _handle = null;
        leaveJsAsync();
        _tick = 1;
        callback();
      }

      enterJsAsync();

      _handle = JS(
          'int', '#.setTimeout(#, #)', global, internalCallback, milliseconds);
    } else {
      throw new UnsupportedError("`setTimeout()` not found.");
    }
  }

  TimerImpl.periodic(int milliseconds, void callback(Timer timer))
      : _once = false {
    if (hasTimer()) {
      enterJsAsync();
      int start = JS('int', 'Date.now()');
      _handle = JS('int', '#.setInterval(#, #)', global, () {
        int tick = this._tick + 1;
        if (milliseconds > 0) {
          int duration = JS('int', 'Date.now()') - start;
          if (duration > (tick + 1) * milliseconds) {
            tick = duration ~/ milliseconds;
          }
        }
        this._tick = tick;
        callback(this);
      }, milliseconds);
    } else {
      throw new UnsupportedError("Periodic timer.");
    }
  }

  int get tick => _tick;

  void cancel() {
    if (hasTimer()) {
      if (_handle == null) return;
      leaveJsAsync();
      if (_once) {
        JS('void', '#.clearTimeout(#)', global, _handle);
      } else {
        JS('void', '#.clearInterval(#)', global, _handle);
      }
      _handle = null;
    } else {
      throw new UnsupportedError("Canceling a timer.");
    }
  }

  bool get isActive => _handle != null;
}

bool hasTimer() {
  return JS('', '#.setTimeout', global) != null;
}
