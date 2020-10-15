// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

// Tests that the --enable-service-port-fallback flag works correctly by trying to bind to
// a port that is unsupported.
var tests = <VMTest>[
  (VM vm) async {
    // Did not bind to provided port.
    expect(Uri.parse(serviceHttpAddress).port != portNumber, true);
    await socket.close();
  }
];

late ServerSocket socket;
int portNumber = -1;

main(args) async {
  socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  portNumber = socket.port;
  return runVMTests(args, tests,
      enable_service_port_fallback: true, port: portNumber, extraArgs: []);
}
