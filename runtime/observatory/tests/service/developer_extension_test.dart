// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:observatory/sample_profile.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

Future<ServiceExtensionResponse> Handler(String method,
                                         Map paremeters) {
  print('Invoked extension: $method');
  switch (method) {
    case 'ext..delay':
      Completer c = new Completer();
      new Timer(new Duration(seconds: 1), () {
        c.complete(new ServiceExtensionResponse.result(json.encode({
            'type': '_delayedType',
            'method': method,
            'parameters': paremeters,
          })));
      });
      return c.future;
    case 'ext..error':
      return new Future.value(
              new ServiceExtensionResponse.error(
                  ServiceExtensionResponse.extensionErrorMin,
                  'My error detail.'));
    case 'ext..exception':
      throw "I always throw!";
    case 'ext..success':
      return new Future.value(
          new ServiceExtensionResponse.result(json.encode({
              'type': '_extensionType',
              'method': method,
              'parameters': paremeters,
          })));
    case 'ext..null':
      return null;
    case 'ext..nullFuture':
      return new Future.value(null);
  }
}

Future<ServiceExtensionResponse> LanguageErrorHandler(String method,
                                                      Map paremeters) {
  // The following is an intentional syntax error.
  klajsdlkjfad
}

void test() {
  registerExtension('ext..delay', Handler);
  debugger();
  postEvent('ALPHA', {
    'cat': 'dog'
  });
  debugger();
  registerExtension('ext..error', Handler);
  registerExtension('ext..exception', Handler);
  registerExtension('ext..null', Handler);
  registerExtension('ext..nullFuture', Handler);
  registerExtension('ext..success', Handler);
  bool exceptionThrown = false;
  try {
    registerExtension('ext..delay', Handler);
  } catch (e) {
    exceptionThrown = true;
  }
  expect(exceptionThrown, isTrue);
  registerExtension('ext..languageError', LanguageErrorHandler);
}

var tests = [
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    await isolate.load();
    expect(isolate.extensionRPCs.length, 1);
    expect(isolate.extensionRPCs[0], equals('ext..delay'));
  },
  resumeIsolateAndAwaitEvent(Isolate.kExtensionStream, (ServiceEvent event) {
    expect(event.kind, equals(ServiceEvent.kExtension));
    expect(event.extensionKind, equals('ALPHA'));
    expect(event.extensionData, new isInstanceOf<Map>());
    expect(event.extensionData['cat'], equals('dog'));
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

    try {
      await isolate.invokeRpcNoUpgrade('ext..null', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.extensionError));
      expect(e.message, equals('Extension handler must return a Future'));
    }

    try {
      await isolate.invokeRpcNoUpgrade('ext..nullFuture', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.extensionError));
      expect(e.message, equals('Extension handler must complete to a '
                               'ServiceExtensionResponse'));
    }

    result = await isolate.invokeRpcNoUpgrade('ext..success',
                                              {'apple': 'banana'});
    expect(result['type'], equals('_extensionType'));
    expect(result['method'], equals('ext..success'));
    expect(result['parameters']['isolateId'], isNotNull);
    expect(result['parameters']['apple'], equals('banana'));


    try {
      result = await isolate.invokeRpcNoUpgrade('ext..languageError', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.extensionError));
      expect(e.message, stringContainsInOrder([
          'developer_extension_test.dart',
          'semicolon expected']));
    }
  },
];

main(args) async => runIsolateTests(args, tests, testeeConcurrent:test);
