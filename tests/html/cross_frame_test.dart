#library('CrossFrameTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('contentWindow', () {
      final iframe = new Element.tag('iframe');
      document.body.nodes.add(iframe);
      final frameWindow = iframe.contentWindow;

      // Ensure that the frame's document is inaccessible via window.
      Expect.throws(() => frameWindow.document);
    });

  test('contentDocument', () {
      final iframe = new Element.tag('iframe');
      document.body.nodes.add(iframe);

      // Ensure that the frame's document is inaccessible.
      Expect.throws(() => iframe.contentDocument);
    });
}
