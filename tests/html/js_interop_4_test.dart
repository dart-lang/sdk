// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library JsInterop4Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:async';
import 'dart:html';
import 'dart:isolate';

const testData = const [1, '2', 'true'];

main() {
  useHtmlConfiguration();

  // Test that our interop scheme also works from Dart to Dart.
  test('dart-to-dart-same-isolate', () {
    var fun = expectAsync1((message) {
      expect(message, orderedEquals(testData));
      return message.length;
    });

    var port1 = new ReceivePortSync();
    port1.receive(fun);
    window.registerPort('fun', port1.toSendPort());

    var port2 = window.lookupPort('fun');
    var result = port2.callSync(testData);
    expect(result, 3);
  });
}
