// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library register_element_proxy_test;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import '../utils.dart';

class FooElement extends HtmlElement {
  static final tag = 'x-foo';

  final int initializedField = 666;
  js.JsObject _proxy;

  factory FooElement() => new Element.tag(tag);
  FooElement.created() : super.created() {
    _proxy = new js.JsObject.fromBrowserObject(this);
  }

  String doSomething() => _proxy.callMethod('doSomething');

  bool get fooCreated => _proxy['fooCreated'];
}

main() {
  useHtmlConfiguration();

  var registered = false;
  var upgrader;
  setUp(() => customElementsReady.then((_) {
        if (!registered) {
          registered = true;
          upgrader = document.createElementUpgrader(FooElement);
          js.context['upgradeListener'] = (e) {
            upgrader.upgrade(e);
          };

          document.registerElement('custom-element', CustomElement);
        }
      }));

  test('created gets proxied', () {
    var element = document.createElement(FooElement.tag);
    expect(element is FooElement, isTrue);
    expect(element.initializedField, 666);
    expect(element.text, 'constructed');

    js.context.callMethod('validateIsFoo', [element]);

    expect(element.doSomething(), 'didSomething');
    expect(element.fooCreated, true);
  });

  test('dart constructor works', () {
    var element = new FooElement();
    expect(element is FooElement, isTrue);
    expect(element.text, 'constructed');

    js.context.callMethod('validateIsFoo', [element]);

    expect(element.doSomething(), 'didSomething');
  });

  test('cannot create upgrader for interfaces', () {
    expect(() {
      document.createElementUpgrader(HtmlElementInterface);
    }, throws);
  });

  test('cannot upgrade interfaces', () {
    expect(() {
      upgrader.upgrade(new HtmlElementInterface());
    }, throws);
  });

  test('cannot upgrade more than once', () {
    var fooElement = new FooElement();
    expect(() {
      upgrader.upgrade(fooElement);
    }, throws);
  });

  test('cannot upgrade non-matching elements', () {
    expect(() {
      upgrader.upgrade(new DivElement());
    }, throws);
  });

  test('cannot upgrade custom elements', () {
    var custom = new CustomElement();
    expect(() {
      upgrader.upgrade(custom);
    }, throws);
  });

  test('can upgrade with extendsTag', () {
    var upgrader = document.createElementUpgrader(CustomDiv, extendsTag: 'div');
    var div = new DivElement();
    var customDiv = upgrader.upgrade(div);
    expect(customDiv is CustomDiv, isTrue);

    var htmlElement = document.createElement('not-registered');
    expect(() {
      upgrader.upgrade(htmlElement);
    }, throws);
  });

  test('cannot create upgrader for built-in types', () {
    expect(() {
      document.createElementUpgrader(HtmlElement);
    }, throws);
  });
}

class HtmlElementInterface implements HtmlElement {
  HtmlElementInterface.created();
}

class CustomDiv extends DivElement {
  CustomDiv.created() : super.created();
}

class CustomElement extends HtmlElement {
  factory CustomElement() => document.createElement('custom-element');
  CustomElement.created() : super.created();
}
