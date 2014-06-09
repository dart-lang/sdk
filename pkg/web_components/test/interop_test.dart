// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_wrappers_test;

import 'dart:html';
import 'dart:async';
import 'dart:js' show context, JsObject;
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_components/interop.dart';

main() {
  useHtmlConfiguration();
  registerDartType('x-a', XAWrapper);
  registerDartType('x-b', XBWrapper, extendsTag: 'div');
  registerDartType('x-c', XCWrapper);

  test('interop is supported', () {
    expect(isSupported, isTrue);
  });

  test('previously created elements are not upgraded', () {
    var a = document.querySelector('x-a');
    expect(a is HtmlElement, isTrue, reason: 'x-a is HtmlElement');
    expect(a is XAWrapper, isFalse, reason: 'x-a should not be upgraded yet');
    expect(_readX(a), 0);

    var b = document.querySelector('[is=x-b]');
    expect(b is DivElement, isTrue, reason: 'x-b is DivElement');
    expect(b is XBWrapper, isFalse, reason: 'x-b should not be upgraded yet');
    expect(_readX(b), 1);

    var c = document.querySelector('x-c');
    expect(c is HtmlElement, isTrue, reason: 'x-c is HtmlElement');
    expect(c is XCWrapper, isFalse, reason: 'x-c should not be upgraded yet');
    expect(_readX(c), null, reason: 'x-c has not been registered in JS yet');
  });

  test('events seen for anything created after registering Dart type', () {
    context.callMethod('addA');
    var list = document.querySelectorAll('x-a');
    expect(list.length, 2);
    var a = list[1];
    expect(a is HtmlElement, isTrue, reason: 'x-a is HtmlElement');
    expect(a is XAWrapper, isTrue, reason: 'x-a is upgraded to XAWrapper');
    expect(a.x, 2);
    expect(a.wrapperCount, 0);

    context.callMethod('addB');
    list = document.querySelectorAll('[is=x-b]');
    expect(list.length, 2);
    var b = list[1];
    expect(b is DivElement, isTrue, reason: 'x-b is DivElement');
    expect(b is XBWrapper, isTrue, reason: 'x-b is upgraded to XBWrapper');
    expect(b.x, 3);
    expect(b.wrapperCount, 1);
  });

  test('events seen if Dart type is registered before registerElement', () {
    var c = document.querySelector('x-c');
    expect(c is XCWrapper, isFalse);
    expect(_readX(c), null, reason: 'x-c has not been registered in JS yet');

    context.callMethod('registerC');
    c = document.querySelector('x-c');
    expect(c is XCWrapper, isTrue);
    expect(c.x, 4);
    expect(c.wrapperCount, 2);

    context.callMethod('addC');
    var list = document.querySelectorAll('x-c');
    expect(list.length, 2);
    expect(list[0], c);
    c = list[1];
    expect(c is HtmlElement, isTrue, reason: 'x-c is HtmlElement');
    expect(c is XCWrapper, isTrue, reason: 'x-c is upgraded to XCWrapper');
    expect(c.x, 5);
    expect(c.wrapperCount, 3);
  });
}
int _count = 0;

abstract class Wrapper {
  int wrapperCount = _count++;
  int get x => _readX(this);
}

_readX(e) => new JsObject.fromBrowserObject(e)['x'];

class XAWrapper extends HtmlElement with Wrapper {
  XAWrapper.created() : super.created();
}

class XBWrapper extends DivElement with Wrapper {
  XBWrapper.created() : super.created();
}

class XCWrapper extends HtmlElement with Wrapper {
  XCWrapper.created() : super.created();
}
