// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/vm_connect_target.dart';
import 'package:observatory/src/elements/vm_connect.dart';
import '../mocks.dart';

void load(_) {}

main() {
  VMConnectElement.tag.ensureRegistration();

  final nTag = NavNotifyElement.tag.name;
  final tTag = VMConnectTargetElement.tag.name;

  group('instantiation', () {
    test('default', () {
      final e = new VMConnectElement(new TargetRepositoryMock(),
          load, new NotificationRepositoryMock());
      expect(e, isNotNull, reason: 'element correctly created');
    });
  });
  test('is correctly listening', () async {
    final targets = new TargetRepositoryMock();
    final e = new VMConnectElement(targets, load,
        new NotificationRepositoryMock());
    document.body.append(e);
    await e.onRendered.first;
    expect(targets.hasListeners, isTrue, reason: 'is listening');
    e.remove();
    await e.onRendered.first;
    expect(targets.hasListeners, isFalse, reason: 'is no more listening');
  });
  group('elements', () {
    test('created after attachment', () async {
      final targets = new TargetRepositoryMock(list: const [
          const TargetMock(name: 't-1'), const TargetMock(name: 't-2'),
          ]);
      final e = new VMConnectElement(targets, load,
          new NotificationRepositoryMock());
      document.body.append(e);
      await e.onRendered.first;
      expect(targets.listInvoked, isTrue, reason: 'should invoke list()');
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(nTag).length, equals(1));
      expect(e.querySelectorAll(tTag).length, equals(2));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('react to update event', () async {
      final list = <TargetMock>[const TargetMock(name: 't-1')];
      final targets = new TargetRepositoryMock(list: list);
      final e = new VMConnectElement(targets, load,
          new NotificationRepositoryMock());
      document.body.append(e);
      await e.onRendered.first;
      expect(e.querySelectorAll(tTag).length, equals(1));
      list.add(const TargetMock(name: 't-2'));
      targets.triggerChangeEvent();
      await e.onRendered.first;
      expect(e.querySelectorAll(tTag).length, equals(2));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
  group('invokes', () {
    test('add on click', () async {
      final address = 'ws://host:1234/ws';
      final list = <TargetMock>[const TargetMock(name: 't-1')];
      final targets = new TargetRepositoryMock(list: list,
          add: expectAsync((String val) {
            expect(val, equals(address));
          }, count: 1, reason: 'should be invoked'));
      final e = new VMConnectElement(targets, load,
          new NotificationRepositoryMock(), address: address);
      document.body.append(e);
      await e.onRendered.first;
      (e.querySelector('button.vm_connect') as ButtonElement).click();
      e.remove();
      await e.onRendered.first;
    });
    test('connect', () async {
      final list = <TargetMock>[const TargetMock(name: 't-1')];
      final targets = new TargetRepositoryMock(list: list,
          setCurrent: expectAsync((TargetMock t) {
            expect(t, equals(list[0]));
          }, count: 1, reason: 'should be invoked'));
      final e = new VMConnectElement(targets, load,
          new NotificationRepositoryMock());
      document.body.append(e);
      await e.onRendered.first;
      (e.querySelector(tTag) as VMConnectTargetElement).connect();
      e.remove();
      await e.onRendered.first;
    });
    test('delete', () async {
      final list = <TargetMock>[const TargetMock(name: 't-1')];
      final targets = new TargetRepositoryMock(list: list,
          delete: expectAsync((TargetMock t) {
            expect(t, equals(list[0]));
          }, count: 1, reason: 'should be invoked'));
      final e = new VMConnectElement(targets, load,
          new NotificationRepositoryMock());
      document.body.append(e);
      await e.onRendered.first;
      (e.querySelector(tTag) as VMConnectTargetElement).delete();
      e.remove();
      await e.onRendered.first;
    });
  });
}
