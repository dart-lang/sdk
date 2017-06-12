// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable;

/**
 * Accumulates change events from several observable objects.
 *
 * wrap() is public and used by client code.  The other methods are used by
 * AbstractObservable, which works with this class to implement batching.
 */
class EventBatch {
  /** The current active batch, if any. */
  static EventBatch current;

  /** Used to generate unique ids for observable objects. */
  static int nextUid;

  /** Map from observable object's uid to their tracked events. */
  // TODO(sigmund): use [Observable] instead of [int] when [Map] can support it,
  Map<int, EventSummary> summaries;

  /** Whether this batch is currently firing and therefore is sealed. */
  bool sealed = false;

  /**
   * Private constructor that shouldn't be used externally. Use [wrap] to ensure
   * that a batch exists when running a function.
   */
  EventBatch._internal() : summaries = new Map<int, EventSummary>();

  /**
   * Ensure there is an event batch where [userFunction] can accumulate events.
   * When the batch is complete, fire all events at once.
   */
  static Function wrap(userFunction(var a)) {
    return (e) {
      if (current == null) {
        // Not in a batch so create one.
        final batch = new EventBatch._internal();
        current = batch;
        var result = null;
        try {
          // TODO(jmesserly): don't return here, otherwise an exception in
          // the finally clause will cause it to rerun. See bug#5350131.
          result = userFunction(e);
        } finally {
          assert(current == batch); // no one should've changed this
          // TODO(jmesserly): VM doesn't seem to like nested try/finally, so
          // set current to null before _notify. That will ensure we're back
          // to the right state, even if _notify throws.
          current = null;
          batch._notify();
        }
        return result;
      } else {
        // Already in a batch, so just use it.
        // TODO(rnystrom): Re-entrant calls to wrap() are kind of hairy. They
        // can occur in at least one known place:
        // 1. You respond to an event handler by calling a function with wrap()
        //    (i.e. the normal way we wrap event handlers).
        // 2. In that handler, you spawn an XHR. You give it a callback which
        //    is also calling wrap, so that when it's later invoked, that is in
        //    a batch too.
        // 3. Because of an error the XHR fails and calls the callback
        //    immediately instead of unwinding the stack past the first wrap()
        //    and then calling it asynchronously.
        // This check handles that, but ideally we'd have a more elegant way of
        // notifying after a series of changes like a onEventHandlerFinished
        // event or something built into the DOM API.
        return userFunction(e);
      }
    };
  }

  /** Returns a unique global id for observable objects. */
  static int genUid() {
    if (nextUid == null) {
      nextUid = 1;
    }
    return nextUid++;
  }

  /** Retrieves the events associated with {@code obj}. */
  EventSummary getEvents(Observable obj) {
    int uid = obj.uid;
    EventSummary summary = summaries[uid];
    if (summary == null) {
      assert(!sealed);
      summary = new EventSummary(obj);
      summaries[uid] = summary;
    }
    return summary;
  }

  /** Fires all events at once. */
  void _notify() {
    assert(!sealed);
    sealed = true;
    for (final summary in summaries.values) {
      summary.notify();
    }
  }
}
