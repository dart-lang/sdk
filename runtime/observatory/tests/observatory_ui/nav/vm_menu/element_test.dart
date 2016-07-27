// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/mocks.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/nav/menu.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

main(){
  NavVMMenuElement.tag.ensureRegistration();

  final mTag = NavMenuElement.tag.name;
  final miTag = NavMenuItemElement.tag.name;

  StreamController<M.VMUpdateEvent> updatesController;
  final TargetMock target = new TargetMock(name: 'target-name');
  final VMMock vm1 = const VMMock(name: 'vm-name-1',
      isolates: const [const IsolateRefMock(id: 'i-id-1', name: 'i-name-1')]);
  final VMMock vm2 = const VMMock(name: 'vm-name-2',
      isolates: const [const IsolateRefMock(id: 'i-id-1', name: 'i-name-1'),
                       const IsolateRefMock(id: 'i-id-2', name: 'i-name-2')]);
  setUp(() {
    updatesController = new StreamController<M.VMUpdateEvent>.broadcast();
  });
  group('instantiation', () {
    test('no target', () {
      final NavVMMenuElement e = new NavVMMenuElement(vm1,
          updatesController.stream);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.vm, equals(vm1));
      expect(e.target, isNull);
    });
    test('target', () {
      final NavVMMenuElement e = new NavVMMenuElement(vm1,
          updatesController.stream, target: target);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.vm, equals(vm1));
      expect(e.target, equals(target));
    });
  });
  test('elements created after attachment', () async {
    final NavVMMenuElement e = new NavVMMenuElement(vm1,
        updatesController.stream);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.shadowRoot.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.shadowRoot.children.length, isZero, reason: 'is empty');
  });
  group('updates', () {
    test('are correctly listen', () async {
      final NavVMMenuElement e = new NavVMMenuElement(vm1,
          updatesController.stream);
      expect(updatesController.hasListener, isFalse);
      document.body.append(e);
      await e.onRendered.first;
      expect(updatesController.hasListener, isTrue);
      e.remove();
      await e.onRendered.first;
      expect(updatesController.hasListener, isFalse);
    });
    test('have effects', () async {
      final NavVMMenuElement e = new NavVMMenuElement(vm1,
          updatesController.stream);
      document.body.append(e);
      await e.onRendered.first;
      expect((e.shadowRoot.querySelector(mTag) as NavMenuElement).label,
          equals(vm1.name));
      expect(e.shadowRoot.querySelectorAll(miTag).length,
          equals(vm1.isolates.length));
      updatesController.add(new VMUpdateEventMock(vm: vm2));
      await e.onRendered.first;
      expect((e.shadowRoot.querySelector(mTag) as NavMenuElement).label,
          equals(vm2.name));
      expect(e.shadowRoot.querySelectorAll(miTag).length,
          equals(vm2.isolates.length));
      e.remove();
    });
  });
}
