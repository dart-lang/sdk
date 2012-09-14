// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Put universally passing event constructors in this file.
// Move constructors that fail on some configuration to their own
// element_constructor_foo_test.dart file.

#library('ElementConstructorTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('anchor1', () {
      var e = new AnchorElement();
      Expect.isTrue(e is AnchorElement);
    });

  test('anchor2', () {
      var e = new AnchorElement(href: '#blah');
      Expect.isTrue(e is AnchorElement);
      Expect.isTrue(e.href.endsWith('#blah'));
    });

  test('area', () {
      var e = new AreaElement();
      Expect.isTrue(e is AreaElement);
    });

  // AudioElement tested in audioelement_test.dart

  test('div', () {
      var e = new DivElement();
      Expect.isTrue(e is DivElement);
    });

  test('canvas1', () {
      var e = new CanvasElement();
      Expect.isTrue(e is CanvasElement);
    });

  test('canvas2', () {
      var e = new CanvasElement(height: 100, width: 200);
      Expect.isTrue(e is CanvasElement);
      Expect.equals(200, e.width);
      Expect.equals(100, e.height);
    });

  test('p', () {
      var e = new ParagraphElement();
      Expect.isTrue(e is ParagraphElement);
    });

  test('span', () {
      var e = new SpanElement();
      Expect.isTrue(e is SpanElement);
    });

  test('select', () {
      var e = new SelectElement();
      Expect.isTrue(e is SelectElement);
    });
}
