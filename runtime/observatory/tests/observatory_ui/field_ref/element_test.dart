// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/field_ref.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import '../mocks.dart';

main() {
  FieldRefElement.tag.ensureRegistration();

  final iTag = InstanceRefElement.tag.name;

  const isolate = const IsolateRefMock();
  const field = const FieldRefMock();
  const declaredType =
      const InstanceMock(kind: M.InstanceKind.type, name: 'CustomObject');
  const field_non_dynamic = const FieldRefMock(declaredType: declaredType);
  final objects = new ObjectRepositoryMock();
  test('instantiation', () {
    final e = new FieldRefElement(isolate, field, objects);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.field, equals(field));
  });
  group('elements', () {
    test('created after attachment (dynamic)', () async {
      final e = new FieldRefElement(isolate, field, objects);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(iTag).length, isZero);
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('created after attachment (non dynamic)', () async {
      final e = new FieldRefElement(isolate, field_non_dynamic, objects);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(iTag).length, equals(1));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
}
