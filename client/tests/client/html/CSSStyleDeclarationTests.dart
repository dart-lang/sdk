// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testCSSStyleDeclaration() {
  getStyle() {
    return new CSSStyleDeclaration.css("""
      color: blue;
      width: 2px !important;
      -webkit-transform: rotate(90deg);
    """);
  };

  test('default constructor is empty', () {
    var style = new CSSStyleDeclaration();
    Expect.equals("", style.cssText);
    Expect.equals("", style.getPropertyPriority('color'));
    Expect.equals("", style.item(0));
    Expect.equals(0, style.length);
    // Expect.isNull(style.parentRule);
    // Expect.isNull(style.getPropertyCSSValue('color'));
    // Expect.isNull(style.getPropertyShorthand('color'));
  });

  test('cssText is wrapped', () {
    var style = getStyle();
    Expect.equals(
      "color: blue; width: 2px !important; -webkit-transform: rotate(90deg); ",
      style.cssText);
    style.cssText = "color: red";
    Expect.equals("color: red; ", style.cssText);
  });

  test('length is wrapped', () {
    Expect.equals(3, getStyle().length);
  });

  test('getPropertyPriority is wrapped', () {
    var style = getStyle();
    Expect.equals("", style.getPropertyPriority("color"));
    Expect.equals("important", style.getPropertyPriority("width"));
  });

  test('item is wrapped', () {
    var style = getStyle();
    Expect.equals("color", style.item(0));
    Expect.equals("width", style.item(1));
    Expect.equals("-webkit-transform", style.item(2));
  });

  test('removeProperty is wrapped', () {
    var style = getStyle();
    style.removeProperty("width");
    Expect.equals(
      "color: blue; -webkit-transform: rotate(90deg); ",
      style.cssText);
  });

  test('getters and setters are generated', () {
    var style = getStyle();
    Expect.equals("blue", style.color);
    Expect.equals("2px", style.width);
    Expect.equals("rotate(90deg)", style.transform);

    style.color = "red";
    style.transform = "translate(10px, 20px)";
    Expect.equals(
      "width: 2px !important; color: red; -webkit-transform: translate(10px, 20px); ",
      style.cssText);
  });
}