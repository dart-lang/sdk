library async_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import 'dart:async';
import 'dart:isolate';
import 'dart:html';

import 'async_oneshot.dart' as oneshot_test show main;
import 'async_periodictimer.dart' as periodictimer_test show main;
import 'async_cancellingisolate.dart' as cancelling_test show main;

oneshot(message) => oneshot_test.main(message.first, message.last);
periodicTimerIsolate(message) =>
    periodictimer_test.main(message.first, message.last);
cancellingIsolate(message) => cancelling_test.main(message.first, message.last);

main() {
  useHtmlConfiguration();

  test('one shot timer in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawn(oneshot, [
      ['START'],
      response.sendPort
    ]);
    expect(remote.then((_) => response.first), completion('DONE'));
  });

  test('periodic timer in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawn(periodicTimerIsolate, [
      ['START'],
      response.sendPort
    ]);
    expect(remote.then((_) => response.first), completion('DONE'));
  });

  test('cancellation in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawn(cancellingIsolate, [
      ['START'],
      response.sendPort
    ]);
    expect(remote.then((_) => response.first), completion('DONE'));
  });
}
