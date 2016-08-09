// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/notify_event.dart';
import '../../mocks.dart';

main() {
  NavNotifyEventElement.tag.ensureRegistration();

  final event = new PauseStartEventMock(
              isolate: new IsolateMock(id: 'isolate-id', name: 'isolate-name'));
  group('instantiation', () {
    final e = new NavNotifyEventElement(event);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.event, equals(event));
  });
  group('elements', () {
    test('created after attachment', () async {
      final e = new NavNotifyEventElement(event);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
  group('events are fired', () {
    NavNotifyEventElement e;
    StreamSubscription sub;
    setUp(() async {
      e = new NavNotifyEventElement(event);
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
      sub = e.onDelete.listen(expectAsync((EventDeleteEvent ev) {
        expect(ev, isNotNull, reason: 'event is passed');
        expect(ev.event, equals(event),
                                            reason: 'exception is the same');
      }, count: 1, reason: 'event is fired'));
      e.querySelector('button').click();
    });
    test('onDelete events (code)', () async {
      sub = e.onDelete.listen(expectAsync((EventDeleteEvent ev) {
        expect(ev, isNotNull, reason: 'event is passed');
        expect(ev.event, equals(event),
                                            reason: 'exception is the same');
      }, count: 1, reason: 'event is fired'));
      e.delete();
    });
  });
}
