// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('JsInteropFuncPassingTest');
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

var dartToJsTest = """
  var port = new ReceivePortSync();
  port.receive(function (f) {
    return f('fromJS');
  });
  window.registerPort('test1', port.toSendPort());
""";

var jsToDartTest = """
  var port1 = window.lookupPort('test2a');
  var result = port1.callSync(function (x) {
    return x*2;
  });
  
  var port2 = window.lookupPort('test2b');
  port2.callSync(result);
""";

var dartToJsToDartTest = """
  var port = new ReceivePortSync();
  port.receive(function (f) {
    return f;
  });
  window.registerPort('test3', port.toSendPort());
""";

main() {
  useHtmlConfiguration();

  test('dart-to-js-function', () {
    injectSource(dartToJsTest);

    SendPortSync port = window.lookupPort('test1');
    var result = port.callSync((msg) {
      Expect.equals('fromJS', msg);
      return 'received';
    });
    Expect.equals('received', result);
  });

  test('js-to-dart-function', () {
    var port1 = new ReceivePortSync();
    int invoked1 = 0;
    port1.receive((f) {
      ++invoked1;
      var data = f(21);
      expect(data, equals(42));
      return 'fromDart';
    });
    window.registerPort('test2a', port1.toSendPort());

    var port2 = new ReceivePortSync();
    int invoked2 = 0;
    port2.receive((x) {
      ++invoked2;
      expect(x, equals('fromDart'));
    });
    window.registerPort('test2b', port2.toSendPort());

    injectSource(jsToDartTest);

    expect(1, equals(invoked1));
    expect(1, equals(invoked2));
  });

  test('dart-to-js-to-dart-function', () {
    injectSource(dartToJsToDartTest);
    
    validate(x) {
      expect(x, equals('fromCaller'));
      return 'fromCallee';
    }

    SendPortSync port = window.lookupPort('test3');
    var f = port.callSync(validate);
    var result = f('fromCaller');
    Expect.equals('fromCallee', result);
    
  });
}
