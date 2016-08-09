// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/isolate_ref.dart';
import '../mocks.dart';

main() {
  IsolateRefElement.tag.ensureRegistration();

  final ref = new IsolateRefMock(id: 'id', name: 'old-name');
  final events = new EventRepositoryMock();
  final obj = new IsolateMock(id: 'id', name: 'new-name');
  group('instantiation', () {
    test('IsolateRef', () {
      final e = new IsolateRefElement(ref, events);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(ref));
    });
    test('Isolate', () {
      final e = new IsolateRefElement(obj, events);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(obj));
    });
  });
  test('elements created after attachment', () async {
    final e = new IsolateRefElement(ref, events);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
  group('updates', () {
    test('are correctly listen', () async {
      final e = new IsolateRefElement(ref, events);
      expect(events.onIsolateUpdateHasListener, isFalse);
      document.body.append(e);
      await e.onRendered.first;
      expect(events.onIsolateUpdateHasListener, isTrue);
      e.remove();
      await e.onRendered.first;
      expect(events.onIsolateUpdateHasListener, isFalse);
    });
    test('have effects', () async {
      final e = new IsolateRefElement(ref, events);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.innerHtml.contains(ref.id), isTrue);
      events.add(new IsolateUpdateEventMock(isolate: obj));
      await e.onRendered.first;
      expect(e.innerHtml.contains(ref.name), isFalse);
      expect(e.innerHtml.contains(obj.name), isTrue);
      e.remove();
    });
  });
}
