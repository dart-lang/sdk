// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_js_helper'
    show patch, Primitives, NoReifyFunctionTypes, DartIterator;
import 'dart:_isolate_helper'
    show
        IsolateNatives,
        TimerImpl,
        global,
        leaveJsAsync,
        enterJsAsync,
        isWorker;

import 'dart:_foreign_helper' show JS, JSExportName;

typedef void _Callback();
typedef void _TakeCallback(_Callback callback);

@JSExportName('async')
@NoReifyFunctionTypes()
async_<T>(Function() initGenerator) {
  var iter;
  Object Function(Object) onValue;
  Object Function(Object) onError;

  onAwait(Object value) {
    _Future f;
    if (value is _Future) {
      f = value;
    } else if (value is Future) {
      f = new _Future();
      _Future._chainForeignFuture(value, f);
    } else {
      f = new _Future.value(value);
    }
    f = JS('', '#', f._thenNoZoneRegistration(onValue, onError));
    return f;
  }

  onValue = (value) {
    var iteratorResult = JS('', '#.next(#)', iter, value);
    value = JS('', '#.value', iteratorResult);
    return JS('bool', '#.done', iteratorResult) ? value : onAwait(value);
  };

  // If the awaited Future throws, we want to convert this to an exception
  // thrown from the `yield` point, as if it was thrown there.
  //
  // If the exception is not caught inside `gen`, it will emerge here, which
  // will send it to anyone listening on this async function's Future<T>.
  //
  // In essence, we are giving the code inside the generator a chance to
  // use try-catch-finally.
  onError = (value) {
    var iteratorResult = JS('', '#.throw(#)', iter, value);
    value = JS('', '#.value', iteratorResult);
    return JS('bool', '#.done', iteratorResult) ? value : onAwait(value);
  };

  var zone = Zone.current;
  if (zone != Zone.ROOT) {
    onValue = zone.registerUnaryCallback(onValue);
    onError = zone.registerUnaryCallback(onError);
  }
  var asyncFuture = new _Future<T>();
  scheduleMicrotask(() {
    try {
      iter = JS('', '#[Symbol.iterator]()', initGenerator());
      var iteratorValue = JS('', '#.next(null)', iter);
      var value = JS('', '#.value', iteratorValue);
      if (JS('bool', '#.done', iteratorValue)) {
        // Return type is checked & cast inserted statically, we should not need
        // a cast here.
        asyncFuture._complete(JS('', '#', value));
        return;
      }
      _Future._chainCoreFuture(onAwait(value), asyncFuture);
    } catch (e, s) {
      _completeWithErrorCallback(asyncFuture, e, s);
    }
  });
  return asyncFuture;
}

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
    if (JS('', '#.scheduleImmediate', global) != null) {
      return _scheduleImmediateJsOverride;
    }
    if (JS('', '#.MutationObserver', global) != null &&
        JS('', '#.document', global) != null) {
      // Use mutationObservers.
      var div = JS('', '#.document.createElement("div")', global);
      var span = JS('', '#.document.createElement("span")', global);
      _Callback storedCallback;

      internalCallback(_) {
        leaveJsAsync();
        var f = storedCallback;
        storedCallback = null;
        f();
      }

      ;

      var observer =
          JS('', 'new #.MutationObserver(#)', global, internalCallback);
      JS('', '#.observe(#, { childList: true })', observer, div);

      return (void callback()) {
        assert(storedCallback == null);
        enterJsAsync();
        storedCallback = callback;
        // Because of a broken shadow-dom polyfill we have to change the
        // children instead a cheap property.
        // See https://github.com/Polymer/ShadowDOM/issues/468
        JS('', '#.firstChild ? #.removeChild(#): #.appendChild(#)', div, div,
            span, div, span);
      };
    } else if (JS('', '#.setImmediate', global) != null) {
      return _scheduleImmediateWithSetImmediate;
    }
    // TODO(20055): We should use DOM promises when available.
    return _scheduleImmediateWithTimer;
  }

  static void _scheduleImmediateJsOverride(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    }

    ;
    enterJsAsync();
    JS('void', '#.scheduleImmediate(#)', global, internalCallback);
  }

  static void _scheduleImmediateWithSetImmediate(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    }

    ;
    enterJsAsync();
    JS('void', '#.setImmediate(#)', global, internalCallback);
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
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
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
