// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CSSStyleDeclarationTests extends UnitTestSuite {
  CSSStyleDeclarationTests(): super();

  static void main() {
    new CSSStyleDeclarationTests().run();
  }

  void setUpTestSuite() {
    addTest(testCssText);
    addTest(testLength);
    addTest(testGetPropertyCSSValue);
    addTest(testGetPropertyPriority);
    addTest(testItem);
    addTest(testRemoveProperty);
    addTest(testGettersAndSetters);
  }

  void testCssText() {
    var style = _style;
    Expect.equals(
      "color: blue; width: 2px !important; -webkit-transform: rotate(90deg); ",
      style.cssText);
    style.cssText = "color: red";
    Expect.equals("color: red; ", style.cssText);
  }

  void testLength() {
    Expect.equals(3, _style.length);
  }

  void testGetPropertyCSSValue() {
    Expect.equals("blue", _style.getPropertyCSSValue("color").cssText);
  }

  void testGetPropertyPriority() {
    var style = _style;
    Expect.equals("", style.getPropertyPriority("color"));
    Expect.equals("important", style.getPropertyPriority("width"));
  }

  void testItem() {
    var style = _style;
    Expect.equals("color", style.item(0));
    Expect.equals("width", style.item(1));
    Expect.equals("-webkit-transform", style.item(2));
  }

  void testRemoveProperty() {
    var style = _style;
    style.removeProperty("width");
    Expect.equals(
      "color: blue; -webkit-transform: rotate(90deg); ",
      style.cssText);
  }

  void testGettersAndSetters() {
    var style = _style;
    Expect.equals("blue", style.color);
    Expect.equals("2px", style.width);
    Expect.equals("rotate(90deg)", style.transform);

    style.color = "red";
    style.transform = "translate(10px, 20px)";
    Expect.equals(
      "width: 2px !important; color: red; -webkit-transform: translate(10px, 20px); ",
      style.cssText);
  }

  CSSStyleDeclaration get _style() {
    return new Element.html("""<div style='
      color: blue;
      width: 2px !important;
      -webkit-transform: rotate(90deg);
    '></div>""").style;
  }
}