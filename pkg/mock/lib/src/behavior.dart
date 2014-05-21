// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.behavior;

import 'action.dart';
import 'call_matcher.dart';
import 'responder.dart';

/**
 * A [Behavior] represents how a [Mock] will respond to one particular
 * type of method call.
 */
class Behavior {
  CallMatcher matcher; // The method call matcher.
  List<Responder> actions; // The values to return/throw or proxies to call.
  bool logging = true;

  Behavior(this.matcher) {
    actions = new List<Responder>();
  }

  /**
   * Adds a [Responder] that returns a [value] for [count] calls
   * (1 by default).
   */
  Behavior thenReturn(value, [count = 1]) {
    actions.add(new Responder(value, count, Action.RETURN));
    return this; // For chaining calls.
  }

  /** Adds a [Responder] that repeatedly returns a [value]. */
  Behavior alwaysReturn(value) {
    return thenReturn(value, 0);
  }

  /**
   * Adds a [Responder] that throws [value] [count]
   * times (1 by default).
   */
  Behavior thenThrow(value, [count = 1]) {
    actions.add(new Responder(value, count, Action.THROW));
    return this; // For chaining calls.
  }

  /** Adds a [Responder] that throws [value] endlessly. */
  Behavior alwaysThrow(value) {
    return thenThrow(value, 0);
  }

  /**
   * [thenCall] creates a proxy Responder, that is called [count]
   * times (1 by default; 0 is used for unlimited calls, and is
   * exposed as [alwaysCall]). [value] is the function that will
   * be called with the same arguments that were passed to the
   * mock. Proxies can be used to wrap real objects or to define
   * more complex return/throw behavior. You could even (if you
   * wanted) use proxies to emulate the behavior of thenReturn;
   * e.g.:
   *
   *     m.when(callsTo('foo')).thenReturn(0)
   *
   * is equivalent to:
   *
   *     m.when(callsTo('foo')).thenCall(() => 0)
   */
  Behavior thenCall(value, [count = 1]) {
    actions.add(new Responder(value, count, Action.PROXY));
    return this; // For chaining calls.
  }

  /** Creates a repeating proxy call. */
  Behavior alwaysCall(value) {
    return thenCall(value, 0);
  }

  /** Returns true if a method call matches the [Behavior]. */
  bool matches(String method, List args) => matcher.matches(method, args);

  /** Returns the [matcher]'s representation. */
  String toString() => matcher.toString();
}
