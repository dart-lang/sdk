library AsyncWindowTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:async';

main() {
  useHtmlConfiguration();
  test('Timer', () {
    new Timer(const Duration(milliseconds: 10), expectAsync0((){}));
  });
  test('Timer.periodic', () {
    int counter = 0;
    int id = null;
    new Timer.periodic(const Duration(milliseconds: 10),
        expectAsyncUntil1(
        (timer) {
          if (counter == 3) {
            counter = 1024;
            timer.cancel();
            // Wait some more time to be sure callback won't be invoked any
            // more.
            new Timer(const Duration(milliseconds: 50), expectAsync0((){}));
            return;
          }
          // As callback should have been cleared on 4th invocation, counter
          // should never be greater than 3.
          assert(counter < 3);
          counter++;
        },
        () => counter == 3));
  });
}
