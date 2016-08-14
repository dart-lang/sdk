// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' hide Notification, NotificationEvent;
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/notify_event.dart';
import 'package:observatory/src/elements/nav/notify_exception.dart';
import '../../mocks.dart';

main() {
  NavNotifyElement.tag.ensureRegistration();

  final evTag = NavNotifyEventElement.tag.name;
  final exTag = NavNotifyExceptionElement.tag.name;

  const vm = const VMRefMock();
  const isolate = const IsolateRefMock(id: 'i-id', name: 'i-name');

  group('instantiation', () {
    NotificationRepositoryMock repository;
    setUp(() {
      repository = new NotificationRepositoryMock();
    });
    test('default', () {
      final e = new NavNotifyElement(repository);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.notifyOnPause, isTrue, reason: 'notifyOnPause is default');
    });
    test('notify on pause', () {
      final e = new NavNotifyElement(repository, notifyOnPause: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.notifyOnPause, isTrue, reason: 'notifyOnPause is the same');
    });
    test('do not notify on pause', () {
      final e = new NavNotifyElement(repository, notifyOnPause: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.notifyOnPause, isFalse, reason: 'notifyOnPause is the same');
    });
  });
  test('is correctly listening', () async {
    final repository = new NotificationRepositoryMock();
    final e = new NavNotifyElement(repository);
    document.body.append(e);
    await e.onRendered.first;
    expect(repository.hasListeners, isTrue, reason: 'is listening');
    e.remove();
    await e.onRendered.first;
    expect(repository.hasListeners, isFalse, reason: 'is no more listening');
  });
  group('elements', () {
    test('created after attachment', () async {
      final repository =
          new NotificationRepositoryMock(list: [
            new ExceptionNotificationMock(exception: new Exception("ex")),
            const EventNotificationMock(event: const VMUpdateEventMock(vm: vm)),
            const EventNotificationMock(event: const VMUpdateEventMock(vm: vm))
          ]);
      final e = new NavNotifyElement(repository);
      document.body.append(e);
      await e.onRendered.first;
      expect(repository.listInvoked, isTrue, reason: 'should invoke list()');
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(evTag).length, equals(2));
      expect(e.querySelectorAll(exTag).length, equals(1));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('react to notifyOnPause change', () async {
      final NotificationRepositoryMock repository =
          new NotificationRepositoryMock(list: [
            new ExceptionNotificationMock(exception: new Exception("ex")),
            const EventNotificationMock(event: const VMUpdateEventMock()),
            const EventNotificationMock(
                event: const PauseStartEventMock(isolate: isolate))
          ]);
      final e = new NavNotifyElement(repository, notifyOnPause: true);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.querySelectorAll(evTag).length, equals(2));
      expect(e.querySelectorAll(exTag).length, equals(1));
      e.notifyOnPause = false;
      await e.onRendered.first;
      expect(e.querySelectorAll(evTag).length, equals(1));
      expect(e.querySelectorAll(exTag).length, equals(1));
      e.notifyOnPause = true;
      await e.onRendered.first;
      expect(e.querySelectorAll(evTag).length, equals(2));
      expect(e.querySelectorAll(exTag).length, equals(1));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('react to update event', () async {
      final List<M.Notification> list = [
        new ExceptionNotificationMock(exception: new Exception("ex")),
        const EventNotificationMock(event: const VMUpdateEventMock()),
      ];
      final repository = new NotificationRepositoryMock(list: list);
      final e = new NavNotifyElement(repository, notifyOnPause: true);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.querySelectorAll(evTag).length, equals(1));
      expect(e.querySelectorAll(exTag).length, equals(1));
      list.add(const EventNotificationMock(
          event: const PauseStartEventMock(isolate: isolate)));
      repository.triggerChangeEvent();
      await e.onRendered.first;
      expect(e.querySelectorAll(evTag).length, equals(2));
      expect(e.querySelectorAll(exTag).length, equals(1));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
}
