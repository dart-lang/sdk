library async_periodictimer;

import 'dart:async';
import 'package:unittest/unittest.dart';

main(message, replyTo) {
  var command = message.first;
  expect(command, 'START');
  int counter = 0;
  new Timer.periodic(const Duration(milliseconds: 10), (timer) {
    if (counter == 3) {
      counter = 1024;
      timer.cancel();
      // Wait some more time to be sure callback won't be invoked any
      // more.
      new Timer(const Duration(milliseconds: 30), () {
        replyTo.send('DONE');
      });
      return;
    }
    assert(counter < 3);
    counter++;
  });
}
