// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('JsInteropFuncPassingTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');
#import('dart:isolate');

injectSource(code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHTML = code;
  document.body.nodes.add(script);
}

var isolateTest = """
  var port = new ReceivePortSync();
  port.receive(function (f) {
    return f('fromJS');
  });
  window.registerPort('test', port.toSendPort());
""";

main() {
  useHtmlConfiguration();

  test('dart-to-js-function', () {
    injectSource(isolateTest);

    SendPortSync port = window.lookupPort('test');
    var result = port.callSync((msg) {
      Expect.equals('fromJS', msg);
      return 'received';
    });
    Expect.equals('received', result);
  });
}
