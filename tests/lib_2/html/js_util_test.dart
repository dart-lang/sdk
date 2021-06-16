// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Tests the functionality of js_util with HTML objects.

@JS()
library js_util_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS('Node')
external get JSNodeType;

@JS('Element')
external get JSElementType;

@JS('Text')
external get JSTextType;

@JS('HTMLCanvasElement')
external get JSHtmlCanvasElementType;

@JS()
class Foo {
  external Foo();
}

main() {
  eval(r""" function Foo() {} """);

  test('hasProperty', () {
    var textElement = new Text('foo');
    expect(js_util.hasProperty(textElement, 'data'), isTrue);
  });

  test('getProperty', () {
    var textElement = new Text('foo');
    expect(js_util.getProperty(textElement, 'data'), equals('foo'));
  });

  test('setProperty', () {
    var textElement = new Text('foo');
    js_util.setProperty(textElement, 'data', 'bar');
    expect(textElement.text, equals('bar'));
  });

  test('callMethod', () {
    var canvas = new CanvasElement();
    expect(
        identical(canvas.getContext('2d'),
            js_util.callMethod(canvas, 'getContext', ['2d'])),
        isTrue);
  });

  test('instanceof', () {
    var canvas = new Element.tag('canvas');
    expect(js_util.instanceof(canvas, JSNodeType), isTrue);
    expect(js_util.instanceof(canvas, JSTextType), isFalse);
    expect(js_util.instanceof(canvas, JSElementType), isTrue);
    expect(js_util.instanceof(canvas, JSHtmlCanvasElementType), isTrue);
    var div = new Element.tag('div');
    expect(js_util.instanceof(div, JSNodeType), isTrue);
    expect(js_util.instanceof(div, JSTextType), isFalse);
    expect(js_util.instanceof(div, JSElementType), isTrue);
    expect(js_util.instanceof(div, JSHtmlCanvasElementType), isFalse);

    var text = new Text('foo');
    expect(js_util.instanceof(text, JSNodeType), isTrue);
    expect(js_util.instanceof(text, JSTextType), isTrue);
    expect(js_util.instanceof(text, JSElementType), isFalse);

    var f = new Foo();
    expect(js_util.instanceof(f, JSNodeType), isFalse);
  });

  test('callConstructor', () {
    var textNode = js_util.callConstructor(JSTextType, ['foo']);
    expect(js_util.instanceof(textNode, JSTextType), isTrue);
    expect(textNode is Text, isTrue);
    expect(textNode.text, equals('foo'));
  });
}
