library KeyboardEventTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

// Test that we are correctly determining keyCode and charCode uniformly across
// browsers.

main() {

  useHtmlConfiguration();

  keydownHandlerTest(KeyEvent e) {
    expect(e.charCode, 0);
  }

  test('keys', () {
    // This test currently is pretty much a no-op because we
    // can't (right now) construct KeyboardEvents with specific keycode/charcode
    // values (a KeyboardEvent can be "init"-ed but not all the information can
    // be programmatically populated. It exists as an example for how to use
    // KeyboardEventController more than anything else.
    var controller = new KeyboardEventController.keydown(document.window);
    var func = keydownHandlerTest;
    controller.add(func);
    document.window.on.keyDown.add((e) => print('regular listener'), false);
  });
}


