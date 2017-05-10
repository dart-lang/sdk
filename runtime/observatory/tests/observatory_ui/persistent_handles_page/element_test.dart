// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/persistent_handles.dart';
import '../mocks.dart';

main() {
  PersistentHandlesPageElement.tag.ensureRegistration();

  const vm = const VMMock();
  const isolate = const IsolateRefMock();
  final events = new EventRepositoryMock();
  final notifs = new NotificationRepositoryMock();
  final repository = new PersistentHandlesRepositoryMock();
  final objects = new ObjectRepositoryMock();
  test('instantiation', () {
    final e = new PersistentHandlesPageElement(
        vm, isolate, events, notifs, repository, objects);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
  });
  test('elements created after attachment', () async {
    final repository = new PersistentHandlesRepositoryMock(
        getter: expectAsync((i) async {
      expect(i, equals(isolate));
      return const PersistentHandlesMock();
    }, count: 1));
    final objects = new ObjectRepositoryMock();
    final e = new PersistentHandlesPageElement(
        vm, isolate, events, notifs, repository, objects);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
