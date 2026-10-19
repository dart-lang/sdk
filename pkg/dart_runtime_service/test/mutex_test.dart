// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';

void main() {
  group('Mutex', () {
    test('runGuarded executes critical sections in FIFO order', () async {
      final mutex = Mutex();
      final events = <String>[];
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();

      final future1 = mutex.runGuarded(() async {
        events.add('start1');
        await completer1.future;
        events.add('end1');
        return 1;
      });

      final future2 = mutex.runGuarded(() async {
        events.add('start2');
        await completer2.future;
        events.add('end2');
        return 2;
      });

      final future3 = mutex.runGuarded(() {
        events.add('start3');
        events.add('end3');
        return 3;
      });

      await pumpEventQueue();
      expect(events, ['start1']);

      completer1.complete();
      await pumpEventQueue();
      expect(events, ['start1', 'end1', 'start2']);

      completer2.complete();
      final results = await Future.wait([future1, future2, future3]);
      expect(results, [1, 2, 3]);
      expect(events, ['start1', 'end1', 'start2', 'end2', 'start3', 'end3']);
    });

    test(
      'runGuardedWeak allows concurrent weak guards and blocks strong guards',
      () async {
        final mutex = Mutex();
        final events = <String>[];
        final weakCompleter1 = Completer<void>();
        final weakCompleter2 = Completer<void>();

        final weak1 = mutex.runGuardedWeak(() async {
          events.add('weak1_start');
          await weakCompleter1.future;
          events.add('weak1_end');
        });

        final weak2 = mutex.runGuardedWeak(() async {
          events.add('weak2_start');
          await weakCompleter2.future;
          events.add('weak2_end');
        });

        await pumpEventQueue();
        expect(events, ['weak1_start', 'weak2_start']);

        final strong = mutex.runGuarded(() {
          events.add('strong');
        });

        await pumpEventQueue();
        expect(events, ['weak1_start', 'weak2_start']);

        weakCompleter1.complete();
        await pumpEventQueue();
        expect(events, ['weak1_start', 'weak2_start', 'weak1_end']);

        weakCompleter2.complete();
        await Future.wait([weak1, weak2, strong]);
        expect(events, [
          'weak1_start',
          'weak2_start',
          'weak1_end',
          'weak2_end',
          'strong',
        ]);
      },
    );

    test('runGuardedWeak queued behind runGuarded does not deadlock subsequent '
        'callers', () async {
      final mutex = Mutex();
      final events = <String>[];
      final strong1Completer = Completer<void>();
      final weak1Completer = Completer<void>();
      final weak2Completer = Completer<void>();

      final strong1 = mutex.runGuarded(() async {
        events.add('strong1_start');
        await strong1Completer.future;
        events.add('strong1_end');
      });

      await pumpEventQueue();
      expect(events, ['strong1_start']);

      // Queue two weak guards and a second strong guard behind strong1.
      final weak1 = mutex.runGuardedWeak(() async {
        events.add('weak1_start');
        await weak1Completer.future;
        events.add('weak1_end');
      });
      final weak2 = mutex.runGuardedWeak(() async {
        events.add('weak2_start');
        await weak2Completer.future;
        events.add('weak2_end');
      });
      final strong2 = mutex.runGuarded(() {
        events.add('strong2');
      });

      await pumpEventQueue();
      expect(events, ['strong1_start']);

      // Release strong1; both weak1 and weak2 should start concurrently,
      // while strong2 must wait until both weak1 and weak2 complete.
      strong1Completer.complete();
      await pumpEventQueue();
      expect(events, [
        'strong1_start',
        'strong1_end',
        'weak1_start',
        'weak2_start',
      ]);

      weak1Completer.complete();
      await pumpEventQueue();
      expect(events, [
        'strong1_start',
        'strong1_end',
        'weak1_start',
        'weak2_start',
        'weak1_end',
      ]);

      weak2Completer.complete();
      await Future.wait([
        strong1,
        weak1,
        weak2,
        strong2,
      ]).timeout(const Duration(seconds: 5));
      expect(events, [
        'strong1_start',
        'strong1_end',
        'weak1_start',
        'weak2_start',
        'weak1_end',
        'weak2_end',
        'strong2',
      ]);
    });

    test('releases lock when criticalSection throws in runGuarded or '
        'runGuardedWeak', () async {
      final mutex = Mutex();

      await expectLater(
        mutex.runGuarded<void>(() => throw StateError('strong failure')),
        throwsStateError,
      );

      await expectLater(
        mutex.runGuardedWeak<void>(() => throw StateError('weak failure')),
        throwsStateError,
      );

      final result = await mutex
          .runGuarded(() => 'recovered')
          .timeout(const Duration(seconds: 5));
      expect(result, 'recovered');
    });
  });
}
