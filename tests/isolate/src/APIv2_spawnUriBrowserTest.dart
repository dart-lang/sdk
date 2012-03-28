// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of spawning an isolate from a URI
// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=APIv2_spawnUriChildIsolate.dart
#library('spawn_tests');
#import('../../../lib/unittest/unittest_dom.dart');
#import('dart:dom'); // import added so test.dart can treat this as a webtest.
#import('dart:isolate');

main() {
  asyncTest('isolate fromUri - send and reply', 1, () {
    ReceivePort port = new ReceivePort();
    port.receive((msg, _) {
      expect(msg).equals('re: hi');
      port.close();
      callbackDone();
    });

    // TODO(eub): make this work for non-JS targets.
    SendPort s = spawnUri('APIv2_spawnUriChildIsolate.js');
    s.send('hi', port.toSendPort());
  });
}
