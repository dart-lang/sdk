// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:isolate';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

worker(message) {
  var uri = message[0];
  var replyTo = message[1];
  try {
    var url = Url.createObjectUrl(new Blob([''], 'application/javascript'));
    Url.revokeObjectUrl(url);
    replyTo.send('Hello from Worker');
  } catch (e) {
    replyTo.send('Error: $e');
  }
}

main() {
  useHtmlConfiguration();

  test('Use Worker API in Worker', () {
    var response = new ReceivePort();
    var remote = Isolate.spawn(worker, ['', response.sendPort]);
    remote.then((_) => response.first).then(
        expectAsync((reply) => expect(reply, equals('Hello from Worker'))));
  });
}
