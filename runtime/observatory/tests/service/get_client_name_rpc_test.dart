// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void fooBar() {}

Future<String> getClientName(Isolate isolate) async {
  final result = await isolate.vm.invokeRpcNoUpgrade('getClientName', {});
  return result['name'] as String;
}

Future<void> setClientName(Isolate isolate, String name) async =>
    await isolate.vm.invokeRpcNoUpgrade('setClientName', {
      'name': name,
    });

final test = <IsolateTest>[
  (Isolate isolate) async {
    // Each client has a default name based on the order of connection to the
    // service.
    expect(await getClientName(isolate), 'client1');

    // Set a custom client name and check it was set properly.
    await setClientName(isolate, 'foobar');
    expect(await getClientName(isolate), 'foobar');

    // Clear the client name and check that we're using the default again.
    await setClientName(isolate, '');
    expect(await getClientName(isolate), 'client1');
  },
];

Future<void> main(args) => runIsolateTests(
      args,
      test,
      testeeBefore: fooBar,
      enableService: false,
    );
