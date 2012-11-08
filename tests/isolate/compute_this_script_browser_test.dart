// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that spawn works even when there are many script files in the page.
// This requires computing correctly the URL to the orignal script, so we can
// pass it to the web worker APIs.
library compute_this_script;

import 'dart:html';
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

child() {
  port.receive((msg, reply) {
    reply.send('re: $msg');
    port.close();
  });
}

main() {
  useHtmlConfiguration();
  var script = document.$dom_createElement('script');
  document.body.$dom_appendChild(script);
  test('spawn with other script tags in page', () {
    ReceivePort port = new ReceivePort();
    port.receive(expectAsync2((msg, _) {
      expect(msg, equals('re: hi'));
      port.close();
    }));

    SendPort s = spawnFunction(child);
    s.send('hi', port.toSendPort());
  });
}
