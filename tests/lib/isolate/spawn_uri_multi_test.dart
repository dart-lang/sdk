// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

void main() {
  asyncStart();
  var message = 'hi';
  ReceivePort port = new ReceivePort();
  port.first.then((response) {
    String expectedResponse = 're: $message';
    Expect.equals(expectedResponse, response);
    asyncEnd();
  });

  Isolate.spawnUri(Uri.parse('spawn_uri_child_isolate.dart'), [
    message,
  ], port.sendPort);
}
