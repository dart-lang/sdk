// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('JsInterop3Test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');
#import('dart:isolate');

injectSource(code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHTML = code;
  document.body.nodes.add(script);
}

var jsToDart = """
  var fun1 = window.lookupPort('fun1');
  var result = fun1.callSync({'a': 'Hello', 'b': 'World', c: 42});

  var fun2 = window.lookupPort('fun2');
  fun2.callSync(result);
""";

main() {
  useHtmlConfiguration();

  test('js-to-dart', () {
    var fun1 = (message) {
      Expect.equals('Hello', message['a']);
      Expect.equals('World', message['b']);
      Expect.equals(42, message['c']);
      Expect.equals(3, message.keys.length);
      return 42;
    };

    var port1 = new ReceivePortSync();
    port1.receive(fun1);
    window.registerPort('fun1', port1.toSendPort());

    // TODO(vsm): Investigate why this needs to be called asynchronously.
    var done = expectAsync0(() {});
    var fun2 = (message) {
      Expect.equals(42, message);
      window.setTimeout(done, 0);
    };

    var port2 = new ReceivePortSync();
    port2.receive(fun2);
    window.registerPort('fun2', port2.toSendPort());

    injectSource(jsToDart);
  });
}
