// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/class_tree.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import '../mocks.dart';

main() {
  ClassTreeElement.tag.ensureRegistration();

  final nTag = NavNotifyElement.tag.name;
  const vm = const VMMock();
  const isolate = const IsolateRefMock();
  final events = new EventRepositoryMock();
  final notifications = new NotificationRepositoryMock();

  group('instantiation', () {
    test('default', () {
      final e = new ClassTreeElement(vm, isolate, events, notifications,
          new ClassRepositoryMock());
      expect(e, isNotNull, reason: 'element correctly created');
    });
  });
  group('elements', () {
    test('created after attachment', () async {
      const child2_id = 'c2-id';
      const child1_1_id = 'c1_1-id';
      const child1_id = 'c1-id';
      const child2 = const ClassMock(id: child2_id);
      const child1_1 = const ClassMock(id: child1_1_id);
      const child1 = const ClassMock(id: child1_id,
                                     subclasses: const [child1_1]);
      const object = const ClassMock(id: 'o-id',
                                     subclasses: const [child1, child2]);
      const ids = const [child1_id, child1_1_id, child2_id];
      bool rendered = false;
      final e = new ClassTreeElement(vm, isolate, events, notifications,
          new ClassRepositoryMock(
              object: expectAsync((i) async {
                expect(i, equals(isolate));
                expect(rendered, isFalse);
                return object;
              }, count: 1),
              getter: expectAsync((i, id) async {
                expect(i, equals(isolate));
                expect(ids.contains(id), isTrue);
                switch (id) {
                  case child1_id: return child1;
                  case child1_1_id: return child1_1;
                  case child2_id: return child2;
                  default: return null;
                }
              }, count: 3)));
      document.body.append(e);
      await e.onRendered.first;
      rendered = true;
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(nTag).length, equals(1));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
}
