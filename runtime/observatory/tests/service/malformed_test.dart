// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) async {
    bool caughtException = false;
    try {
      await isolate.invokeRpc('_respondWithMalformedObject', {});
      expect(false, isTrue, reason: 'Unreachable');
    } on MalformedResponseRpcException catch (e) {
      caughtException = true;
      expect(e.message, equals("Response is missing the 'type' field"));
    }
    expect(caughtException, isTrue);
  },

  // Do this test last... it kills the vm connection.
  (Isolate isolate) async {
    bool caughtException = false;
    try {
      await isolate.invokeRpc('_respondWithMalformedJson', {});
      expect(false, isTrue, reason: 'Unreachable');
    } on NetworkRpcException catch (e) {
      caughtException = true;
      expect(
          e.message,
          startsWith("Canceling request: "
              "Connection saw corrupt JSON message: "
              "FormatException: Unexpected character"));
    }
    expect(caughtException, isTrue);
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      // This test hangs with DDS as package:json_rpc_2 can't parse the JSON
      // response and is unable to determine the request ID, so the malformed
      // JSON request will never complete.
      enableDds: false,
    );
