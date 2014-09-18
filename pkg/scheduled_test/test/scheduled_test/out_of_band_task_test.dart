// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/mock_clock.dart' as mock_clock;

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

  expectTestsPass("out-of-band schedule() runs its function immediately (but "
      "asynchronously)", () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        wrapFuture(sleep(1).then((_) {
          var nestedScheduleRun = false;
          schedule(() {
            nestedScheduleRun = true;
          });

          expect(nestedScheduleRun, isFalse);
          expect(pumpEventQueue().then((_) => nestedScheduleRun),
              completion(isTrue));
        }));
      });
    });
  });

  expectTestsPass("out-of-band schedule() calls block their parent queue", () {
    mock_clock.mock().run();
    test('test', () {
      var scheduleRun = false;
      wrapFuture(sleep(1).then((_) {
        schedule(() => sleep(1).then((_) {
          scheduleRun = true;
        }));
      }));

      currentSchedule.onComplete.schedule(() => expect(scheduleRun, isTrue));
    });
  });
}
