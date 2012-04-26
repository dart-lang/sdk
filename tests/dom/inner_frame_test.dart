#library('InnerFrameTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  if (window != window.top) {
    // Child frame.

    // The child's frame should not be able to access its parent's
    // document.

    // Check window.frameElement.
    try {
      var parentDocument = window.frameElement.ownerDocument;
      var div = parentDocument.createElement("div");
      div.id = "illegalFrameElement";
      parentDocument.body.appendChild(div);
      Expect.fail('Should not reach here.');
    } catch (NoSuchMethodException e) {
      // Expected.
    }

    // Check window.top.
    try {
      final top = window.top;
      var parentDocument = top.document;
      var div = parentDocument.createElement("div");
      div.id = "illegalTop";
      parentDocument.body.appendChild(div);
      Expect.fail('Should not reach here.');
    } catch (var e) {
      // Expected.
      // TODO(vsm): Enforce this is a NoSuchMethodException.
    }
    return;
  }

  // Parent / test frame
  useDomConfiguration();

  final iframe = document.createElement('iframe');
  iframe.src = window.location.href;

  asyncTest('prepare', 1, () {
      iframe.addEventListener('load', (e) => callbackDone(), false);
      document.body.appendChild(iframe);
    });

  test('frameElement', () {
      var div = document.getElementById('illegalFrameElement');

      // Ensure that this parent frame was not modified by its child.
      Expect.isNull(div);
    });

  test('top', () {
      var div = document.getElementById('illegalTop');

      // Ensure that this parent frame was not modified by its child.
      Expect.isNull(div);
    });
}
