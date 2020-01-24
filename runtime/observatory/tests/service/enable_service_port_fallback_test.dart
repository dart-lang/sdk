// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

// Tests that the --enable-service-port-fallback flag works correctly by trying to bind to
// a port that is unsupported.
var tests = <VMTest>[
  (VM vm) async {
    // Did not bind to provided port.
    expect(Uri.parse(serviceHttpAddress).port != 1, true);
  }
];

main(args) => runVMTests(args, tests,
    enable_service_port_fallback: true,
    // Choose a port number that most machines do not have permission
    // to bind to.
    port: 1,
    extraArgs: []);
