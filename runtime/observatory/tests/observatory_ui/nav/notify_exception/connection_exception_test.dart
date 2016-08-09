// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/notify_exception.dart';
import '../../mocks.dart';

main() {
  NavNotifyExceptionElement.tag.ensureRegistration();

  final exception = new ConnectionExceptionMock(message: 'message');
  test('instantiation', () {
    final e = new NavNotifyExceptionElement(exception);
    expect(e, isNotNull, reason: 'element correctly created');
  });
  test('elements created after attachment', () async {
    final e = new NavNotifyExceptionElement(exception);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
  group('events are fired', () {
    NavNotifyExceptionElement e;
    StreamSubscription sub;
    setUp(() async {
      e = new NavNotifyExceptionElement(exception);
      document.body.append(e);
      await e.onRendered.first;
    });
    tearDown(() {
      sub.cancel();
      e.remove();
    });
    test('navigation after connect', () async {
      sub = window.onPopState.listen(expectAsync((_) {}, count: 1,
        reason: 'event is fired'));
      e.querySelector('a').click();
    });
    test('onDelete events (DOM)', () async {
      sub = e.onDelete.listen(expectAsync((ExceptionDeleteEvent event) {
        expect(event, isNotNull, reason: 'event is passed');
        expect(event.exception, equals(exception),
                                              reason: 'exception is the same');
        expect(event.stacktrace, isNull);
      }, count: 1, reason: 'event is fired'));
      e.querySelector('button').click();
    });
    test('onDelete events (code)', () async {
      sub = e.onDelete.listen(expectAsync((ExceptionDeleteEvent event) {
        expect(event, isNotNull, reason: 'event is passed');
        expect(event.exception, equals(exception),
                                              reason: 'exception is the same');
        expect(event.stacktrace, isNull);
      }, count: 1, reason: 'event is fired'));
      e.delete();
    });
  });
}
