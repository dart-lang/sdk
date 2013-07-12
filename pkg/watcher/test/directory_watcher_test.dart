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

  test('does not notify for files that already exist when started', () {
    // Make some pre-existing files.
    writeFile("a.txt");
    writeFile("b.txt");

    createWatcher();

    // Change one after the watcher is running.
    writeFile("b.txt", contents: "modified");

    // We should get a modify event for the changed file, but no add events
    // for them before this.
    expectModifyEvent("b.txt");
  });

  test('notifies when a file is added', () {
    createWatcher();
    writeFile("file.txt");
    expectAddEvent("file.txt");
  });

  test('notifies when a file is modified', () {
    writeFile("file.txt");
    createWatcher();
    writeFile("file.txt", contents: "modified");
    expectModifyEvent("file.txt");
  });

  test('notifies when a file is removed', () {
    writeFile("file.txt");
    createWatcher();
    deleteFile("file.txt");
    expectRemoveEvent("file.txt");
  });

  test('notifies when a file is moved', () {
    writeFile("old.txt");
    createWatcher();
    renameFile("old.txt", "new.txt");
    expectAddEvent("new.txt");
    expectRemoveEvent("old.txt");
  });

  test('notifies when a file is modified multiple times', () {
    writeFile("file.txt");
    createWatcher();
    writeFile("file.txt", contents: "modified");
    expectModifyEvent("file.txt");
    writeFile("file.txt", contents: "modified again");
    expectModifyEvent("file.txt");
  });

  test('does not notify if the file contents are unchanged', () {
    writeFile("a.txt", contents: "same");
    writeFile("b.txt", contents: "before");
    createWatcher();
    writeFile("a.txt", contents: "same");
    writeFile("b.txt", contents: "after");
    expectModifyEvent("b.txt");
  });

  test('does not notify if the modification time did not change', () {
    writeFile("a.txt", contents: "before");
    writeFile("b.txt", contents: "before");
    createWatcher();
    writeFile("a.txt", contents: "after", updateModified: false);
    writeFile("b.txt", contents: "after");
    expectModifyEvent("b.txt");
  });

  test('watches files in subdirectories', () {
    createWatcher();
    writeFile("a/b/c/d/file.txt");
    expectAddEvent("a/b/c/d/file.txt");
  });

  test('does not notify for changes when there were no subscribers', () {
    // Note that this test doesn't rely as heavily on the test functions in
    // utils.dart because it needs to be very explicit about when the event
    // stream is and is not subscribed.
    var watcher = createWatcher();

    // Subscribe to the events.
    var completer = new Completer();
    var subscription = watcher.events.listen((event) {
      expect(event.type, equals(ChangeType.ADD));
      expect(event.path, endsWith("file.txt"));
      completer.complete();
    });

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
      subscription = watcher.events.listen((event) {
        // We should get an event for the third file, not the one added while
        // we weren't subscribed.
        expect(event.type, equals(ChangeType.ADD));
        expect(event.path, endsWith("added.txt"));
        completer.complete();
      });
    });

    // The watcher will have been cancelled and then resumed in the middle of
    // its pause between polling loops. That means the second scan to skip
    // what changed while we were unsubscribed won't happen until after that
    // delay is done. Wait long enough for that to happen.
    schedule(() => new Future.delayed(new Duration(seconds: 1)));

    // And add a third file.
    writeFile("added.txt");

    // Wait until we get an event for the third file.
    schedule(() => completer.future);

    schedule(() {
      subscription.cancel();
    });
  });


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
