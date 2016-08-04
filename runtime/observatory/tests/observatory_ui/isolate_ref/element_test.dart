// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart';
import 'package:observatory/mocks.dart';
import 'package:observatory/src/elements/isolate_ref.dart';

main(){
  IsolateRefElement.tag.ensureRegistration();

  StreamController<IsolateUpdateEvent> updatesController;
  final IsolateRefMock ref = new IsolateRefMock(id: 'id', name: 'old-name');
  final IsolateMock obj = new IsolateMock(id: 'id', name: 'new-name');
  setUp(() {
    updatesController = new StreamController<IsolateUpdateEvent>();
  });
  group('instantiation', () {
    test('IsolateRef', () {
      final IsolateRefElement e = new IsolateRefElement(ref,
                                      updatesController.stream);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(ref));
    });
    test('Isolate', () {
      final IsolateRefElement e = new IsolateRefElement(obj,
                                      updatesController.stream);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.isolate, equals(obj));
    });
  });
  test('elements created after attachment', () async {
    final IsolateRefElement e = new IsolateRefElement(ref,
                                    updatesController.stream);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
  group('updates', () {
    test('are correctly listen', () async {
      final IsolateRefElement e = new IsolateRefElement(ref,
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
      final IsolateRefElement e = new IsolateRefElement(ref,
                                      updatesController.stream);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.innerHtml.contains(ref.id), isTrue);
      updatesController.add(new IsolateUpdateEventMock(isolate: obj));
      await e.onRendered.first;
      expect(e.innerHtml.contains(ref.name), isFalse);
      expect(e.innerHtml.contains(obj.name), isTrue);
      e.remove();
    });
  });
}
