// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.web.js_interop_test;

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

@CustomTag("dart-element")
class DartElement extends PolymerElement {
  DartElement.created() : super.created();
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
