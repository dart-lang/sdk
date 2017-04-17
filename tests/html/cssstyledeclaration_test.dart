// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library CssStyleDeclarationTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:async';
import 'utils.dart';

main() {
  useHtmlConfiguration();

  createTestStyle() {
    return new CssStyleDeclaration.css("""
      color: blue;
      width: 2px !important;
    """);
  }

  ;

  test('default constructor is empty', () {
    var style = new CssStyleDeclaration();
    expect(style.cssText, isEmpty);
    expect(style.getPropertyPriority('color'), isEmpty);
    expect(style.item(0), isEmpty);
    expect(style, hasLength(0));
    // These assertions throw a UnimplementedError in dartium:
    // expect(style.parentRule, isNull);
    // expect(style.getPropertyCssValue('color'), isNull);
    // expect(style.getPropertyShorthand('color'), isNull);
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
    expect(style.cssText.trim(), equals("color: blue;"));
  });

  test('CSS property empty getters and setters', () {
    var style = createTestStyle();
    expect(style.border, equals(""));

    style.border = "1px solid blue";
    style.border = "";
    expect(style.border, equals(""));

    style.border = "1px solid blue";
    style.border = null;
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
    document.body.children.add(element);

    var style = element.getComputedStyle();
    // Some browsers will normalize this, so it'll be a matrix rather than
    // the original string. Just check that it's something other than null.
    expect(style.transform.length, greaterThan(3));
  });

  // IE9 requires an extra poke for some properties to get applied.
  test('IE9 Invalidation', () {
    var element = new DivElement();
    document.body.children.add(element);

    // Need to wait one tick after the element has been added to the page.
    new Timer(const Duration(milliseconds: 10), expectAsync(() {
      element.style.textDecoration = 'underline';
      var style = element.getComputedStyle();
      expect(style.textDecoration, contains('underline'));
    }));
  });

  test('Invalid values', () {
    var element = new DivElement();
    // Should not throw an error.
    element.style.background = 'some_bad_value';
  });

  test('css multi get', () {
    var listElement = new Element.html(
        '<ul class="foo">'
        '<li class="bar" style="background-color: red; border-left: 10px;">'
        '<li class="baz" style="background-color: black;>'
        '<li class="baz classy" style="background-color: blue; ">'
        '</ul>',
        treeSanitizer: new NullTreeSanitizer());
    document.documentElement.children.add(listElement);

    var elements = document.queryAll('li');
    expect(elements.style.backgroundColor, equals('red'));
    expect(elements.style.borderLeftWidth, equals('10px'));
    elements = document.queryAll('.baz');
    expect(elements.style.backgroundColor, equals('black'));
    expect(elements.style.borderLeftWidth, equals(''));
    elements = document.queryAll('.bar');
    expect(elements.style.backgroundColor, equals('red'));
  });

  test('css multi set', () {
    var listElement = new Element.html(
        '<ul class="foo">'
        '<li class="bar" style="background-color: red; border-left: 10px;">'
        '<li class="baz" style="background-color: black;>'
        '<li class="baz" id="wat" style="background-color: blue; ">'
        '</ul>',
        treeSanitizer: new NullTreeSanitizer());
    document.documentElement.children.add(listElement);

    var elements = document.queryAll('li');
    elements.style.backgroundColor = 'green';
    expect(elements.style.backgroundColor, equals('green'));
    expect(elements.style.borderLeftWidth, equals('10px'));

    elements = document.queryAll('.baz');
    expect(elements.style.backgroundColor, equals('green'));
    elements.style.backgroundColor = 'yellow';
    expect(elements.style.backgroundColor, equals('yellow'));
    expect(elements.style.borderLeftWidth, equals(''));

    elements = document.queryAll('.bar');
    expect(elements.style.backgroundColor, equals('green'));
    elements = document.queryAll('#wat');
    expect(elements.style.backgroundColor, equals('yellow'));

    elements.style.borderLeftWidth = '18px';
    expect(elements.style.borderLeftWidth, equals('18px'));
    elements = document.queryAll('li');
    expect(elements.style.borderLeftWidth, equals('10px'));
  });

  test('supports property', () {
    expect(document.body.style.supportsProperty('bogus-property'), false);
    expect(document.body.style.supportsProperty('background'), true);
    expect(document.body.style.supportsProperty('borderBottomWidth'), true);
    expect(document.body.style.supportsProperty('animation'), true);
  });
}
