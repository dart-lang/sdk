// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

const String kHttpEnableTimelineLogging =
    'ext.dart.io.httpEnableTimelineLogging';

Future<void> setup() async {}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    await isolate.load();
    // Ensure all HTTP service extensions are registered.
    expect(isolate.extensionRPCs.length, greaterThanOrEqualTo(2));
    expect(isolate.extensionRPCs.contains(kHttpEnableTimelineLogging), isTrue);
  },
  (Isolate isolate) async {
    await isolate.load();
    var response =
        await isolate.invokeRpcNoUpgrade(kHttpEnableTimelineLogging, {});
    expect(response['type'], 'HttpTimelineLoggingState');
    expect(response['enabled'], false);

    response = await isolate
        .invokeRpcNoUpgrade(kHttpEnableTimelineLogging, {'enabled': true});
    expect(response['type'], 'HttpTimelineLoggingState');
    expect(response['enabled'], true);

    response = await isolate.invokeRpcNoUpgrade(kHttpEnableTimelineLogging, {});
    expect(response['type'], 'HttpTimelineLoggingState');
    expect(response['enabled'], true);

    response = await isolate
        .invokeRpcNoUpgrade(kHttpEnableTimelineLogging, {'enabled': false});
    expect(response['type'], 'HttpTimelineLoggingState');
    expect(response['enabled'], false);

    response = await isolate.invokeRpcNoUpgrade(kHttpEnableTimelineLogging, {});
    expect(response['type'], 'HttpTimelineLoggingState');
    expect(response['enabled'], false);
  },
  (Isolate isolate) async {
    // Bad argument.
    try {
      await isolate.invokeRpcNoUpgrade(
        kHttpEnableTimelineLogging,
        {'enabled': 'foo'},
      );
    } catch (e) {/* expected */}
    // Missing argument.
    try {
      await isolate.invokeRpcNoUpgrade(kHttpEnableTimelineLogging, {});
    } catch (e) {/* expected */}
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: setup);
