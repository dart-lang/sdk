// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

// Tests that the --enable-service-port-fallback flag works correctly by trying to bind to
// a port that is available.
var tests = <VMTest>[
  (VM vm) async {
    // Correctly bound to provided port.
    expect(Uri.parse(serviceHttpAddress).port == selectedPort, true);
  }
];

int selectedPort = 0;

main(args) async {
  selectedPort = await _getUnusedPort();
  await runVMTests(
    args, tests,
    enable_service_port_fallback: true,
    // Choose a port number that should always be open.
    port: selectedPort,
    extraArgs: [],
    // TODO(bkonyi): investigate failure.
    enableDds: false,
  );
}

Future<int> _getUnusedPort() async {
  var socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
  var port = socket.port;
  await socket.close();
  return port;
}
