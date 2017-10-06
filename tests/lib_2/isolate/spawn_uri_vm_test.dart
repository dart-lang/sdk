// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of spawning an isolate from a URI
// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=spawn_uri_child_isolate.dart
library spawn_tests;

import 'dart:isolate';
import 'package:unittest/unittest.dart';

main() {
  test('isolate fromUri - send and reply', () {
    ReceivePort port = new ReceivePort();
    port.first.then(expectAsync((msg) {
      expect(msg, equals('re: hi'));
    }));

    Isolate.spawnUri(
        Uri.parse('spawn_uri_child_isolate.dart'), ['hi'], port.sendPort);
  });
}
