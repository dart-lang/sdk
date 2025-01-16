// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of spawning an isolate from a URI

import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  asyncStart();
  ReceivePort port = new ReceivePort();
  port.first.then((msg) {
    Expect.equals('re: hi', msg);
    asyncEnd();
  });

  Isolate.spawnUri(Uri.parse('spawn_uri_child_isolate.dart'), [
    'hi',
  ], port.sendPort);
}
