// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

// Regression test for http://dartbug.com/27205
// If a yield-star completes while the stream is paused, it didn't resume.

main() {
  asyncStart();
  var c = new Completer();
  var s = yieldStream(mkStream());
  var sub;
  sub = s.listen((v) {
    sub.pause();
    print(v);
    Timer.run(sub.resume);
  }, onDone: () {
    print("DONE");
    c.complete(null);
  });

  c.future.whenComplete(asyncEnd);
}

Stream yieldStream(Stream s) async* {
  yield* s;
}

Stream mkStream() {
  var s = new StreamController(sync: true);
  // The close event has to be sent and received between
  // the pause and resume above.
  // Using a sync controller and a Timer.run(sub.resume) ensures this.
  Timer.run(() {
    s.add("event");
    s.close();
  });
  return s.stream;
}
