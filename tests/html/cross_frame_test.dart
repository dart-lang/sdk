#library('CrossFrameTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('contentWindow', () {
      final iframe = new Element.tag('iframe');
      document.body.nodes.add(iframe);
      final frameWindow = iframe.contentWindow;

      // Ensure that the frame's document is inaccessible via window.
      expect(() => frameWindow.document, throws);
    });

  test('contentDocument', () {
      final iframe = new Element.tag('iframe');
      document.body.nodes.add(iframe);

      // Ensure that the frame's document is inaccessible.
      expect(() => iframe.contentDocument, throws);
    });
}
