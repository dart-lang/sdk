// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_io;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:vmservice';

part 'resources.dart';
part 'server.dart';

// The TCP port that the HTTP server listens on.
int _port;

// The VM service instance.
VMService service;

main() {
  // Get VMService.
  service = new VMService();
  // Start HTTP server.
  var server = new Server(service, _port);
  server.startServer();
}
