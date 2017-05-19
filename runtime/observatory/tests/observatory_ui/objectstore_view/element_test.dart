// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/objectstore_view.dart';
import '../mocks.dart';

main() {
  ObjectStoreViewElement.tag.ensureRegistration();

  const vm = const VMMock();
  const isolate = const IsolateRefMock();
  final events = new EventRepositoryMock();
  final notifs = new NotificationRepositoryMock();
  final stores = new ObjectStoreRepositoryMock();
  final objects = new ObjectRepositoryMock();
  test('instantiation', () {
    final e = new ObjectStoreViewElement(
        vm, isolate, events, notifs, stores, objects);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
  });
  test('elements created after attachment', () async {
    const fields = const [
      const NamedFieldMock(name: 'field-1'),
      const NamedFieldMock(name: 'field-2'),
      const NamedFieldMock(name: 'field-3')
    ];
    const store = const ObjectStoreMock(fields: fields);
    final stores = new ObjectStoreRepositoryMock(
        getter: expectAsync((i) async {
      expect(i, equals(isolate));
      return store;
    }, count: 1));
    final objects = new ObjectRepositoryMock();
    final e = new ObjectStoreViewElement(
        vm, isolate, events, notifs, stores, objects);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll('.memberItem').length, equals(fields.length));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
