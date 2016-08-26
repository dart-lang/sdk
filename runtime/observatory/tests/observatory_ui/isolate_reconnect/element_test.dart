// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/isolate_reconnect.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import '../mocks.dart';

main() {
  IsolateReconnectElement.tag.ensureRegistration();

  final nTag = NavNotifyElement.tag.name;

  EventRepositoryMock events;
  NotificationRepositoryMock notifications;
  Uri uri;
  const vm = const VMMock(isolates: const [
    const IsolateMock(id: 'i-1-id'), const IsolateMock(id: 'i-2-id')
  ]);
  const missing = 'missing-id';
  setUp(() {
    events = new EventRepositoryMock();
    notifications = new NotificationRepositoryMock();
    uri = new  Uri(path: 'path');
  });
  test('instantiation', () {
    final e = new IsolateReconnectElement(vm, events, notifications, missing,
                                          uri);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.vm, equals(vm));
    expect(e.missing, equals(missing));
    expect(e.uri, equals(uri));
  });
  test('elements created after attachment', () async {
    final e = new IsolateReconnectElement(vm, events, notifications, missing,
                                          uri);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelector(nTag), isNotNull, reason: 'has notifications');
    expect(e.querySelectorAll('.isolate-link').length,
        equals(vm.isolates.length), reason: 'has links');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
  group('updates', () {
    test('are correctly listen', () async {
      final e = new IsolateReconnectElement(vm, events, notifications, missing,
                                            uri);
      expect(events.onVMUpdateHasListener, isFalse);
      document.body.append(e);
      await e.onRendered.first;
      expect(events.onVMUpdateHasListener, isTrue);
      e.remove();
      await e.onRendered.first;
      expect(events.onVMUpdateHasListener, isFalse);
    });
    test('have effects', () async {
      final e = new IsolateReconnectElement(vm, events, notifications, missing,
                                            uri);
      const vm2 = const VMMock(isolates: const [
          const IsolateMock(id: 'i-1-id'), const IsolateMock(id: 'i-2-id'),
          const IsolateMock(id: 'i-3-id')
      ]);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.querySelectorAll('.isolate-link').length,
          equals(vm.isolates.length));
      events.add(new VMUpdateEventMock(vm: vm2));
      await e.onRendered.first;
      expect(e.querySelectorAll('.isolate-link').length,
          equals(vm2.isolates.length));
      e.remove();
      await e.onRendered.first;
    });
  });
}
