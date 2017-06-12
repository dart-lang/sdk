// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_launch_main;

import 'dart:isolate';
import 'dart:io';

main(List<String> arguments) {
  int port = int.parse(arguments[0]);
  ReceivePort receivePort = new ReceivePort();
  Isolate.spawnUri(Uri.parse('http://127.0.0.1:$port/http_isolate_main.dart'),
      ['hello'], receivePort.sendPort);
  receivePort.first.then((response) {
    print(response);
  });
}
