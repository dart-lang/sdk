library ClientRectTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {

  var isRectList =
      predicate((x) => x is List<Rect>, 'is a List<Rect>');

  insertTestDiv() {
    var element = new Element.tag('div');
    element.innerHtml = r'''
    A large block of text should go here. Click this
    block of text multiple times to see each line
    highlight with every click of the mouse button.
    ''';
    document.body.nodes.add(element);
    return element;
  }

  useHtmlConfiguration();

   test("ClientRectList test", () {
    insertTestDiv();
    var range = new Range();
    var rects = range.getClientRects();
    expect(rects, isRectList);
  });
}
