// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('JsInteropObjInvokeTest');
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

  var port = window.lookupPort('test1');
  port.callSync(data);
""";

main() {
  useHtmlConfiguration();

  test('js-proxy', () {
    int invoked = 0;

    var port = new ReceivePortSync();
    port.receive((data) {
      expect(data.x, equals(21));
      expect(data.razzle(), equals(42));
      data.x = 100;
      expect(data.razzle(), equals(200));

      ++invoked;
    });
    window.registerPort('test1', port.toSendPort());

    injectSource(jsProxyTest);
    expect(invoked, equals(1));
  });
}
