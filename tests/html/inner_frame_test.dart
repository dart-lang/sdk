#library('InnerFrameTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
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
    } catch (NoSuchMethodException e) {
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
    } catch (var e) {
      // Expected.
      // TODO(vsm): Enforce this is a NoSuchMethodException.
    }
    return;
  }

  // Parent / test frame
  useHtmlConfiguration();

  final iframe = new Element.tag('iframe');
  iframe.src = window.location.href;

  asyncTest('prepare', 1, () {
      iframe.on.load.add((e) => callbackDone());
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
