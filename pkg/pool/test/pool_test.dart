// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
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
      new FakeAsync().run((async) {
        var pool = new Pool(50);
        var requests = [];
        for (var i = 0; i < 50; i++) {
          expect(pool.request(), completes);
        }
        expect(pool.request(), doesNotComplete);

        async.elapse(new Duration(seconds: 1));
      });
    });

    test("a blocked resource is allocated when another is released", () {
      new FakeAsync().run((async) {
        var pool = new Pool(50);
        var requests = [];
        for (var i = 0; i < 49; i++) {
          expect(pool.request(), completes);
        }

        pool.request().then((lastAllocatedResource) {
          // This will only complete once [lastAllocatedResource] is released.
          expect(pool.request(), completes);

          new Future.delayed(new Duration(microseconds: 1)).then((_) {
            lastAllocatedResource.release();
          });
        });

        async.elapse(new Duration(seconds: 1));
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
      new FakeAsync().run((async) {
        var pool = new Pool(50);
        var requests = [];
        for (var i = 0; i < 50; i++) {
          pool.withResource(expectAsync(() => new Completer().future));
        }
        pool.withResource(expectNoAsync());

        async.elapse(new Duration(seconds: 1));
      });
    });

    test("a blocked resource is allocated when another is released", () {
      new FakeAsync().run((async) {
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

        new Future.delayed(new Duration(microseconds: 1)).then((_) {
          expect(blockedResourceAllocated, isFalse);
          completer.complete();
          return new Future.delayed(new Duration(microseconds: 1));
        }).then((_) {
          expect(blockedResourceAllocated, isTrue);
        });

        async.elapse(new Duration(seconds: 1));
      });
    });
  });

  group("with a timeout", () {
    test("doesn't time out if there are no pending requests", () {
      new FakeAsync().run((async) {
        var pool = new Pool(50, timeout: new Duration(seconds: 5));
        for (var i = 0; i < 50; i++) {
          expect(pool.request(), completes);
        }

        async.elapse(new Duration(seconds: 6));
      });
    });

    test("resets the timer if a resource is returned", () {
      new FakeAsync().run((async) {
        var pool = new Pool(50, timeout: new Duration(seconds: 5));
        for (var i = 0; i < 49; i++) {
          expect(pool.request(), completes);
        }

        pool.request().then((lastAllocatedResource) {
          // This will only complete once [lastAllocatedResource] is released.
          expect(pool.request(), completes);

          new Future.delayed(new Duration(seconds: 3)).then((_) {
            lastAllocatedResource.release();
            expect(pool.request(), doesNotComplete);
          });
        });

        async.elapse(new Duration(seconds: 6));
      });
    });

    test("resets the timer if a resource is requested", () {
      new FakeAsync().run((async) {
        var pool = new Pool(50, timeout: new Duration(seconds: 5));
        for (var i = 0; i < 50; i++) {
          expect(pool.request(), completes);
        }
        expect(pool.request(), doesNotComplete);

        new Future.delayed(new Duration(seconds: 3)).then((_) {
          expect(pool.request(), doesNotComplete);
        });

        async.elapse(new Duration(seconds: 6));
      });
    });    

    test("times out if nothing happens", () {
      new FakeAsync().run((async) {
        var pool = new Pool(50, timeout: new Duration(seconds: 5));
        for (var i = 0; i < 50; i++) {
          expect(pool.request(), completes);
        }
        expect(pool.request(), throwsA(new isInstanceOf<TimeoutException>()));

        async.elapse(new Duration(seconds: 6));
      });
    });    
  });
}

/// Returns a function that will cause the test to fail if it's called.
///
/// This should only be called within a [FakeAsync.run] zone.
Function expectNoAsync() {
  var stack = new Trace.current(1);
  return () => handleExternalError(
      new TestFailure("Expected function not to be called."), "",
      stack);
}

/// A matcher for Futures that asserts that they don't complete.
///
/// This should only be called within a [FakeAsync.run] zone.
Matcher get doesNotComplete => predicate((future) {
  expect(future, new isInstanceOf<Future>('Future'));

  var stack = new Trace.current(1);
  future.then((_) => handleExternalError(
      new TestFailure("Expected future not to complete."), "",
      stack));
  return true;
});
