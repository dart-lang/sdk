#library('AsyncWindowTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {
  useDomConfiguration();
  asyncTest('Window.setTimeout', 1, () {
    window.setTimeout(callbackDone, 10);
  });
  asyncTest('Window.setInterval', 1, () {
    int counter = 0;
    int id = null;
    id = window.setInterval(() {
      if (counter == 3) {
        counter = 1024;
        window.clearInterval(id);
        // Wait some more time to be sure callback won't be invoked any more.
        window.setTimeout(callbackDone, 50);
        return;
      }
      // As callback should have been cleared on 4th invocation, counter
      // should never be greater than 3.
      assert(counter < 3);
      counter++;
    }, 10);
  });
}
