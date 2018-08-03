// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that spawn works even when there are many script files in the page.
// This requires computing correctly the URL to the orignal script, so we can
// pass it to the web worker APIs.
library compute_this_script;

import 'dart:html';
import 'dart:isolate';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import "../remote_unittest_helper.dart";

child(var message) {
  var data = message[0];
  var reply = message[1];
  reply.send('re: $data');
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  useHtmlConfiguration();
  var script = new ScriptElement();
  document.body.append(script);
  test('spawn with other script tags in page', () {
    ReceivePort port = new ReceivePort();
    port.listen(expectAsync((msg) {
      expect(msg, equals('re: hi'));
      port.close();
    }));

    Isolate.spawn(child, ['hi', port.sendPort]);
  });
}
