// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library DOMIsolatesTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:isolate';

childDomIsolate() {
  port.receive((msg, replyTo) {
    if (msg != 'check') {
      replyTo.send('wrong msg: $msg');
    }
    replyTo.send('${window.location}');
    port.close();
  });
}

trampolineIsolate() {
  final future = spawnDomFunction(childDomIsolate);
  port.receive((msg, parentPort) {
    future.then((childPort) {
      childPort.call(msg).then((response) {
        parentPort.send(response);
        port.close();
      });
    });
  });
}

dummy() => print('Bad invocation of top-level function');

main() {
  useHtmlConfiguration();

  test('Simple DOM isolate test', () {
    spawnDomFunction(childDomIsolate).then(expectAsync1(
        (sendPort) {
            expect(sendPort.call('check'), completion('${window.location}'));
        }
    ));
  });

  test('Nested DOM isolates test', () {
    spawnDomFunction(trampolineIsolate).then(expectAsync1(
        (sendPort) {
            expect(sendPort.call('check'), completion('${window.location}'));
        }
    ));
  });

  test('Spawn DOM isolate from pure', () {
    expect(spawnFunction(trampolineIsolate).call('check'),
           completion('${window.location}'));
  });

  test('Spawn DOM by uri', () {
    spawnDomUri('dom_isolates_test.dart.child_isolate.dart').then(expectAsync1(
        (sendPort) {
            expect(sendPort.call('check'), completion('${window.location}'));
        }
    ));
  });

  test('Not function', () {
      expect(() => spawnDomFunction(42), throws);
  });

  test('Not topLevelFunction', () {
    var closure = guardAsync(() {});
    expect(() => spawnDomFunction(closure), throws);
  });

  test('Masked local function', () {
    var local = 42;
    dummy() => print('Bad invocation of local function: $local');
    expect(() => spawnDomFunction(dummy), throws);
  });
}
