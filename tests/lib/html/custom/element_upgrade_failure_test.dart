// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:js' as js;

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

class FooElement extends HtmlElement {
  static final tag = 'x-foo';

  final int initializedField = 666;
  late js.JsObject _proxy = new js.JsObject.fromBrowserObject(this);

  factory FooElement() => new Element.tag(tag) as FooElement;
  FooElement.created() : super.created();

  String doSomething() => _proxy.callMethod('doSomething');

  bool get fooCreated => _proxy['fooCreated'];
}

main() async {
  await customElementsReady;
  var upgrader = document.createElementUpgrader(FooElement);
  js.context['upgradeListener'] = (e) {
    upgrader.upgrade(e);
  };

  test('cannot create upgrader for interfaces', () {
    expect(() {
      // TODO(srujzs): Determine if this should be a static error.
      document.createElementUpgrader(HtmlElementInterface);
    }, throws);
  });

  test('cannot upgrade interfaces', () {
    expect(() {
      upgrader.upgrade(new HtmlElementInterface());
      //                   ^^^^^^^^^^^^^^^^^^^^
      // [analyzer] STATIC_WARNING.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
    }, throws);
  });
}

class HtmlElementInterface implements HtmlElement {
  //  ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
  HtmlElementInterface.created();
}
