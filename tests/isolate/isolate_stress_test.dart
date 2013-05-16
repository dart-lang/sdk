// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test creates a lot of isolates.  This is meant to exhaust
// resources if the isolates aren't closed correctly (which happened
// in dart2js).

import 'dart:async';
import 'dart:html';
import 'dart:isolate';

// TODO(ahe): Remove dependency on unittest when tests are wrapperless.
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

const bool IS_UNITTEST = true;

worker() {
  port.receive((String uri, SendPort replyTo) {
    replyTo.send('Hello from Worker');
    port.close();
  });
}

main() {
  useHtmlConfiguration();
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
      if (IS_UNITTEST) {
        doneClosure();
      } else {
        port.close();
        window.postMessage('unittest-suite-done', '*');
      }
      return;
    }
    spawnFunction(worker).call('').then(spawnMany);
    print('isolateCount = $isolateCount');
  }

  if (IS_UNITTEST) {
    test('stress test', () {
      spawnMany('Hello from Worker');
      doneClosure = expectAsync0(() {});
    });
  } else {
    spawnMany('Hello from Worker');
    window.postMessage('unittest-suite-wait-for-done', '*');
  }
}
