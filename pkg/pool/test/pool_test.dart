// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:pool/pool.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/unittest.dart';

void main() {
  group("request()", () {
    test("resources can be requested freely up to the limit", () {
      var pool = new Pool(50);
      var requests = [];
      for (var i = 0; i < 50; i++) {
        expect(pool.request(), completes);
      }
    });

    test("resources block past the limit", () {
      var pool = new Pool(50);
      var requests = [];
      for (var i = 0; i < 50; i++) {
        expect(pool.request(), completes);
      }
      expect(pool.request(), doesNotComplete);
    });

    test("a blocked resource is allocated when another is released", () {
      var pool = new Pool(50);
      var requests = [];
      for (var i = 0; i < 49; i++) {
        expect(pool.request(), completes);
      }

      return pool.request().then((lastAllocatedResource) {
        var blockedResource = pool.request();

        return pumpEventQueue().then((_) {
          lastAllocatedResource.release();
          return pumpEventQueue();
        }).then((_) {
          expect(blockedResource, completes);
        });
      });
    });
  });

  group("withResource()", () {
    test("can be called freely up to the limit", () {
      var pool = new Pool(50);
      var requests = [];
      for (var i = 0; i < 50; i++) {
        pool.withResource(expectAsync(() => new Completer().future));
      }
    });

    test("blocks the callback past the limit", () {
      var pool = new Pool(50);
      var requests = [];
      for (var i = 0; i < 50; i++) {
        pool.withResource(expectAsync(() => new Completer().future));
      }
      pool.withResource(expectNoAsync());
    });

    test("a blocked resource is allocated when another is released", () {
      var pool = new Pool(50);
      var requests = [];
      for (var i = 0; i < 49; i++) {
        pool.withResource(expectAsync(() => new Completer().future));
      }

      var completer = new Completer();
      var lastAllocatedResource = pool.withResource(() => completer.future);
      var blockedResourceAllocated = false;
      var blockedResource = pool.withResource(() {
        blockedResourceAllocated = true;
      });

      return pumpEventQueue().then((_) {
        expect(blockedResourceAllocated, isFalse);
        completer.complete();
        return pumpEventQueue();
      }).then((_) {
        expect(blockedResourceAllocated, isTrue);
      });
    });
  });

  // TODO(nweiz): test timeouts when seaneagan's fake_async package lands.
}

/// Returns a [Future] that completes after pumping the event queue [times]
/// times. By default, this should pump the event queue enough times to allow
/// any code to run, as long as it's not waiting on some external event.
Future pumpEventQueue([int times = 20]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

/// Returns a function that will cause the test to fail if it's called.
///
/// This won't let the test complete until it's confident that the function
/// won't be called.
Function expectNoAsync() {
  // Make sure the test lasts long enough for the function to get called if it's
  // going to get called.
  expect(pumpEventQueue(), completes);

  var stack = new Trace.current(1);
  return () => handleExternalError(
      new TestFailure("Expected function not to be called."), "",
      stack);
}

/// A matcher for Futures that asserts that they don't complete.
///
/// This won't let the test complete until it's confident that the function
/// won't be called.
Matcher get doesNotComplete => predicate((future) {
  expect(future, new isInstanceOf<Future>('Future'));
  // Make sure the test lasts long enough for the function to get called if it's
  // going to get called.
  expect(pumpEventQueue(), completes);

  var stack = new Trace.current(1);
  future.then((_) => handleExternalError(
      new TestFailure("Expected future not to complete."), "",
      stack));
  return true;
});
