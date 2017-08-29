// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/allocation_profile.dart';
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/containers/virtual_collection.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import '../mocks.dart';

main() {
  AllocationProfileElement.tag.ensureRegistration();

  final cTag = ClassRefElement.tag.name;
  final rTag = NavRefreshElement.tag.name;
  final vTag = VirtualCollectionElement.tag.name;

  const vm = const VMMock();
  const isolate = const IsolateRefMock();
  final events = new EventRepositoryMock();
  final notif = new NotificationRepositoryMock();
  test('instantiation', () {
    final repo = new AllocationProfileRepositoryMock();
    final e = new AllocationProfileElement(vm, isolate, events, notif, repo);
    expect(e, isNotNull, reason: 'element correctly created');
  });
  test('elements created', () async {
    final completer = new Completer<AllocationProfileMock>();
    final repo = new AllocationProfileRepositoryMock(
        getter:
            expectAsync((M.IsolateRef i, bool gc, bool reset, bool combine) {
      expect(i, equals(isolate));
      expect(gc, isFalse);
      expect(reset, isFalse);
      expect(combine, isFalse);
      return completer.future;
    }, count: 1));
    final e = new AllocationProfileElement(vm, isolate, events, notif, repo);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll(vTag).length, isZero);
    completer.complete(const AllocationProfileMock());
    await e.onRendered.first;
    expect(e.querySelectorAll(vTag).length, equals(1));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
  group('reacts', () {
    test('to refresh', () async {
      final completer = new Completer<AllocationProfileMock>();
      int step = 0;
      final repo = new AllocationProfileRepositoryMock(
          getter:
              expectAsync((M.IsolateRef i, bool gc, bool reset, bool combine) {
        expect(i, equals(isolate));
        expect(combine, isFalse);
        switch (step) {
          case 0:
            expect(gc, isFalse);
            expect(reset, isFalse);
            break;
          case 1:
            expect(gc, isFalse);
            expect(reset, isTrue);
            break;
          case 2:
            expect(gc, isTrue);
            expect(reset, isFalse);
            break;
          case 3:
            expect(gc, isFalse);
            expect(reset, isFalse);
            break;
        }
        step++;
        return completer.future;
      }, count: 4));
      final e = new AllocationProfileElement(vm, isolate, events, notif, repo);
      document.body.append(e);
      await e.onRendered.first;
      completer.complete(const AllocationProfileMock());
      await e.onRendered.first;
      e
          .querySelectorAll(rTag)
          .sublist(1, 4)
          .forEach((NavRefreshElement e) => e.refresh());
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('to gc', () async {
      final events = new EventRepositoryMock();
      final completer = new Completer<AllocationProfileMock>();
      int count = 0;
      final repo = new AllocationProfileRepositoryMock(
          getter:
              expectAsync((M.IsolateRef i, bool gc, bool reset, bool combine) {
        expect(i, equals(isolate));
        expect(gc, isFalse);
        expect(reset, isFalse);
        expect(combine, isFalse);
        count++;
        return completer.future;
      }, count: 2));
      final e = new AllocationProfileElement(vm, isolate, events, notif, repo);
      document.body.append(e);
      await e.onRendered.first;
      completer.complete(const AllocationProfileMock());
      await e.onRendered.first;
      e.querySelector('input[type=\'checkbox\']').click();
      expect(events.onGCEventHasListener, isTrue);
      events.add(new GCEventMock(isolate: isolate));
      await e.onRendered.first;
      expect(count, equals(2));
      // shouldn't trigger
      events.add(new GCEventMock(isolate: new IsolateRefMock(id: 'another')));
      await (() async {}());
      e.querySelector('input[type=\'checkbox\']').click();
      // shouldn't trigger
      events.add(new GCEventMock(isolate: isolate));
      await (() async {}());
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('to sort change', () async {
      const clazz1 = const ClassRefMock(name: 'class1');
      const clazz2 = const ClassRefMock(name: 'class2');
      const clazz3 = const ClassRefMock(name: 'class3');
      const profile = const AllocationProfileMock(members: const [
        const ClassHeapStatsMock(clazz: clazz1),
        const ClassHeapStatsMock(
            clazz: clazz2,
            newSpace: const AllocationsMock(
                current: const AllocationCountMock(bytes: 10)),
            oldSpace: const AllocationsMock(
                current: const AllocationCountMock(bytes: 2))),
        const ClassHeapStatsMock(
            clazz: clazz3,
            newSpace: const AllocationsMock(
                current: const AllocationCountMock(bytes: 5)),
            oldSpace: const AllocationsMock(
                current: const AllocationCountMock(bytes: 3)))
      ]);
      final completer = new Completer<AllocationProfileMock>();
      final repo = new AllocationProfileRepositoryMock(
          getter:
              expectAsync((M.IsolateRef i, bool gc, bool reset, bool combine) {
        expect(i, equals(isolate));
        expect(gc, isFalse);
        expect(reset, isFalse);
        expect(combine, isFalse);
        return completer.future;
      }, count: 1));
      final e = new AllocationProfileElement(vm, isolate, events, notif, repo);
      document.body.append(e);
      await e.onRendered.first;
      completer.complete(profile);
      await e.onRendered.first;
      expect((e.querySelector(cTag) as ClassRefElement).cls, equals(clazz2));
      e.querySelector('button.name').click();
      await e.onRendered.first;
      expect((e.querySelector(cTag) as ClassRefElement).cls, equals(clazz1));
      e.querySelector('button.name').click();
      await e.onRendered.first;
      expect((e.querySelector(cTag) as ClassRefElement).cls, equals(clazz3));
      e.querySelectorAll('button.bytes').last.click();
      await e.onRendered.first;
      expect((e.querySelector(cTag) as ClassRefElement).cls, equals(clazz3));
      e.querySelectorAll('button.bytes').last.click();
      await e.onRendered.first;
      expect((e.querySelector(cTag) as ClassRefElement).cls, equals(clazz1));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
}
