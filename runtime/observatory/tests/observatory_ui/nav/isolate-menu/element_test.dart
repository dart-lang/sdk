// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import '../../mocks.dart';

main() {
  NavIsolateMenuElement.tag.ensureRegistration();

  final tag = '.nav-menu_label > a';

  EventRepositoryMock events;
  final ref = const IsolateRefMock(id: 'i-id', name: 'old-name');
  final obj = const IsolateMock(id: 'i-id', name: 'new-name');
  setUp(() {
    events = new EventRepositoryMock();
  });
  group('instantiation', () {
    test('IsolateRef', () {
      final e = new NavIsolateMenuElement(ref, events);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(ref));
    });
    test('Isolate', () {
      final e = new NavIsolateMenuElement(obj, events);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(obj));
    });
  });
  test('elements created after attachment', () async {
    final e = new NavIsolateMenuElement(ref, events);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
  group('updates', () {
    test('are correctly listen', () async {
      final e = new NavIsolateMenuElement(ref, events);
      expect(events.onIsolateUpdateHasListener, isFalse);
      document.body.append(e);
      await e.onRendered.first;
      expect(events.onIsolateUpdateHasListener, isTrue);
      e.remove();
      await e.onRendered.first;
      expect(events.onIsolateUpdateHasListener, isFalse);
    });
    test('have effects', () async {
      final e = new NavIsolateMenuElement(ref, events);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.querySelector(tag).text.contains(ref.name), isTrue);
      events.add(new IsolateUpdateEventMock(isolate: obj));
      await e.onRendered.first;
      expect(e.querySelector(tag).text.contains(ref.name), isFalse);
      expect(e.querySelector(tag).text.contains(obj.name), isTrue);
      e.remove();
    });
  });
}
