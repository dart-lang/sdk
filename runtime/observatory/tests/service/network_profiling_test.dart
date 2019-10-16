// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:observatory/sample_profile.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

void test() {
  // TODO(bkonyi): do actual network operations.
  print('hello world!');
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    await isolate.load();

    // Ensure all network profiling service extensions are registered.
    const kGetHttpProfileRPC = 'ext.dart.io.getHttpProfile';
    const kGetSocketProfileRPC = 'ext.dart.io.getSocketProfile';
    expect(isolate.extensionRPCs.length, greaterThanOrEqualTo(2));
    expect(isolate.extensionRPCs.contains(kGetHttpProfileRPC), isTrue);
    expect(isolate.extensionRPCs.contains(kGetSocketProfileRPC), isTrue);

    // Test invocations (will throw on failure).
    var response = await isolate.invokeRpcNoUpgrade(kGetHttpProfileRPC, {});
    expect(response['type'], 'HttpProfile');
    response = await isolate.invokeRpcNoUpgrade(kGetSocketProfileRPC, {});
    expect(response['type'], 'SocketProfile');
  },
];

main(args) async => runIsolateTests(args, tests, testeeConcurrent: test);
