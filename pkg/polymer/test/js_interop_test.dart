// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.web.js_interop_test;

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

@CustomTag('dart-element')
class DartElement extends PolymerElement {
  DartElement.created() : super.created();
}

@CustomTag('dart-element2')
class DartElement2 extends PolymerElement {
  Element get quux => this.querySelector('.quux');
  DartElement2.created() : super.created();
}

@CustomTag('dart-element3')
class DartElement3 extends PolymerElement {
  @observable var quux;
  DartElement3.created() : super.created();

  domReady() {
    quux = new JsObject.jsify({
      'aDartMethod': (x) => 444 + x
    });
  }
}

@CustomTag('dart-two-way')
class DartTwoWay extends PolymerElement {
  @observable var twoWay = 40;
  DartTwoWay.created() : super.created();
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('dart-element upgraded', () {
    expect(querySelector('dart-element') is DartElement, true,
        reason: 'dart-element upgraded');
  });

  test('js-element in body', () => testInterop(
      querySelector('js-element')));

  test('js-element in dart-element', () => testInterop(
      querySelector('dart-element').shadowRoot.querySelector('js-element')));

  test('elements can be passed through Node.bind to JS', () {
    var text = querySelector('dart-element2')
        .shadowRoot.querySelector('js-element2')
        .shadowRoot.text;
    expect(text, 'QUX:123');
  });

  test('objects with functions can be passed through Node.bind to JS', () {
    var sr = querySelector('dart-element3')
      .shadowRoot.querySelector('js-element3')
      .shadowRoot;

    return new Future(() {
      expect(sr.text, 'js-element3[qux]:765');
    });
  });

  test('two way bindings work', () {
    var dartElem = querySelector('dart-two-way');
    var jsElem = dartElem.shadowRoot.querySelector('js-two-way');
    var interop = new JsObject.fromBrowserObject(jsElem);

    return new Future(() {
      expect(jsElem.shadowRoot.text, 'FOOBAR:40');

      expect(dartElem.twoWay, 40);
      expect(interop['foobar'], 40);

      interop.callMethod('aJsMethod', [2]);

      // Because Polymer.js two-way bindings are just a getter/setter pair
      // pointing at the original, we will see the new value immediately.
      expect(dartElem.twoWay, 42);

      expect(interop['foobar'], 42);

      // Text will update asynchronously
      expect(jsElem.shadowRoot.text, 'FOOBAR:40');

      return new Future(() {
        expect(jsElem.shadowRoot.text, 'FOOBAR:42');
      });
    });     
  });
});

testInterop(jsElem) {
  expect(jsElem.shadowRoot.text, 'FOOBAR');
  var interop = new JsObject.fromBrowserObject(jsElem);
  expect(interop['baz'], 42, reason: 'can read JS custom element properties');

  jsElem.attributes['baz'] = '123';
  return flush().then((_) {
    expect(interop['baz'], 123, reason: 'attribute reflected to property');
    expect(jsElem.shadowRoot.text, 'FOOBAR', reason: 'text unchanged');

    interop['baz'] = 777;
    return flush();
  }).then((_) {
    expect(jsElem.attributes['baz'], '777',
        reason: 'property reflected to attribute');

    expect(jsElem.shadowRoot.text, 'FOOBAR', reason: 'text unchanged');

    interop.callMethod('aJsMethod', [123]);
    return flush();
  }).then((_) {
    expect(jsElem.shadowRoot.text, '900', reason: 'text set by JS method');
    expect(interop['baz'], 777, reason: 'unchanged');
  });
}

/// Calls Platform.flush() to flush Polymer.js pending operations, e.g.
/// dirty checking for data-bindings.
Future flush() {
  var Platform = context['Platform'];
  Platform.callMethod('flush');

  var completer = new Completer();
  Platform.callMethod('endOfMicrotask', [() => completer.complete()]);
  return completer.future;
}
