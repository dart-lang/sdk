// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:async_helper/async_helper.dart";

/// This test verifies that an await for loop sends the correct
/// signals to the stream it iterates over:
/// 1) A listen event.
/// 2) A pause event when the loop body is awaiting something,
///    and more elements arrive on the stream.  See issue
///    https://github.com/dart-lang/sdk/issues/23996 .
/// 3) A resume event, when the loop is again ready to iterate.
main() {
  Completer listenEventReceived = new Completer();
  Completer pauseEventReceived = new Completer();
  Completer resumeEventReceived = new Completer();
  StreamController controller = new StreamController(
      onListen: () => listenEventReceived.complete(),
      onPause: () => pauseEventReceived.complete(),
      onResume: () => resumeEventReceived.complete());

  Completer forLoopEntered = new Completer();

  /// The send function puts items on the stream. It waits for a
  /// listener, puts "first" on the stream, waits for the for loop
  /// to start (and eventually block), puts "second" on the stream
  /// multiple times, letting the event loop run, until the for loop
  /// pauses the stream because it it blocked.
  /// The for loop unblocks after the pause message is received, and
  /// reads the stream items, sending a stream resume message when it
  /// is ready for more.
  /// Then the send function puts a final "third" on the stream, and
  /// closes the stream.
  send() async {
    await listenEventReceived.future;
    controller.add('first');
    await forLoopEntered.future;
    var timer = new Timer.periodic(new Duration(milliseconds: 10), (timer) {
      controller.add('second');
    });
    await pauseEventReceived.future;
    // pauseEventReceived.future completes when controller.stream is
    // paused by the await-for loop below. What's specified is that
    // await-for must pause immediately on an "await", but instead
    // the implementations agree on not pausing until receiving the
    // next event. For this reason, [timer] will call its callback at
    // least once before we cancel it again.
    timer.cancel();
    await resumeEventReceived.future;
    controller.add('third');
    controller.close();
  }

  receive() async {
    bool thirdReceived = false;
    await for (var entry in controller.stream) {
      if (entry == 'first') {
        forLoopEntered.complete();
        await pauseEventReceived.future;
      } else if (entry == 'third') {
        thirdReceived = true;
      }
    }
    if (!thirdReceived) {
      throw "Error in await-for loop: 'third' not received";
    }
  }

  asyncTest(() async {
    // We need to start both functions in parallel, and wait on them both.
    var f = send();
    await receive();
    await f;
  });
}
