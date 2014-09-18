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

  expectTestsFail('an out-of-band error reported via signalError is '
      'handled', () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        sleep(1).then((_) => currentSchedule.signalError('bad'));
      });
      schedule(() => sleep(2));
    });
  });

  expectTestsFail('an out-of-band error reported via signalError that finished '
      'after the schedule is handled', () {
    mock_clock.mock().run();
    test('test', () {
      schedule(() {
        var done = wrapAsync((_) {});
        sleep(2).then((_) {
          currentSchedule.signalError('bad');
          done(null);
        });
      });
      schedule(() => sleep(1));
    });
  });

  expectTestsFail('a synchronous error reported via signalError is handled', () {
    test('test', () {
      currentSchedule.signalError('bad');
    });
  });
}
