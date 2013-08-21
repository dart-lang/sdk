library async_test;

import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

import 'dart:async';
import 'dart:isolate';
import 'dart:html';

oneshotTimerIsolate() {
  port.receive((msg, replyTo) {
    expect(msg, 'START');
    new Timer(const Duration(milliseconds: 10), () {
      replyTo.send('DONE');
    });
  });
}

periodicTimerIsolate() {
  port.receive((msg, replyTo) {
    expect(msg, 'START');
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
  });
}

cancellingIsolate() {
  port.receive((msg, replyTo) {
    expect(msg, 'START');
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
  });
}

main() {
  useHtmlConfiguration();

  test('one shot timer in pure isolate', () {
    expect(spawnFunction(oneshotTimerIsolate).call('START'),
           completion('DONE'));
  });
  test('periodic timer in pure isolate', () {
    expect(spawnFunction(periodicTimerIsolate).call('START'),
           completion('DONE'));
  });
  test('cancellation in pure isolate', () {
    expect(spawnFunction(cancellingIsolate).call('START'),
           completion('DONE'));
  });
}
