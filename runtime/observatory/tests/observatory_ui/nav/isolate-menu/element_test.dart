// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart';
import 'package:observatory/mocks.dart';
import 'package:observatory/src/elements/nav/menu.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';

main(){
  NavIsolateMenuElement.tag.ensureRegistration();

  final String tag = NavMenuElement.tag.name;

  StreamController<IsolateUpdateEvent> updatesController;
  final IsolateRefMock ref = const IsolateRefMock(id: 'i-id', name: 'old-name');
  final IsolateMock obj = const IsolateMock(id: 'i-id', name: 'new-name');
  setUp(() {
    updatesController = new StreamController<IsolateUpdateEvent>();
  });
  group('instantiation', () {
    test('IsolateRef', () {
      final NavIsolateMenuElement e = new NavIsolateMenuElement(ref,
                                      updatesController.stream);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(ref));
    });
    test('Isolate', () {
      final NavIsolateMenuElement e = new NavIsolateMenuElement(obj,
                                      updatesController.stream);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(obj));
    });
  });
  test('elements created after attachment', () async {
    final NavIsolateMenuElement e = new NavIsolateMenuElement(ref,
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
      final NavIsolateMenuElement e = new NavIsolateMenuElement(ref,
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
      final NavIsolateMenuElement e = new NavIsolateMenuElement(ref,
                                      updatesController.stream);
      document.body.append(e);
      await e.onRendered.first;
      expect((e.shadowRoot.querySelector(tag) as NavMenuElement)
             .label.contains(ref.name), isTrue);
      updatesController.add(new IsolateUpdateEventMock(isolate: obj));
      await e.onRendered.first;
      expect((e.shadowRoot.querySelector(tag) as NavMenuElement)
             .label.contains(ref.name), isFalse);
      expect((e.shadowRoot.querySelector(tag) as NavMenuElement)
            .label.contains(obj.name), isTrue);
      e.remove();
    });
  });
}
