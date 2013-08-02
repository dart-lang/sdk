// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/watcher.dart';

import 'utils.dart';

main() {
  initConfig();

  setUp(createSandbox);

  test('does not notify for changes when there were no subscribers', () {
    // Note that this test doesn't rely as heavily on the test functions in
    // utils.dart because it needs to be very explicit about when the event
    // stream is and is not subscribed.
    var watcher = createWatcher();

    // Subscribe to the events.
    var completer = new Completer();
    var subscription = watcher.events.listen(wrapAsync((event) {
      expect(event.type, equals(ChangeType.ADD));
      expect(event.path, endsWith("file.txt"));
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
        expect(event.type, equals(ChangeType.ADD));
        expect(event.path, endsWith("added.txt"));
        completer.complete();
      }));
    });

    // The watcher will have been cancelled and then resumed in the middle of
    // its pause between polling loops. That means the second scan to skip
    // what changed while we were unsubscribed won't happen until after that
    // delay is done. Wait long enough for that to happen.
    schedule(() => new Future.delayed(watcher.pollingDelay * 2));

    // And add a third file.
    writeFile("added.txt");

    // Wait until we get an event for the third file.
    schedule(() => completer.future);

    schedule(() {
      subscription.cancel();
    });
  });
}
