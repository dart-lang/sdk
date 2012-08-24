// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('JsInterop4Test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');
#import('dart:isolate');

const testData = const [1, '2', 'true'];

void testIsolateEntry() {
  var fun1 = window.lookupPort('fun1');
  var result = fun1.callSync(testData);

  var fun2 = window.lookupPort('fun2');
  fun2.callSync(result);
}

main() {
  useHtmlConfiguration();

  // Test that our interop scheme also works from Dart to Dart.
  test('dart-to-dart-same-isolate', () {
    var fun = expectAsync1((message) {
      Expect.listEquals(testData, message);
      return message.length;
    });

    var port1 = new ReceivePortSync();
    port1.receive(fun);
    window.registerPort('fun', port1.toSendPort());

    var port2 = window.lookupPort('fun');
    var result = port2.callSync(testData);
    Expect.equals(3, result);
  });

  // Test across isolate boundary.
  test('dart-to-dart-cross-isolate', () {
    var fun1 = (message) {
      Expect.listEquals(testData, message);
      return message.length;
    };

    var port1 = new ReceivePortSync();
    port1.receive(fun1);
    window.registerPort('fun1', port1.toSendPort());

    // TODO(vsm): Investigate why this needs to be called asynchronously.
    var done = expectAsync0(() {});
    var fun2 = (message) {
      Expect.equals(3, message);
      window.setTimeout(done, 0);
    };

    var port2 = new ReceivePortSync();
    port2.receive(fun2);
    window.registerPort('fun2', port2.toSendPort());

    spawnDomFunction(testIsolateEntry);
  });
}
