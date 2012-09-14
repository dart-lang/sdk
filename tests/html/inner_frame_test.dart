#library('InnerFrameTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  if (window != window.top) {
    // Child frame.

    // The child's frame should not be able to access its parent's
    // document.

    // Check window.frameElement.
    try {
      var parentDocument = window.frameElement.document;
      var div = parentDocument.$dom_createElement("div");
      div.id = "illegalFrameElement";
      parentDocument.body.nodes.add(div);
      Expect.fail('Should not reach here.');
    } on NoSuchMethodError catch (e) {
      // Expected.
    }

    // Check window.top.
    try {
      final top = window.top;
      var parentDocument = top.document;
      var div = parentDocument.$dom_createElement("div");
      div.id = "illegalTop";
      parentDocument.body.nodes.add(div);
      Expect.fail('Should not reach here.');
    } catch (e) {
      // Expected.
      // TODO(vsm): Enforce this is a NoSuchMethodError.
    }
    return;
  }

  // Parent / test frame
  useHtmlConfiguration();

  final iframe = new Element.tag('iframe');
  iframe.src = window.location.href;

  test('prepare', () {
      iframe.on.load.add(expectAsync1((e) {}));
      document.body.nodes.add(iframe);
    });

  test('frameElement', () {
      var div = document.query('#illegalFrameElement');

      // Ensure that this parent frame was not modified by its child.
      Expect.isNull(div);
    });

  test('top', () {
      var div = document.query('#illegalTop');

      // Ensure that this parent frame was not modified by its child.
      Expect.isNull(div);
    });
}
