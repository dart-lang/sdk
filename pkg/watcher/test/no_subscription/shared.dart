// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/watcher.dart';

import '../utils.dart';

void sharedTests() {
  test('does not notify for changes when there are no subscribers', () {
    // Note that this test doesn't rely as heavily on the test functions in
    // utils.dart because it needs to be very explicit about when the event
    // stream is and is not subscribed.
    var watcher = createWatcher();

    // Subscribe to the events.
    var completer = new Completer();
    var subscription = watcher.events.listen(wrapAsync((event) {
      expect(event, isWatchEvent(ChangeType.ADD, "file.txt"));
      completer.complete();
    }));

    writeFile("file.txt");

    // Then wait until we get an event for it.
    schedule(() => completer.future);

    // Unsubscribe.
    schedule(() {
      subscription.cancel();
    });

    // Now write a file while we aren't listening.
    writeFile("unwatched.txt");

    // Then start listening again.
    schedule(() {
      completer = new Completer();
      subscription = watcher.events.listen(wrapAsync((event) {
        // We should get an event for the third file, not the one added while
        // we weren't subscribed.
        expect(event, isWatchEvent(ChangeType.ADD, "added.txt"));
        completer.complete();
      }));

      // Wait until the watcher is ready to dispatch events again.
      return watcher.ready;
    });

    // And add a third file.
    writeFile("added.txt");

    // Wait until we get an event for the third file.
    schedule(() => completer.future);

    schedule(() {
      subscription.cancel();
    });
  });
}
