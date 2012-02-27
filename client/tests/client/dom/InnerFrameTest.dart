#library('InnerFrameTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

main() {
  if (window != window.top) {
    // Child frame.

    // The child's frame should not be able to access its parent's
    // document.
    try {
      var parentDocument = window.frameElement.ownerDocument;
      var div = parentDocument.createElement("div");
      div.id = "illegal";
      parentDocument.body.appendChild(div);
      Expect.fail('Should not reach here.');
    } catch (NoSuchMethodException e) {
      // Expected.
    }
    return;
  }

  // Parent / test frame
  forLayoutTests();

  final iframe = document.createElement('iframe');
  iframe.src = window.location.href;

  asyncTest('prepare', 1, () {
      iframe.addEventListener('load', (e) => callbackDone(), false);
      document.body.appendChild(iframe);
    });

  test('frameElement', () {
      var div = document.getElementById('illegal');

      // Ensure that this parent frame was not modified by its child.
      Expect.isNull(div);
    });
}
