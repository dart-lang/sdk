// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _isolate_helper;

import 'dart:async';
import 'dart:isolate';

import 'dart:_js_embedded_names' show CURRENT_SCRIPT;

import 'dart:_js_helper'
    show convertDartClosureToJS, random64, requiresPreamble;

import 'dart:_foreign_helper' show JS, JS_EMBEDDED_GLOBAL;

import 'dart:_interceptors' show JSExtendableArray;

/// Returns true if we are currently in a worker context.
bool isWorker() {
  requiresPreamble();
  return JS('', '!self.window && !!self.postMessage');
}

/// The src url for the script tag that loaded this code.
String thisScript = computeThisScript();

/// The src url for the script tag that loaded this function.
///
/// Used to create JavaScript workers and load deferred libraries.
String computeThisScript() {
  var currentScript = JS_EMBEDDED_GLOBAL('', CURRENT_SCRIPT);
  if (currentScript != null) {
    return JS('String', 'String(#.src)', currentScript);
  }
  // A worker has no script tag - so get an url from a stack-trace.
  if (isWorker()) return _computeThisScriptFromTrace();
  // An isolate that doesn't support workers, but doesn't have a
  // currentScript either. This is most likely a Chrome extension.
  return null;
}

String _computeThisScriptFromTrace() {
  var stack = JS('String|Null', 'new Error().stack');
  if (stack == null) {
    // According to Internet Explorer documentation, the stack
    // property is not set until the exception is thrown. The stack
    // property was not provided until IE10.
    stack = JS(
        'String|Null',
        '(function() {'
        'try { throw new Error() } catch(e) { return e.stack }'
        '})()');
    if (stack == null) throw new UnsupportedError('No stack trace');
  }
  var pattern, matches;

  // This pattern matches V8, Chrome, and Internet Explorer stack
  // traces that look like this:
  // Error
  //     at methodName (URI:LINE:COLUMN)
  pattern = JS('', r'new RegExp("^ *at [^(]*\\((.*):[0-9]*:[0-9]*\\)$", "m")');

  matches = JS('JSExtendableArray|Null', '#.match(#)', stack, pattern);
  if (matches != null) return JS('String', '#[1]', matches);

  // This pattern matches Firefox stack traces that look like this:
  // methodName@URI:LINE
  pattern = JS('', r'new RegExp("^[^@]*@(.*):[0-9]*$", "m")');

  matches = JS('JSExtendableArray|Null', '#.match(#)', stack, pattern);
  if (matches != null) return JS('String', '#[1]', matches);

  throw new UnsupportedError('Cannot extract URI from "$stack"');
}

class ReceivePortImpl extends Stream implements ReceivePort {
  ReceivePortImpl();

  StreamSubscription listen(void onData(var event),
      {Function onError, void onDone(), bool cancelOnError}) {
    throw new UnsupportedError("ReceivePort.listen");
  }

  void close() {}

  SendPort get sendPort => throw new UnsupportedError("ReceivePort.sendPort");
}

class TimerImpl implements Timer {
  final bool _once;
  int _handle;
  int _tick = 0;

  TimerImpl(int milliseconds, void callback()) : _once = true {
    if (_hasTimer()) {
      void internalCallback() {
        _handle = null;
        this._tick = 1;
        callback();
      }

      _handle = JS('int', 'self.setTimeout(#, #)',
          convertDartClosureToJS(internalCallback, 0), milliseconds);
    } else {
      throw new UnsupportedError('`setTimeout()` not found.');
    }
  }

  TimerImpl.periodic(int milliseconds, void callback(Timer timer))
      : _once = false {
    if (_hasTimer()) {
      int start = JS('int', 'Date.now()');
      _handle = JS(
          'int',
          'self.setInterval(#, #)',
          convertDartClosureToJS(() {
            int tick = this._tick + 1;
            if (milliseconds > 0) {
              int duration = JS('int', 'Date.now()') - start;
              if (duration > (tick + 1) * milliseconds) {
                tick = duration ~/ milliseconds;
              }
            }
            this._tick = tick;
            callback(this);
          }, 0),
          milliseconds);
    } else {
      throw new UnsupportedError('Periodic timer.');
    }
  }

  @override
  bool get isActive => _handle != null;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    if (_hasTimer()) {
      if (_handle == null) return;
      if (_once) {
        JS('void', 'self.clearTimeout(#)', _handle);
      } else {
        JS('void', 'self.clearInterval(#)', _handle);
      }
      _handle = null;
    } else {
      throw new UnsupportedError('Canceling a timer.');
    }
  }
}

bool _hasTimer() {
  requiresPreamble();
  return JS('', 'self.setTimeout') != null;
}
