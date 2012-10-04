#library('CrossFrameTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  final iframe = new Element.tag('iframe');
  document.body.nodes.add(iframe);

  test('window', () {
      expect(window is LocalWindow);
      expect(window.document == document);
    });

  test('iframe', () {
      final frameWindow = iframe.contentWindow;
      expect(frameWindow is Window);
      expect(frameWindow is! LocalWindow);
      expect(frameWindow.parent is LocalWindow);

      // Ensure that the frame's document is inaccessible via window.
      expect(() => frameWindow.document, throws);
    });

  test('contentDocument', () {
      // Ensure that the frame's document is inaccessible.
      expect(() => iframe.contentDocument, throws);
    });

  test('location', () {
      expect(window.location is LocalLocation);
      final frameLocation = iframe.contentWindow.location;
      expect(frameLocation is Location);
      expect(frameLocation is! LocalLocation);

      expect(() => frameLocation.href, throws);
      expect(() => frameLocation.hash, throws);

      final frameParentLocation = iframe.contentWindow.parent.location;
      expect(frameParentLocation is LocalLocation);
    });

  test('history', () {
      expect(window.history is LocalHistory);
      final frameHistory = iframe.contentWindow.history;
      expect(frameHistory is History);
      expect(frameHistory is! LocalHistory);

      // Valid methods.
      frameHistory.back();
      frameHistory.forward();

      expect(() => frameHistory.length, throws);

      final frameParentHistory = iframe.contentWindow.parent.history;
      expect(frameParentHistory is LocalHistory);
    });
}
