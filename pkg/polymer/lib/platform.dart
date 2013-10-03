// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Exposes helper functionality for interacting with the platform. Similar to
 * the [Platform] class from dart:html.
 */
// TODO(jmesserly): in Polymer this is a static class called "Platform", but
// that conflicts with dart:html. What should we do? Does this functionality
// belong in html's Platform instead?
library polymer.platform;

import 'dart:async' show Completer;
import 'dart:html' show Text, MutationObserver;
import 'dart:collection' show Queue;
import 'package:observe/src/microtask.dart' show performMicrotaskCheckpoint;

void flush() {
  endOfMicrotask(performMicrotaskCheckpoint);
}

int _iterations = 0;
final Queue _callbacks = new Queue();
final Text _twiddle = () {
  var twiddle = new Text('');
  new MutationObserver((x, y) {
    while (_callbacks.isNotEmpty) {
      try {
        _callbacks.removeFirst()();
      } catch (e) { // Dart note: fire the error async.
        new Completer().completeError(e);
      }
    }
  }).observe(twiddle, characterData: true);
  return twiddle;
}();

void endOfMicrotask(void callback()) {
  _twiddle.text = '${_iterations++}';
  _callbacks.add(callback);
}
