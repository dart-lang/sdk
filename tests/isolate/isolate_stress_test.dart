// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test creates a lot of isolates.  This is meant to exhaust
// resources if the isolates aren't closed correctly (which happened
// in dart2js).

import 'dart:async';
import 'dart:isolate';

// TODO(ahe): Remove this import when we have wrapper-less testing.
import 'dart:html';

worker() {
  port.receive((String uri, SendPort replyTo) {
    replyTo.send('Hello from Worker');
    port.close();
  });
}

main() {
  try {
    // Create a Worker to confuse broken isolate implementation in dart2js.
    new Worker('data:application/javascript,').terminate();
  } catch (e) {
    // Ignored.
  }
  var doneClosure;
  int isolateCount = 0;
  spawnMany(reply) {
    if (reply != 'Hello from Worker') {
      throw new Exception('Unexpected reply from worker: $reply');
    }
    if (++isolateCount > 200) {
      port.close();
      window.postMessage('unittest-suite-success', '*');
      return;
    }
    spawnFunction(worker).call('').then(spawnMany);
    print('isolateCount = $isolateCount');
  }

  spawnMany('Hello from Worker');
  window.postMessage('unittest-suite-wait-for-done', '*');
}
