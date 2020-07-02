// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Put universally passing event constructors in this file.
// Move constructors that fail on some configuration to their own
// element_constructor_foo_test.dart file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isAnchorElement =
      predicate((x) => x is AnchorElement, 'is an AnchorElement');
  var isAreaElement = predicate((x) => x is AreaElement, 'is an AreaElement');
  var isDivElement = predicate((x) => x is DivElement, 'is a DivElement');
  var isCanvasElement =
      predicate((x) => x is CanvasElement, 'is a CanvasElement');
  var isParagraphElement =
      predicate((x) => x is ParagraphElement, 'is a ParagraphElement');
  var isSpanElement = predicate((x) => x is SpanElement, 'is a SpanElement');
  var isSelectElement =
      predicate((x) => x is SelectElement, 'is a SelectElement');

  test('anchor1', () {
    var e = new AnchorElement();
    expect(e, isAnchorElement);
  });

  test('anchor2', () {
    var e = new AnchorElement(href: '#blah');
    expect(e, isAnchorElement);
    expect(e.href.endsWith('#blah'), isTrue);
  });

  test('area', () {
    var e = new AreaElement();
    expect(e, isAreaElement);
  });

  // AudioElement tested in audioelement_test.dart

  test('div', () {
    var e = new DivElement();
    expect(e, isDivElement);
  });

  test('canvas1', () {
    var e = new CanvasElement();
    expect(e, isCanvasElement);
  });

  test('canvas2', () {
    var e = new CanvasElement(height: 100, width: 200);
    expect(e, isCanvasElement);
    expect(e.width, 200);
    expect(e.height, 100);
  });

  test('p', () {
    var e = new ParagraphElement();
    expect(e, isParagraphElement);
  });

  test('span', () {
    var e = new SpanElement();
    expect(e, isSpanElement);
  });

  test('select', () {
    var e = new SelectElement();
    expect(e, isSelectElement);
  });
}
