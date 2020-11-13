// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:expect/expect.dart';
import 'package:observatory/service_io.dart';
import 'package:observatory/sample_profile.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

Future<ServiceExtensionResponse> Handler(String method, Map paremeters) {
  print('Invoked extension: $method');
  switch (method) {
    case 'ext..delay':
      var c = new Completer<ServiceExtensionResponse>();
      new Timer(new Duration(seconds: 1), () {
        c.complete(new ServiceExtensionResponse.result(jsonEncode({
          'type': '_delayedType',
          'method': method,
          'parameters': paremeters,
        })));
      });
      return c.future;
    case 'ext..error':
      return new Future<ServiceExtensionResponse>.value(
          new ServiceExtensionResponse.error(
              ServiceExtensionResponse.extensionErrorMin, 'My error detail.'));
    case 'ext..exception':
      throw "I always throw!";
    case 'ext..success':
      return new Future<ServiceExtensionResponse>.value(
          new ServiceExtensionResponse.result(jsonEncode({
        'type': '_extensionType',
        'method': method,
        'parameters': paremeters,
      })));
  }
  throw "Unknown extension: $method";
}

void test() {
  registerExtension('ext..delay', Handler);
  debugger();
  postEvent('ALPHA', {'cat': 'dog'});
  debugger();
  registerExtension('ext..error', Handler);
  registerExtension('ext..exception', Handler);
  registerExtension('ext..success', Handler);
  bool exceptionThrown = false;
  try {
    registerExtension('ext..delay', Handler);
  } catch (e) {
    exceptionThrown = true;
  }
  // This check is running in the target process so we can't used package:test.
  Expect.isTrue(exceptionThrown);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    await isolate.load();
    // Note: extensions other than those is this test might already be
    // registered by core libraries.
    expect(isolate.extensionRPCs, contains('ext..delay'));
    expect(isolate.extensionRPCs, isNot(contains('ext..error')));
    expect(isolate.extensionRPCs, isNot(contains('ext..exception')));
    expect(isolate.extensionRPCs, isNot(contains('ext..success')));
  },
  resumeIsolateAndAwaitEvent(Isolate.kExtensionStream, (ServiceEvent event) {
    expect(event.kind, equals(ServiceEvent.kExtension));
    expect(event.extensionKind, equals('ALPHA'));
    expect(event.extensionData, isA<Map>());
    expect(event.extensionData!['cat'], equals('dog'));
  }),
  hasStoppedAtBreakpoint,
  resumeIsolateAndAwaitEvent(VM.kIsolateStream, (ServiceEvent event) {
    // Check that we received an event when '__error' was registered.
    expect(event.kind, equals(ServiceEvent.kServiceExtensionAdded));
    expect(event.extensionRPC, equals('ext..error'));
  }),
  // Initial.
  (Isolate isolate) async {
    var result;

    result = await isolate.invokeRpcNoUpgrade('ext..delay', {});
    expect(result['type'], equals('_delayedType'));
    expect(result['method'], equals('ext..delay'));
    expect(result['parameters']['isolateId'], isNotNull);

    try {
      await isolate.invokeRpcNoUpgrade('ext..error', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.extensionErrorMin));
      expect(e.message, equals('My error detail.'));
    }

    try {
      await isolate.invokeRpcNoUpgrade('ext..exception', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.extensionError));
      expect(e.message.startsWith('I always throw!\n'), isTrue);
    }

    result =
        await isolate.invokeRpcNoUpgrade('ext..success', {'apple': 'banana'});
    expect(result['type'], equals('_extensionType'));
    expect(result['method'], equals('ext..success'));
    expect(result['parameters']['isolateId'], isNotNull);
    expect(result['parameters']['apple'], equals('banana'));
  },
];

main(args) async => runIsolateTests(args, tests, testeeConcurrent: test);
