// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

@CustomTag('x-html')
class XHtmlElement extends PolymerElement {
  XHtmlElement.created() : super.created();
}

@CustomTag('x-html-two')
class XHtml2Element extends XHtmlElement {
  XHtml2Element.created() : super.created();
}

@CustomTag('x-div')
class XDivElement extends DivElement with Polymer, Observable {
  XDivElement.created() : super.created() {
    polymerCreated();
  }
}

@CustomTag('x-div-two')
class XDiv2Element extends XDivElement {
  XDiv2Element.created() : super.created();
}

/// Dart-specific test:
/// This element is registered from code without an associated polymer-element.
class XPolymerElement extends PolymerElement {
  XPolymerElement.created() : super.created();
}

/// Dart-specific test:
/// This element is registered from code without an associated polymer-element.
class XButtonElement extends ButtonElement with Polymer, Observable {
  XButtonElement.created() : super.created() {
    polymerCreated();
  }
}


main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('elements upgraded', () {
    expect(querySelector('x-html') is XHtmlElement, isTrue);
    expect(querySelector('x-html-two') is XHtml2Element, isTrue);
    expect(querySelector('#x-div') is XDivElement, isTrue);
    expect(querySelector('#x-div-two') is XDiv2Element, isTrue);
  });

  group('register without polymer-element', () {
    test('custom element', () {
      Polymer.registerSync('x-polymer', XPolymerElement,
          template: new Element.html('<template>FOOBAR'));

      expect(document.createElement('x-polymer') is XPolymerElement, isTrue,
          reason: 'should have been registered');

      var e = document.querySelector('x-polymer');
      expect(e is XPolymerElement, isTrue,
          reason: 'elements on page should be upgraded');
      expect(e.shadowRoot, isNotNull,
          reason: 'shadowRoot was created from template');
      expect(e.shadowRoot.nodes[0].text, 'FOOBAR');
    });

    test('type extension', () {
      Polymer.registerSync('x-button', XButtonElement, extendsTag: 'button');

      expect(document.createElement('button', 'x-button') is XButtonElement,
          isTrue, reason: 'should have been registered');
      expect(document.querySelector('[is=x-button]') is XButtonElement, isTrue,
          reason: 'elements on page should be upgraded');
    });
  });
});
