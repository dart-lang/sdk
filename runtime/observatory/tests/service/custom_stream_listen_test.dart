// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

Future streamListen(VM vm, String streamId) async =>
    await vm.invokeRpcNoUpgrade(
      'streamListen',
      {
        'streamId': streamId,
      },
    );

var tests = <VMTest>[
  // Ensure the VM Service throws an exception when encountering a custom
  // stream.
  (VM vm) async {
    try {
      await streamListen(vm, 'Foo');
    } on ServerRpcException catch (e) {
      expect(e.message, "streamListen: invalid 'streamId' parameter: Foo");
    }
  }
];

main(args) => runVMTests(
      args,
      tests,
      enableService: true,
      enableDds: false,
    );
