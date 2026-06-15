// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'common/expect.dart';
import 'common/test_helper.dart';

Future<ServiceExtensionResponse> handler(String method, Map parameters) {
  print('Invoked extension: $method');
  switch (method) {
    case 'ext..delay':
      final c = Completer<ServiceExtensionResponse>();
      Timer(Duration(seconds: 1), () {
        c.complete(
          ServiceExtensionResponse.result(
            jsonEncode({
              'type': '_delayedType',
              'method': method,
              'parameters': parameters,
            }),
          ),
        );
      });
      return c.future;
    case 'ext..error':
      return Future<ServiceExtensionResponse>.value(
        ServiceExtensionResponse.error(
          ServiceExtensionResponse.extensionErrorMin,
          'My error detail.',
        ),
      );
    case 'ext..exception':
      throw 'I always throw!';
    case 'ext..success':
      return Future<ServiceExtensionResponse>.value(
        ServiceExtensionResponse.result(
          jsonEncode({
            'type': '_extensionType',
            'method': method,
            'parameters': parameters,
          }),
        ),
      );
  }
  throw 'Unknown extension: $method';
}

void test() {
  registerExtension('ext..delay', handler);
  debugger();
  postEvent('ALPHA', {'cat': 'dog'});
  debugger();
  registerExtension('ext..error', handler);
  registerExtension('ext..exception', handler);
  registerExtension('ext..success', handler);
  bool exceptionThrown = false;
  try {
    registerExtension('ext..delay', handler);
  } catch (e) {
    exceptionThrown = true;
  }
  // This check is running in the target process so we can't used package:test.
  Expect.equals(exceptionThrown, true);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: test);
}
