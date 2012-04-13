#library('CrossFrameTest');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  useDomConfiguration();

  test('contentWindow', () {
      final iframe = document.createElement('iframe');
      document.body.appendChild(iframe);
      final frameWindow = iframe.contentWindow;

      // Test this field to ensure a valid Dart wrapper.
      Expect.isNull(frameWindow.dartObjectLocalStorage);

      // Ensure that the frame's document is inaccessible via window.
      Expect.throws(() => frameWindow.document);
    });

  test('contentDocument', () {
      final iframe = document.createElement('iframe');
      document.body.appendChild(iframe);

      // Ensure that the frame's document is inaccessible.
      Expect.throws(() => iframe.contentDocument);
    });
}
