// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_js_helper' show Primitives, convertDartClosureToJS;
import 'dart:_isolate_helper' show
    IsolateNatives,
    TimerImpl,
    leaveJsAsync,
    enterJsAsync,
    isWorker;

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
    // TODO(9002): don't use the Timer to enqueue the immediate callback.
    _createTimer(Duration.ZERO, callback);
  }
}

patch class DeferredLibrary {
  patch Future<bool> load() {
    List hunkNames = new List();
    if (JS('bool', '\$.libraries_to_load[#] === undefined', libraryName)) {
      return new Future(() => false);
    }
    for (int index = 0;
         index < JS('int', '\$.libraries_to_load[#].length', libraryName);
         ++index) {
      hunkNames.add(JS('String', '\$.libraries_to_load[#][#]',
                       libraryName, index));
    }
    Iterable<Future<bool>> allLoads =
        hunkNames.map((hunkName) => _load(hunkName, uri));
    return Future.wait(allLoads).then((results) {
      return results.any((x) => x);
    });
  }
}

// TODO(ahe): This should not only apply to this isolate.
final Map<String, Future<bool>> _loadedLibraries = <String, Future<bool>>{};

Future<bool> _load(String hunkName, String uri) {
  // TODO(ahe): Validate libraryName.  Kasper points out that you want
  // to be able to experiment with the effect of toggling @DeferLoad,
  // so perhaps we should silently ignore "bad" library names.
  Future<bool> future = _loadedLibraries[hunkName];
  if (future != null) {
    return future.then((_) => false);
  }

  if (uri == null) {
    uri = IsolateNatives.thisScript;
  }
  int index = uri.lastIndexOf('/');
  uri = '${uri.substring(0, index + 1)}$hunkName';

  if (Primitives.isJsshell || Primitives.isD8) {
    // TODO(ahe): Move this code to a JavaScript command helper script that is
    // not included in generated output.
    return _loadedLibraries[hunkName] = new Future<bool>(() {
      try {
        // Create a new function to avoid getting access to current function
        // context.
        JS('void', '(new Function(#))()', 'load("$uri")');
      } catch (error, stackTrace) {
        throw new DeferredLoadException("Loading $uri failed.");
      }
      return true;
    });
  } else if (isWorker()) {
    // We are in a web worker. Load the code with an XMLHttpRequest.
    return _loadedLibraries[hunkName] = new Future<bool>(() {
      Completer completer = new Completer<bool>();
      enterJsAsync();
      Future<bool> leavingFuture = completer.future.whenComplete(() {
        leaveJsAsync();
      });

      int index = uri.lastIndexOf('/');
      uri = '${uri.substring(0, index + 1)}$hunkName';
      var xhr =  JS('dynamic', 'new XMLHttpRequest()');
      JS('void', '#.open("GET", #)', xhr, uri);
      JS('void', '#.addEventListener("load", #, false)',
         xhr, convertDartClosureToJS((event) {
        if (JS('int', '#.status', xhr) != 200) {
          completer.completeError(
              new DeferredLoadException("Loading $uri failed."));
          return;
        }
        String code = JS('String', '#.responseText', xhr);
        try {
          // Create a new function to avoid getting access to current function
          // context.
          JS('void', '(new Function(#))()', code);
        } catch (error, stackTrace) {
          completer.completeError(
            new DeferredLoadException("Evaluating $uri failed."));
          return;
        }
        completer.complete(true);
      }, 1));

      var fail = convertDartClosureToJS((event) {
        new DeferredLoadException("Loading $uri failed.");
      }, 1);
      JS('void', '#.addEventListener("error", #, false)', xhr, fail);
      JS('void', '#.addEventListener("abort", #, false)', xhr, fail);

      JS('void', '#.send()', xhr);
      return leavingFuture;
    });
  }
  // We are in a dom-context.
  return _loadedLibraries[hunkName] = new Future<bool>(() {
    Completer completer = new Completer<bool>();
    // Inject a script tag.
    var script = JS('', 'document.createElement("script")');
    JS('', '#.type = "text/javascript"', script);
    JS('', '#.src = #', script, uri);
    JS('', '#.addEventListener("load", #, false)',
       script, convertDartClosureToJS((event) {
      completer.complete(true);
    }, 1));
    JS('', '#.addEventListener("error", #, false)',
       script, convertDartClosureToJS((event) {
      completer.completeError(
          new DeferredLoadException("Loading $uri failed."));
    }, 1));
    JS('', 'document.body.appendChild(#)', script);

    return completer.future;
  });
}

bool get _hasDocument => JS('String', 'typeof document') == 'object';
