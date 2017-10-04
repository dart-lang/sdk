library KeyboardEventTest;

import 'dart:html';

import 'package:expect/minitest.dart';

// Test that we are correctly determining keyCode and charCode uniformly across
// browsers.

void testKeyboardEventConstructor() {
  new KeyboardEvent('keyup');
}

void keydownHandlerTest(KeyEvent e) {
  expect(e.charCode, 0);
}

void testKeys() {
  var subscription =
      KeyboardEventStream.onKeyDown(document.body).listen(keydownHandlerTest);
  var subscription2 =
      KeyEvent.keyDownEvent.forTarget(document.body).listen(keydownHandlerTest);
  var subscription3 =
      document.body.onKeyDown.listen((e) => print('regular listener'));
  subscription.cancel();
  subscription2.cancel();
  subscription3.cancel();
}

void testConstructKeyEvent() {
  int handlerCallCount = 0;
  CustomStream<KeyEvent> stream =
      KeyEvent.keyPressEvent.forTarget(document.body);
  var subscription = stream.listen((keyEvent) {
    expect(keyEvent.charCode, 97);
    expect(keyEvent.keyCode, 65);
    handlerCallCount++;
  });
  var k = new KeyEvent('keypress', keyCode: 65, charCode: 97);
  stream.add(k);
  subscription.cancel();
  // Capital "A":
  stream.add(new KeyEvent('keydown', keyCode: 16, charCode: 0));

  subscription = stream.listen((keyEvent) {
    expect(keyEvent.charCode, 65);
    expect(keyEvent.keyCode, 65);
    handlerCallCount++;
  });
  stream.add(new KeyEvent('keypress', keyCode: 65, charCode: 65));
  subscription.cancel();

  expect(handlerCallCount, 2);
}

void testKeyEventSequence() {
  int handlerCallCount = 0;
  // Press "?" by simulating "shift" and then the key that has "/" and "?" on
  // it.
  CustomStream<KeyEvent> streamDown =
      KeyEvent.keyDownEvent.forTarget(document.body);
  CustomStream<KeyEvent> streamPress =
      KeyEvent.keyPressEvent.forTarget(document.body);
  CustomStream<KeyEvent> streamUp =
      KeyEvent.keyUpEvent.forTarget(document.body);

  var subscription = streamDown.listen((keyEvent) {
    expect(keyEvent.keyCode, predicate([16, 191].contains));
    expect(keyEvent.charCode, 0);
    handlerCallCount++;
  });

  var subscription2 = streamPress.listen((keyEvent) {
    expect(keyEvent.keyCode, 23);
    expect(keyEvent.charCode, 63);
    handlerCallCount++;
  });

  var subscription3 = streamUp.listen((keyEvent) {
    expect(keyEvent.keyCode, predicate([16, 191].contains));
    expect(keyEvent.charCode, 0);
    handlerCallCount++;
  });

  streamDown.add(new KeyEvent('keydown', keyCode: 16, charCode: 0));
  streamDown.add(new KeyEvent('keydown', keyCode: 191, charCode: 0));

  streamPress.add(new KeyEvent('keypress', keyCode: 23, charCode: 63));

  streamUp.add(new KeyEvent('keyup', keyCode: 191, charCode: 0));
  streamUp.add(new KeyEvent('keyup', keyCode: 16, charCode: 0));
  subscription.cancel();
  subscription2.cancel();
  subscription3.cancel();

  expect(handlerCallCount, 5);
}

void testKeyEventKeyboardEvent() {
  int handlerCallCount = 0;
  window.onKeyDown.listen((event) {
    expect(event.keyCode, 16);
    handlerCallCount++;
  });
  CustomStream<KeyEvent> streamDown =
      KeyEvent.keyDownEvent.forTarget(document.body);
  streamDown.add(new KeyEvent('keydown', keyCode: 16, charCode: 0));
  expect(handlerCallCount, 1);
}

main() {
  testKeyboardEventConstructor();
  testKeys();
  testConstructKeyEvent();
  testKeyEventSequence();
  testKeyEventKeyboardEvent();
}
