// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import '../../mocks.dart';

main(){
  NavVMMenuElement.tag.ensureRegistration();

  final mTag = '.nav-menu_label > a';
  final miTag = NavMenuItemElement.tag.name;

  EventRepositoryMock events;
  final vm1 = const VMMock(name: 'vm-name-1', displayName: 'display-name-1',
      isolates: const [const IsolateRefMock(id: 'i-id-1', name: 'i-name-1')]);
  final vm2 = const VMMock(name: 'vm-name-2', displayName: 'display-name-2',
      isolates: const [const IsolateRefMock(id: 'i-id-1', name: 'i-name-1'),
                       const IsolateRefMock(id: 'i-id-2', name: 'i-name-2')]);
  setUp(() {
    events = new EventRepositoryMock();
  });
  test('instantiation', () {
    final e = new NavVMMenuElement(vm1, events);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.vm, equals(vm1));
  });
  test('elements created after attachment', () async {
    final e = new NavVMMenuElement(vm1, events);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
  group('updates', () {
    test('are correctly listen', () async {
      final e = new NavVMMenuElement(vm1, events);
      expect(events.onVMUpdateHasListener, isFalse);
      document.body.append(e);
      await e.onRendered.first;
      expect(events.onVMUpdateHasListener, isTrue);
      e.remove();
      await e.onRendered.first;
      expect(events.onVMUpdateHasListener, isFalse);
    });
    test('have effects', () async {
      final e = new NavVMMenuElement(vm1, events);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.querySelectorAll(mTag).single.text, equals(vm1.displayName));
      expect(e.querySelectorAll(miTag).length,
          equals(vm1.isolates.length));
      events.add(new VMUpdateEventMock(vm: vm2));
      await e.onRendered.first;
      expect(e.querySelectorAll(mTag).single.text, equals(vm2.displayName));
      expect(e.querySelectorAll(miTag).length,
          equals(vm2.isolates.length));
      e.remove();
    });
  });
}
