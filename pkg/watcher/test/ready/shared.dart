// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

void sharedTests() {
  test('ready does not complete until after subscription', () {
    var watcher = createWatcher(waitForReady: false);

    var ready = false;
    watcher.ready.then((_) {
      ready = true;
    });

    // Should not be ready yet.
    schedule(() {
      expect(ready, isFalse);
    });

    // Subscribe to the events.
    schedule(() {
      var subscription = watcher.events.listen((event) {});

      currentSchedule.onComplete.schedule(() {
        subscription.cancel();
      });
    });

    // Should eventually be ready.
    schedule(() => watcher.ready);

    schedule(() {
      expect(ready, isTrue);
    });
  });

  test('ready completes immediately when already ready', () {
    var watcher = createWatcher(waitForReady: false);

    // Subscribe to the events.
    schedule(() {
      var subscription = watcher.events.listen((event) {});

      currentSchedule.onComplete.schedule(() {
        subscription.cancel();
      });
    });

    // Should eventually be ready.
    schedule(() => watcher.ready);

    // Now ready should be a future that immediately completes.
    var ready = false;
    schedule(() {
      watcher.ready.then((_) {
        ready = true;
      });
    });

    schedule(() {
      expect(ready, isTrue);
    });
  });

  test('ready returns a future that does not complete after unsubscribing', () {
    var watcher = createWatcher(waitForReady: false);

    // Subscribe to the events.
    var subscription;
    schedule(() {
      subscription = watcher.events.listen((event) {});
    });

    var ready = false;

    // Wait until ready.
    schedule(() => watcher.ready);

    // Now unsubscribe.
    schedule(() {
      subscription.cancel();

      // Track when it's ready again.
      ready = false;
      watcher.ready.then((_) {
        ready = true;
      });
    });

    // Should be back to not ready.
    schedule(() {
      expect(ready, isFalse);
    });
  });
}
