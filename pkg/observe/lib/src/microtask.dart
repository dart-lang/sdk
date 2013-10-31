// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * *Warning*: this library is **internal**, and APIs are subject to change.
 *
 * Wraps a callback using [wrapMicrotask] and provides the ability to pump all
 * observable objects and [scheduleMicrotask] calls via
 * [performMicrotaskCheckpoint].
 */
library observe.src.microtask;

import 'dart:async' show Completer, runZoned, ZoneSpecification;
import 'dart:collection';
import 'package:observe/observe.dart' show Observable;

// TODO(jmesserly): remove "microtask" from these names and instead import
// the library "as microtask"?

/**
 * This change pumps events relevant to observers and data-binding tests.
 * This must be used inside an [observeTest].
 *
 * Executes all pending [scheduleMicrotask] calls on the event loop, as well as
 * performing [Observable.dirtyCheck], until there are no more pending events.
 * It will always dirty check at least once.
 */
// TODO(jmesserly): do we want to support nested microtasks similar to nested
// zones? Instead of a single pending list we'd need one per wrapMicrotask,
// and [performMicrotaskCheckpoint] would only run pending callbacks
// corresponding to the innermost wrapMicrotask body.
void performMicrotaskCheckpoint() {
  Observable.dirtyCheck();

  while (_pending.isNotEmpty) {

    for (int len = _pending.length; len > 0 && _pending.isNotEmpty; len--) {
      final callback = _pending.removeFirst();
      try {
        callback();
      } catch (e, s) {
        new Completer().completeError(e, s);
      }
    }

    Observable.dirtyCheck();
  }
}

final Queue<Function> _pending = new Queue<Function>();

/**
 * Wraps the [body] in a zone that supports [performMicrotaskCheckpoint],
 * and returns the body.
 */
// TODO(jmesserly): deprecate? this doesn't add much over runMicrotask.
wrapMicrotask(body()) => () => runMicrotask(body);

/**
 * Runs the [body] in a zone that supports [performMicrotaskCheckpoint],
 * and returns the result.
 */
runMicrotask(body()) => runZoned(() {
  try {
    return body();
  } finally {
    performMicrotaskCheckpoint();
  }
}, zoneSpecification: new ZoneSpecification(
    scheduleMicrotask: (self, parent, zone, callback) => _pending.add(callback))
);
