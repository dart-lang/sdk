// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:isolate';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

worker() {
  port.receive((String uri, SendPort replyTo) {
    try {
      var url = Url.createObjectUrl(new Blob([''], 'application/javascript'));
      Url.revokeObjectUrl(url);
      replyTo.send('Hello from Worker');
    } catch (e) {
      replyTo.send('Error: $e');
    }
    port.close();
  });
}

main() {
  useHtmlConfiguration();

  test('Use Worker API in Worker', () {
    spawnFunction(worker).call('').then(
        expectAsync1((reply) => expect(reply, equals('Hello from Worker'))));
  });
}
