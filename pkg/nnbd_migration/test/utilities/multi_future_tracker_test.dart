// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:nnbd_migration/src/utilities/multi_future_tracker.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultiFutureTrackerTest);
  });
}

@reflectiveTest
class MultiFutureTrackerTest {
  MultiFutureTracker testTracker;

  tearDown() {
    // This will leak futures on certain kinds of test failures.  But it is
    // a test, so we don't care.
    testTracker = null;
  }

  Future<void> test_multiFutureBlocksOnLimit() async {
    var completer1 = Completer();

    testTracker = MultiFutureTracker(1);
    await testTracker.addFutureFromClosure(() => completer1.future);
    // The second future added shouldn't be executing until the first
    // future is complete.
    var secondInQueue = testTracker.addFutureFromClosure(() async {
      expect(completer1.isCompleted, isTrue);
    });

    completer1.complete();
    await secondInQueue;
    return await testTracker.wait();
  }

  Future<void> test_doesNotBlockWithoutLimit() async {
    var completer1 = Completer();

    // Limit is set above the number of futures we are adding.
    testTracker = MultiFutureTracker(10);
    await testTracker.addFutureFromClosure(() => completer1.future);
    // The second future added should be executing even though the first
    // future is not complete.  A test failure will time out.
    await testTracker.addFutureFromClosure(() async {
      expect(completer1.isCompleted, isFalse);
      completer1.complete();
    });

    return await testTracker.wait();
  }

  Future<void> test_runsSeriallyAtLowLimit() async {
    var completer1 = Completer();

    testTracker = MultiFutureTracker(1);
    var runFuture1 = testTracker.runFutureFromClosure(() => completer1.future);
    var runFuture2 = testTracker.runFutureFromClosure(() => null);

    // Both futures _should_ timeout.
    await expectLater(runFuture1.timeout(Duration(milliseconds: 1)),
        throwsA(TypeMatcher<TimeoutException>()));
    await expectLater(runFuture2.timeout(Duration(milliseconds: 1)),
        throwsA(TypeMatcher<TimeoutException>()));
    expect(completer1.isCompleted, isFalse);

    completer1.complete();

    // Now, these should complete normally.
    await runFuture1;
    await runFuture2;
  }

  Future<void> test_returnsValueFromRun() async {
    testTracker = MultiFutureTracker(1);
    await expectLater(
        await testTracker.runFutureFromClosure(() async => true), equals(true));
    await expectLater(
        await testTracker.runFutureFromClosure(() => true), equals(true));
  }
}
