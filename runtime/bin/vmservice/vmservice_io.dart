// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_io;

import 'dart:io';
import 'vmservice.dart';

part 'server.dart';

// The TCP port that the HTTP server listens on.
int _port;

// The receive port that isolate startup / shutdown messages are delivered on.
RawReceivePort _receivePort;

main() {
  // Create VmService.
  var service = new VMService();
  _receivePort = service.receivePort;
  // Start HTTP server.
  var server = new Server(service, _port);
  server.startServer();
}
