library KeyboardEventTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

// Test that we are correctly determining keyCode and charCode uniformly across
// browsers.

main() {
  useHtmlConfiguration();

  keydownHandlerTest(KeyEvent e) {
    expect(e.charCode, 0);
  }

  test('keyboardEvent constructor', () {
    var event = new KeyboardEvent('keyup');
  });
  test('keys', () {
    var subscription =
        KeyboardEventStream.onKeyDown(document.body).listen(keydownHandlerTest);
    var subscription2 = KeyEvent.keyDownEvent
        .forTarget(document.body)
        .listen(keydownHandlerTest);
    var subscription3 =
        document.body.onKeyDown.listen((e) => print('regular listener'));
    subscription.cancel();
    subscription2.cancel();
    subscription3.cancel();
  });

  test('constructKeyEvent', () {
    var stream = KeyEvent.keyPressEvent.forTarget(document.body);
    var subscription = stream.listen(expectAsync((keyEvent) {
      expect(keyEvent.charCode, 97);
      expect(keyEvent.keyCode, 65);
    }));
    var k = new KeyEvent('keypress', keyCode: 65, charCode: 97);
    stream.add(k);
    subscription.cancel();
    // Capital "A":
    stream.add(new KeyEvent('keydown', keyCode: 16, charCode: 0));

    subscription = stream.listen(expectAsync((keyEvent) {
      expect(keyEvent.charCode, 65);
      expect(keyEvent.keyCode, 65);
    }));
    stream.add(new KeyEvent('keypress', keyCode: 65, charCode: 65));
    subscription.cancel();
  });

  test('KeyEventSequence', () {
    // Press "?" by simulating "shift" and then the key that has "/" and "?" on
    // it.
    var streamDown = KeyEvent.keyDownEvent.forTarget(document.body);
    var streamPress = KeyEvent.keyPressEvent.forTarget(document.body);
    var streamUp = KeyEvent.keyUpEvent.forTarget(document.body);

    var subscription = streamDown.listen(expectAsync((keyEvent) {
      expect(keyEvent.keyCode, isIn([16, 191]));
      expect(keyEvent.charCode, 0);
    }, count: 2));

    var subscription2 = streamPress.listen(expectAsync((keyEvent) {
      expect(keyEvent.keyCode, 23);
      expect(keyEvent.charCode, 63);
    }));

    var subscription3 = streamUp.listen(expectAsync((keyEvent) {
      expect(keyEvent.keyCode, isIn([16, 191]));
      expect(keyEvent.charCode, 0);
    }, count: 2));

    streamDown.add(new KeyEvent('keydown', keyCode: 16, charCode: 0));
    streamDown.add(new KeyEvent('keydown', keyCode: 191, charCode: 0));

    streamPress.add(new KeyEvent('keypress', keyCode: 23, charCode: 63));

    streamUp.add(new KeyEvent('keyup', keyCode: 191, charCode: 0));
    streamUp.add(new KeyEvent('keyup', keyCode: 16, charCode: 0));
    subscription.cancel();
    subscription2.cancel();
    subscription3.cancel();
  });

  test('KeyEventKeyboardEvent', () {
    window.onKeyDown.listen(expectAsync((KeyboardEvent event) {
      expect(event.keyCode, 16);
    }));
    var streamDown = KeyEvent.keyDownEvent.forTarget(document.body);
    streamDown.add(new KeyEvent('keydown', keyCode: 16, charCode: 0));
  });
}
