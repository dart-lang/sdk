// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_js_helper' show Primitives;
import 'dart:_isolate_helper' show IsolateNatives, TimerImpl;
import 'dart:_foreign_helper' show JS, DART_CLOSURE_TO_JS;

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
    // TODO(9002): don't use the Timer to enqueue the immediate callback.
    _createTimer(Duration.ZERO, callback);
  }
}

patch class DeferredLibrary {
  patch Future<bool> load() {
    return _load(libraryName, uri);
  }
}

// TODO(ahe): This should not only apply to this isolate.
final Map<String, Future<bool>> _loadedLibraries = <String, Future<bool>>{};

Future<bool> _load(String libraryName, String uri) {
  // TODO(ahe): Validate libraryName.  Kasper points out that you want
  // to be able to experiment with the effect of toggling @DeferLoad,
  // so perhaps we should silently ignore "bad" library names.
  Future<bool> future = _loadedLibraries[libraryName];
  if (future != null) {
    return future.then((_) => false);
  }

  if (Primitives.isJsshell) {
    // TODO(ahe): Move this code to a JavaScript command helper script that is
    // not included in generated output.
    return _loadedLibraries[libraryName] = new Future<bool>(() {
      if (uri == null) uri = 'part.js';
      // Create a new function to avoid getting access to current function
      // context.
      JS('void', '(new Function(#))()', 'loadRelativeToScript("$uri")');
      return true;
    });
  } else if (Primitives.isD8) {
    // TODO(ahe): Move this code to a JavaScript command helper script that is
    // not included in generated output.
    return _loadedLibraries[libraryName] = new Future<bool>(() {
      if (uri == null) {
        uri = IsolateNatives.computeThisScriptD8();
        int index = uri.lastIndexOf('/');
        uri = '${uri.substring(0, index + 1)}part.js';
      }
      // Create a new function to avoid getting access to current function
      // context.
      JS('void', '(new Function(#))()', 'load("$uri")');
      return true;
    });
  }

  return _loadedLibraries[libraryName] = new Future<bool>(() {
    Completer completer = new Completer<bool>();
    if (uri == null) {
      uri = IsolateNatives.thisScript;
      int index = uri.lastIndexOf('/');
      uri = '${uri.substring(0, index + 1)}part.js';
    }

    // Inject a script tag.
    var script = JS('', 'document.createElement("script")');
    JS('', '#.type = "text/javascript"', script);
    JS('', '#.src = #', script, uri);
    var onLoad = JS('', '#.bind(null, #)',
                    DART_CLOSURE_TO_JS(_onDeferredLibraryLoad), completer);
    JS('', '#.addEventListener("load", #, false)', script, onLoad);
    JS('', 'document.body.appendChild(#)', script);

    return completer.future;
  });
}

/// Used to implement deferred loading. Used as callback on "load"
/// event above in [load].
_onDeferredLibraryLoad(Completer<bool> completer, event) {
  completer.complete(true);
}

bool get _hasDocument => JS('String', 'typeof document') == 'object';
