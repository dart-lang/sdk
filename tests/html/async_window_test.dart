library AsyncWindowTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('Window.setTimeout', () {
    window.setTimeout(expectAsync0((){}), 10);
  });
  test('Window.setInterval', () {
    int counter = 0;
    int id = null;
    id = window.setInterval(expectAsync0(() {
      if (counter == 3) {
        counter = 1024;
        window.clearInterval(id);
        // Wait some more time to be sure callback won't be invoked any more.
        window.setTimeout(expectAsync0((){}), 50);
        return;
      }
      // As callback should have been cleared on 4th invocation, counter
      // should never be greater than 3.
      assert(counter < 3);
      counter++;
    }, 3), 10);
  });
}
