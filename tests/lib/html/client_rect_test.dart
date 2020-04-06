// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isRectList =
      predicate((x) => x is DomRectList, 'should be a DomRectList');
  var isListOfRectangle =
      predicate((x) => x is List<Rectangle>, 'should be a List<Rectangle>');

  var isRectangle = predicate((x) => x is Rectangle, 'should be a Rectangle');
  var isDomRectReadOnly =
      predicate((x) => x is DomRectReadOnly, 'should be a DomRectReadOnly');

  insertTestDiv() {
    var element = new Element.tag('div');
    element.innerHtml = r'''
    A large block of text should go here. Click this
    block of text multiple times to see each line
    highlight with every click of the mouse button.
    ''';
    document.body!.append(element);
    return element;
  }

  test("DomRectList test", () {
    insertTestDiv();
    var range = new Range();
    var rects = range.getClientRects();
    expect(rects, isListOfRectangle);
    expect(rects, isRectList);
  });

  test("ClientRect ==", () {
    var rect1 = document.body!.getBoundingClientRect();
    var rect2 = document.body!.getBoundingClientRect();
    expect(rect1, isRectangle);
    expect(rect1, isDomRectReadOnly);
    expect(rect1, equals(rect2));
  });
}
