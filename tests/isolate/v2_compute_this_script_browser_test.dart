// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that spawn works even when there are many script files in the page.
// This requires computing correctly the URL to the orignal script, so we can
// pass it to the web worker APIs.
#library('spawn_tests');

#import('dart:dom_deprecated');
#import('dart:isolate');

#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');

child() {
  port.receive((msg, reply) => reply.send('re: $msg'));
}

main() {
  useDomConfiguration();
  var script = document.createElement('script');
  document.body.appendChild(script);
  test('spawn with other script tags in page', () {
    ReceivePort port = new ReceivePort();
    port.receive(expectAsync2((msg, _) {
      expect(msg).equals('re: hi');
      port.close();
    }));

    SendPort s = spawnFunction(child);
    s.send('hi', port.toSendPort());
  });
}
