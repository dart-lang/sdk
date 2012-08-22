// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('JsInteropObjPassingTest');
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

var jsProxyTest = """
  function TestType(x) {
    this.x = x;
  }
  TestType.prototype.razzle = function () {
    return this.x * 2;
  }
  var data = new TestType(21);

  var port1 = new ReceivePortSync();
  port1.receive(function (x) {
    return x.razzle();
  });
  window.registerPort('test1a', port1.toSendPort());

  var port2 = window.lookupPort('test1b');
  port2.callSync(data);
""";

var dartProxyTest = """
  var port2 = new ReceivePortSync();
  port2.receive(function (x) {
    var port1 = window.lookupPort('test2a');
    port1.callSync(x);
  });
  window.registerPort('test2b', port2.toSendPort());
""";

main() {
  useHtmlConfiguration();

  test('js-proxy', () {
    int invoked = 0;

    var port2 = new ReceivePortSync();
    port2.receive((x) {
      var port1 = window.lookupPort('test1a');
      var result = port1.callSync(x);
      expect(result, equals(42));
      ++invoked;
    });
    window.registerPort('test1b', port2.toSendPort());

    injectSource(jsProxyTest);
    expect(invoked, equals(1));
  });

  test('dart-proxy', () {
    injectSource(dartProxyTest);

    var buffer = new StringBuffer();
    buffer.add('hello');

    var port1 = new ReceivePortSync();
    port1.receive((x) => x.add(' from dart'));
    window.registerPort('test2a', port1.toSendPort());

    var port2 = window.lookupPort('test2b');
    port2.callSync(buffer);

    expect(buffer.toString(), equals('hello from dart'));
  });
}
