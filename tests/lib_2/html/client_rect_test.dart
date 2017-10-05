import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isRectList =
      predicate((x) => x is List<Rectangle>, 'is a List<Rectangle>');

  insertTestDiv() {
    var element = new Element.tag('div');
    element.innerHtml = r'''
    A large block of text should go here. Click this
    block of text multiple times to see each line
    highlight with every click of the mouse button.
    ''';
    document.body.append(element);
    return element;
  }

  test("ClientRectList test", () {
    insertTestDiv();
    var range = new Range();
    var rects = range.getClientRects();
    expect(rects, isRectList);
  });

  test("ClientRect ==", () {
    var rect1 = document.body.getBoundingClientRect();
    var rect2 = document.body.getBoundingClientRect();
    expect(rect1, equals(rect2));
  });
}
