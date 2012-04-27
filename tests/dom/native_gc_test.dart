#library('NativeGCTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('EventListener', () {
      final int N = 1000000;
      final int M = 1000;

      var div;
      for (int i = 0; i < M; ++i) {
        // This memory should be freed when the listener below is
        // collected.
        List l = new List(N);

        // Record the iteration number.
        l[N - 1] = i;

        div = new Element.tag('div');
        div.on['test'].add((_) {
            // Only the final iteration's listener should be invoked.
            // Note: the reference to l keeps the entire list alive.
            Expect.equals(M - 1, l[N - 1]);
          }, false);
      }

      final event = new Event('test');
      div.on['test'].dispatch(event);
  });
}
