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
import 'package:web_components/polyfill.dart';

main() {
  useHtmlConfiguration();
  setUp(() => customElementsReady);

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

    var d = document.querySelector('x-d');
    expect(d is HtmlElement, isTrue, reason: 'x-d is HtmlElement');
    expect(d is XDWrapper, isFalse, reason: 'x-d should not be upgraded yet');
    expect(_readX(d), 2);

    /// Note: this registration has a global side-effect and is assumed in the
    /// following tests.
    registerDartType('x-a', XAWrapper);
    registerDartType('x-b', XBWrapper, extendsTag: 'div');
    registerDartType('x-c', XCWrapper);
    onlyUpgradeNewElements();
    registerDartType('x-d', XDWrapper); // late on purpose.

    a = document.querySelector('x-a');
    expect(a is HtmlElement, isTrue, reason: 'x-a is HtmlElement');
    expect(a is XAWrapper, isTrue, reason: 'x-a is upgraded to XAWrapper');
    expect(a.x, 0);
    expect(a.wrapperCount, 0);

    b = document.querySelector('[is=x-b]');
    expect(b is DivElement, isTrue, reason: 'x-b is DivElement');
    expect(b is XBWrapper, isTrue, reason: 'x-b is upgraded to XBWrapper');
    expect(b.x, 1);
    expect(b.wrapperCount, 1);

    // x-d was not upgraded because its registration came after we stopped
    // upgrading old elements:
    d = document.querySelector('x-d');
    expect(d is HtmlElement, isTrue, reason: 'x-d is HtmlElement');
    expect(d is XDWrapper, isFalse, reason: 'x-d should not be upgraded yet');
    expect(_readX(d), 2);

    var c = document.querySelector('x-c');
    expect(c is HtmlElement, isTrue, reason: 'x-c is HtmlElement');
    expect(c is XCWrapper, isFalse, reason: 'x-c should not be upgraded yet');
    expect(_readX(c), null, reason: 'x-c has not been registered in JS yet');
  });

  test('anything created after registering Dart type is upgraded', () {
    context.callMethod('addA');
    var list = document.querySelectorAll('x-a');
    expect(list.length, 2);
    var a = list[1];
    expect(a is HtmlElement, isTrue, reason: 'x-a is HtmlElement');
    expect(a is XAWrapper, isTrue, reason: 'x-a is upgraded to XAWrapper');
    expect(a.x, 3);
    expect(a.wrapperCount, 2);

    context.callMethod('addB');
    list = document.querySelectorAll('[is=x-b]');
    expect(list.length, 2);
    var b = list[1];
    expect(b is DivElement, isTrue, reason: 'x-b is DivElement');
    expect(b is XBWrapper, isTrue, reason: 'x-b is upgraded to XBWrapper');
    expect(b.x, 4);
    expect(b.wrapperCount, 3);

    // New instances of x-d should be upgraded regardless.
    context.callMethod('addD');
    list = document.querySelectorAll('x-d');
    expect(list.length, 2);
    var d = list[1];
    expect(d is HtmlElement, isTrue, reason: 'x-d is HtmlElement');
    expect(d is XDWrapper, isTrue, reason: 'x-d is upgraded to XDWrapper');
    expect(d.x, 5);
    expect(d.wrapperCount, 4);
  });

  test('events seen if Dart type is registered before registerElement', () {
    var c = document.querySelector('x-c');
    expect(c is XCWrapper, isFalse);
    expect(_readX(c), null, reason: 'x-c has not been registered in JS yet');

    context.callMethod('registerC');
    c = document.querySelector('x-c');
    expect(c is XCWrapper, isTrue);
    expect(c.x, 6);
    expect(c.wrapperCount, 5);

    context.callMethod('addC');
    var list = document.querySelectorAll('x-c');
    expect(list.length, 2);
    expect(list[0], c);
    c = list[1];
    expect(c is HtmlElement, isTrue, reason: 'x-c is HtmlElement');
    expect(c is XCWrapper, isTrue, reason: 'x-c is upgraded to XCWrapper');
    expect(c.x, 7);
    expect(c.wrapperCount, 6);
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

class XDWrapper extends HtmlElement with Wrapper {
  XDWrapper.created() : super.created();
}
