// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;

import 'package:unittest/html_individual_config.dart';
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
  var registered = false;
  var upgrader;
  setUp(() => customElementsReady.then((_) {
        if (!registered) {
          registered = true;
          upgrader = document.createElementUpgrader(FooElement);
          js.context['upgradeListener'] = (e) {
            upgrader.upgrade(e);
          };
        }
      }));


  test('cannot create upgrader for interfaces', () {
    expect(() {
      document.createElementUpgrader(HtmlElementInterface); /*@compile-error=unspecified*/
    }, throws);
  });

  test('cannot upgrade interfaces', () {
    expect(() {
      upgrader.upgrade(new HtmlElementInterface());
    }, throws);
  });
}

class HtmlElementInterface implements HtmlElement { /*@compile-error=unspecified*/
  HtmlElementInterface.created();
}

