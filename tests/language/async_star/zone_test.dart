// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an `async*` stream continues running in the same zone after a yield.
// Tries to pause, resume or cancel it from another zone.

import "dart:async";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

String get zoneId => Zone.current[#id] ?? '<unknown>';

void main() async {
  asyncStart();
  String testName = "";

  Stream<int> makeStream(int n) async* {
    Zone zone = Zone.current;
    Expect.equals('outer', zoneId, 'expected start zone: $zoneId');
    try {
      for (var i = 0; i < n; i++) {
        yield i;
        Expect.equals(
          zone,
          Zone.current,
          '$testName: current zone after yield: $zoneId',
        );
      }
    } finally {
      Expect.equals(
        zone,
        Zone.current,
        '$testName: current zone at end or after cancel: $zoneId',
      );
    }
  }

  Stream<int> repeatStream(int n, {int recurse = 1}) async* {
    Zone zone = Zone.current;
    try {
      yield* (recurse > 1
          ? repeatStream(n, recurse: recurse - 1)
          : makeStream(n));
    } finally {
      Expect.equals(
        zone,
        Zone.current,
        '$testName: current zone after yield*: $zoneId',
      );
    }
  }

  // Sibling zone of zone where tests are run.
  final parallelZone = Zone.current.fork(zoneValues: {#id: 'parallel'});
  // Run tests in zone with `zoneId == 'outer'`.
  await runZoned<Future<void>>(zoneValues: {#id: 'outer'}, () async {
    // Nested zone with different zone-ID.
    Zone nestedZone = Zone.current.fork(zoneValues: {#id: "nested"});

    Future<void> testPause(
      String name,
      Stream<int> stream,
      int count,
      Zone otherZone,
    ) {
      testName = "$name-pause";
      print(testName);
      Expect.equals('outer', zoneId, testName); // Sanity check.
      var done = Completer<void>();
      var expected = 0;
      var subscription = stream.listen(
        null,
        onError: done.completeError,
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
      subscription.onData((value) {
        Expect.equals(expected, value, name);
        expected++;
        if (expected > count) Expect.fail("$name: too many events");
        otherZone.run(() {
          subscription.pause(); // Pause in different zone.
        });
        Timer(Duration.zero, () {
          subscription.resume(); // Resume later (in original zone)
        });
      });
      return done.future;
    }

    await testPause('nested-make', makeStream(5), 5, nestedZone);
    await testPause('nested-repeat', repeatStream(5), 5, nestedZone);
    await testPause(
      'nested-repeat-2',
      repeatStream(5, recurse: 2),
      5,
      nestedZone,
    );

    await testPause('parallel-make', makeStream(5), 5, parallelZone);
    await testPause('parallel-repeat', repeatStream(5), 5, parallelZone);
    await testPause(
      'parallel-repeat-2',
      repeatStream(5, recurse: 2),
      5,
      parallelZone,
    );

    Future<void> testResume(
      String name,
      Stream<int> stream,
      int count,
      Zone otherZone,
    ) {
      testName = "$name-resume";
      print(testName);
      Expect.equals('outer', zoneId, testName); // Sanity check.
      var done = Completer<void>();
      var expected = 0;
      var subscription = stream.listen(
        null,
        onError: done.completeError,
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
      subscription.onData((value) {
        Expect.equals(expected, value, name);
        expected++;
        if (expected > count) Expect.fail("$name: too many events");
        subscription.pause();
        otherZone.scheduleMicrotask(() {
          subscription.resume();
        });
      });
      return done.future;
    }

    await testResume('nested-make', makeStream(5), 5, nestedZone);
    await testResume('nested-repeat', repeatStream(5), 5, nestedZone);
    await testResume(
      'nested-repeat-2',
      repeatStream(5, recurse: 2),
      5,
      nestedZone,
    );

    await testResume('parallel-make', makeStream(5), 5, parallelZone);
    await testResume('parallel-repeat', repeatStream(5), 5, parallelZone);
    await testResume(
      'parallel-repeat-2',
      repeatStream(5, recurse: 2),
      5,
      parallelZone,
    );

    Future<void> testResumeFuture(
      String name,
      Stream<int> stream,
      int count,
      Zone otherZone,
    ) {
      testName = '$name-resume-future';
      print(testName);
      Expect.equals('outer', zoneId, testName); // Sanity check.
      var done = Completer<void>();
      var expected = 0;
      var subscription = stream.listen(
        null,
        onError: done.completeError,
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
      subscription.onData((value) {
        Expect.equals(expected, value, name);
        expected++;
        if (expected > count) Expect.fail("$name: too many events");
        otherZone.run(() {
          subscription.pause(Future<void>.microtask(() {}));
        });
      });
      return done.future;
    }

    await testResumeFuture('nested-make', makeStream(5), 5, nestedZone);
    await testResumeFuture('nested-repeat', repeatStream(5), 5, nestedZone);
    await testResumeFuture(
      'nested-repeat-2',
      repeatStream(5, recurse: 2),
      5,
      nestedZone,
    );

    await testResumeFuture('parallel-make', makeStream(5), 5, parallelZone);
    await testResumeFuture('parallel-repeat', repeatStream(5), 5, parallelZone);
    await testResumeFuture(
      'parallel-repeat-2',
      repeatStream(5, recurse: 2),
      5,
      parallelZone,
    );

    Future<void> testCancel(
      String name,
      Stream<int> stream,
      int count,
      Zone otherZone,
    ) {
      testName = '$name-cancel';
      print(testName);
      Expect.equals('outer', zoneId, testName); // Sanity check.
      var done = Completer<void>();
      var expected = 0;
      var subscription = stream.listen(
        null,
        onError: done.completeError,
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
      subscription.onData((value) {
        Expect.equals(expected, value, name);
        expected++;
        if (expected == count) {
          otherZone.run(() {
            done.complete(subscription.cancel());
          });
        }
      });
      return done.future;
    }

    await testCancel('nested-make', makeStream(5), 5, nestedZone);
    await testCancel('nested-repeat', repeatStream(5), 5, nestedZone);
    await testCancel(
      'nested-repeat-2',
      repeatStream(5, recurse: 2),
      5,
      nestedZone,
    );

    await testCancel('parallel-make', makeStream(5), 5, parallelZone);
    await testCancel('parallel-repeat', repeatStream(5), 5, parallelZone);
    await testCancel(
      'parallel-repeat-2',
      repeatStream(5, recurse: 2),
      5,
      parallelZone,
    );

    asyncEnd();
  });
}
