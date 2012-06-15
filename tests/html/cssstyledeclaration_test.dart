// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('CSSStyleDeclarationTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  createTestStyle() {
    return new CSSStyleDeclaration.css("""
      color: blue;
      width: 2px !important;
      -webkit-transform: rotate(90deg);
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

  test('cssText is wrapped', () {
    var style = createTestStyle();
    expect(style.cssText,
      equals("color: blue; width: 2px !important; "
             "-webkit-transform: rotate(90deg); "));
    style.cssText = "color: red";
    expect(style.cssText, equals("color: red; "));
  });

  test('length is wrapped', () {
    expect(createTestStyle(), hasLength(3));
  });

  test('getPropertyPriority is wrapped', () {
    var style = createTestStyle();
    expect(style.getPropertyPriority("color"), isEmpty);
    expect(style.getPropertyPriority("width"), equals("important"));
  });

  test('item is wrapped', () {
    var style = createTestStyle();
    expect(style.item(0), equals("color"));
    expect(style.item(1), equals("width"));
    expect(style.item(2), equals("-webkit-transform"));
  });

  test('removeProperty is wrapped', () {
    var style = createTestStyle();
    style.removeProperty("width");
    expect(style.cssText,
      equals("color: blue; -webkit-transform: rotate(90deg); "));
  });

  test('CSS property getters and setters', () {
    var style = createTestStyle();
    expect(style.color, equals("blue"));
    expect(style.width, equals("2px"));
    expect(style.transform, equals("rotate(90deg)"));

    style.color = "red";
    style.transform = "translate(10px, 20px)";
    expect(style.cssText,
      equals("color: red; width: 2px !important;"
             " -webkit-transform: translate(10px, 20px); "));
  });
}
