library async_test;

import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

import 'dart:async';
import 'dart:isolate';
import 'dart:html';

oneshotTimerIsolate(message) {
  var command = message[0];
  var replyTo = message[1];
  expect(command, 'START');
  new Timer(const Duration(milliseconds: 10), () {
    replyTo.send('DONE');
  });
}

periodicTimerIsolate(message) {
  var command = message[0];
  var replyTo = message[1];
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

cancellingIsolate(message) {
  var command = message[0];
  var replyTo = message[1];
  expect(command, 'START');
  bool shot = false;
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

main() {
  useHtmlConfiguration();

  test('one shot timer in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawn(oneshotTimerIsolate,
                               ['START', response.sendPort]);
    expect(remote.then((_) => response.first), completion('DONE'));
  });
  test('periodic timer in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawn(periodicTimerIsolate,
                               ['START', response.sendPort]);
    expect(remote.then((_) => response.first), completion('DONE'));
  });
  test('cancellation in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawn(cancellingIsolate,
                               ['START', response.sendPort]);
    expect(remote.then((_) => response.first), completion('DONE'));
  });
}
