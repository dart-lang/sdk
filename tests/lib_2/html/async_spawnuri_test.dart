library async_spawnuri_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import 'dart:async';
import 'dart:isolate';
import 'dart:html';

// OtherScripts=async_oneshot.dart async_periodictimer.dart async_cancellingisolate.dart
main() {
  useHtmlConfiguration();

  test('one shot timer in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawnUri(
        Uri.parse('async_oneshot.dart'), ['START'], response.sendPort);
    remote.catchError((x) => expect("Error in oneshot isolate", x));
    expect(remote.then((_) => response.first), completion('DONE'));
  });

  test('periodic timer in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawnUri(
        Uri.parse('async_periodictimer.dart'), ['START'], response.sendPort);
    remote.catchError((x) => expect("Error in periodic timer isolate", x));
    expect(remote.then((_) => response.first), completion('DONE'));
  });

  test('cancellation in pure isolate', () {
    var response = new ReceivePort();
    var remote = Isolate.spawnUri(Uri.parse('async_cancellingisolate.dart'),
        ['START'], response.sendPort);
    remote.catchError((x) => expect("Error in cancelling isolate", x));
    expect(remote.then((_) => response.first), completion('DONE'));
  });
}
