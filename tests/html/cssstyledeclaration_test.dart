// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('CSSStyleDeclarationTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  createTestStyle() {
    return new CSSStyleDeclaration.css("""
      color: blue;
      width: 2px !important;
    """);
  };

  test('default constructor is empty', () {
    var style = new CSSStyleDeclaration();
    expect(style.cssText, isEmpty);
    expect(style.getPropertyPriority('color'), isEmpty);
    expect(style.item(0), isEmpty);
    expect(style, hasLength(0));
    // These assertions throw a NotImplementedException in dartium:
    // Expect.isNull(style.parentRule);
    // Expect.isNull(style.getPropertyCSSValue('color'));
    // Expect.isNull(style.getPropertyShorthand('color'));
  });

  test('length is wrapped', () {
    expect(createTestStyle(), hasLength(2));
  });

  test('getPropertyPriority is wrapped', () {
    var style = createTestStyle();
    expect(style.getPropertyPriority("color"), isEmpty);
    expect(style.getPropertyPriority("width"), equals("important"));
  });

  test('removeProperty is wrapped', () {
    var style = createTestStyle();
    style.removeProperty("width");
    expect(style.cssText.trim(),
      equals("color: blue;"));
  });

  test('CSS property empty getters and setters', () {
    var style = createTestStyle();
    expect(style.border, equals(""));
    
    style.border = "1px solid blue";
    style.border = "";
    expect(style.border, equals(""));
  });

  test('CSS property getters and setters', () {
    var style = createTestStyle();
    expect(style.color, equals("blue"));
    expect(style.width, equals("2px"));

    style.color = "red";
    style.transform = "translate(10px, 20px)";

    expect(style.color, equals("red"));
    expect(style.transform, equals("translate(10px, 20px)"));
  });

  test('Browser prefixes', () {
    var element = new DivElement();
    element.style.transform = 'translateX(10px)';
    document.body.elements.add(element);

    element.getComputedStyle('').then(expectAsync1(
      (CSSStyleDeclaration style) {
        // Some browsers will normalize this, so it'll be a matrix rather than
        // the original string. Just check that it's something other than null.
        expect(style.transform.length, greaterThan(3));
      }
    ));
  });

  // IE9 requires an extra poke for some properties to get applied.
  test('IE9 Invalidation', () {
    var element = new DivElement();
    document.body.elements.add(element);

    // Need to wait one tick after the element has been added to the page.
    window.setTimeout(expectAsync0(() {
      element.style.textDecoration = 'underline';
      element.getComputedStyle('').then(expectAsync1(
        (CSSStyleDeclaration style) {
          expect(style.textDecoration, equals('underline'));
        }
      ));
    }), 10);
  });
}
