library async_cancellingisolate;

import 'dart:async';
import 'package:unittest/unittest.dart';

main(message, replyTo) {
  var command = message.first;
  expect(command, 'START');
  var shot = false;
  var oneshot;
  var periodic;
  periodic = new Timer.periodic(const Duration(milliseconds: 10), (timer) {
    expect(shot, isFalse);
    shot = true;
    expect(timer, same(periodic));
    periodic.cancel();
    oneshot.cancel();
    // Wait some more time to be sure callbacks won't be invoked any
    // more.
    new Timer(const Duration(milliseconds: 50), () {
      replyTo.send('DONE');
    });
  });
  // We launch the oneshot timer after the periodic timer. Otherwise a
  // (very long) context switch could make this test flaky: assume the
  // oneshot timer is created first and then there is a 30ms context switch.
  // when the periodic timer is scheduled it would execute after the oneshot.
  oneshot = new Timer(const Duration(milliseconds: 30), () {
    fail('Should never be invoked');
  });
}
