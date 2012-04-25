// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Negative test to make sure that we are reaching all assertions.
// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=APIv2_spawnUriChildIsolate.dart
#library('spawn_tests');
#import('../../../lib/unittest/unittest.dart');
#import('dart:isolate');

main() {
  test('isolate fromUri - negative test', () {
    ReceivePort port = new ReceivePort();
    port.receive(expectAsync2((msg, _) {
      expect(msg).equals('re: hello'); // should be hi, not hello
      port.close();
    }));

    // TODO(eub): make this work for non-JS targets.
    SendPort s = spawnUri('APIv2_spawnUriChildIsolate.js');
    s.send('hi', port.toSendPort());
  });
}
