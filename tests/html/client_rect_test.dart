#library('ClientRectTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {

  insertTestDiv() {
    var element = new Element.tag('div');
    element.innerHTML = @'''
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
    var range = document.createRange();
    List<ClientRect> rects = range.getClientRects();
    Expect.isTrue(rects is List<ClientRect>);
  });
}
