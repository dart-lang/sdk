// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('JsInteropElementTest');
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

var jsElementTest = """
  var canvas = document.createElement('canvas');
  document.body.appendChild(canvas);

  var port = window.lookupPort('test1');
  port.callSync(canvas);
""";

var dartElementTest = """
  var port = new ReceivePortSync();
  port.receive(function (data) {
    return (data instanceof HTMLDivElement);
  });
  window.registerPort('test2', port.toSendPort());
""";

main() {
  useHtmlConfiguration();

  test('js-element', () {
    int invoked = 0;

    var port = new ReceivePortSync();
    port.receive((data) {
      expect(data is CanvasElement);
      ++invoked;
    });
    window.registerPort('test1', port.toSendPort());

    injectSource(jsElementTest);
    expect(invoked, equals(1));
  });

  test('dart-element', () {
    injectSource(dartElementTest);

    var port = window.lookupPort('test2');
    var div = new DivElement();
    var canvas = new CanvasElement(100,100);
    document.body.nodes.addAll([div, canvas]);
    expect(port.callSync(div));
    expect(!port.callSync(canvas));
  });
}
