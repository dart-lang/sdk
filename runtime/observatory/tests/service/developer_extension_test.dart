// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:observatory/cpu_profile.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

Future<ServiceExtensionResponse> Handler(String method,
                                         Map paremeters) {
  print('Invoked extension: $method');
  switch (method) {
    case '__delay':
      Completer c = new Completer();
      new Timer(new Duration(seconds: 1), () {
        c.complete(new ServiceExtensionResponse.result(JSON.encode({
            'type': '_delayedType',
            'method': method,
            'parameters': paremeters,
          })));
      });
      return c.future;
    case '__error':
      return new Future.value(
              new ServiceExtensionResponse.error(
                  ServiceExtensionResponse.kExtensionErrorMin,
                  'My error detail.'));
    case '__exception':
      throw "I always throw!";
    case '__success':
      return new Future.value(
          new ServiceExtensionResponse.result(JSON.encode({
              'type': '_extensionType',
              'method': method,
              'parameters': paremeters,
          })));
    case '__null':
      return null;
    case '__nullFuture':
      return new Future.value(null);
  }
}

Future<ServiceExtensionResponse> LanguageErrorHandler(String method,
                                                      Map paremeters) {
  // The following is an intentional syntax error.
  klajsdlkjfad
}

void test() {
  registerExtension('__delay', Handler);
  debugger();
  postEvent('ALPHA', {
    'cat': 'dog'
  });
  debugger();
  registerExtension('__error', Handler);
  registerExtension('__exception', Handler);
  registerExtension('__null', Handler);
  registerExtension('__nullFuture', Handler);
  registerExtension('__success', Handler);
  bool exceptionThrown = false;
  try {
    registerExtension('__delay', Handler);
  } catch (e) {
    exceptionThrown = true;
  }
  expect(exceptionThrown, isTrue);
  registerExtension('__languageError', LanguageErrorHandler);
}

var tests = [
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    await isolate.load();
    expect(isolate.extensionRPCs.length, 1);
    expect(isolate.extensionRPCs[0], equals('__delay'));
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
    expect(event.extensionRPC, equals('__error'));
  }),
  // Initial.
  (Isolate isolate) async {
    var result;

    result = await isolate.invokeRpcNoUpgrade('__delay', {});
    expect(result['type'], equals('_delayedType'));
    expect(result['method'], equals('__delay'));
    expect(result['parameters']['isolateId'], isNotNull);

    try {
      await isolate.invokeRpcNoUpgrade('__error', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.kExtensionErrorMin));
      expect(e.message, equals('My error detail.'));
    }

    try {
      await isolate.invokeRpcNoUpgrade('__exception', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.kExtensionError));
      expect(e.message.startsWith('I always throw!\n'), isTrue);
    }

    try {
      await isolate.invokeRpcNoUpgrade('__null', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.kExtensionError));
      expect(e.message, equals('Extension handler must return a Future'));
    }

    try {
      await isolate.invokeRpcNoUpgrade('__nullFuture', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.kExtensionError));
      expect(e.message, equals('Extension handler must complete to a '
                               'ServiceExtensionResponse'));
    }

    result = await isolate.invokeRpcNoUpgrade('__success',
                                              {'apple': 'banana'});
    expect(result['type'], equals('_extensionType'));
    expect(result['method'], equals('__success'));
    expect(result['parameters']['isolateId'], isNotNull);
    expect(result['parameters']['apple'], equals('banana'));


    try {
      result = await isolate.invokeRpcNoUpgrade('__languageError', {});
    } on ServerRpcException catch (e, st) {
      expect(e.code, equals(ServiceExtensionResponse.kExtensionError));
      expect(e.message, stringContainsInOrder([
          'Error in extension `__languageError`:',
          'developer_extension_test.dart',
          'semicolon expected']));
    }

  },
];

main(args) async => runIsolateTests(args, tests, testeeConcurrent:test);
