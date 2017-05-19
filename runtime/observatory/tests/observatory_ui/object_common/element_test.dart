// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/inbound_references.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/retaining_path.dart';
import '../mocks.dart';

main() {
  ObjectCommonElement.tag.ensureRegistration();

  final cTag = ClassRefElement.tag.name;
  final iTag = InboundReferencesElement.tag.name;
  final rTag = RetainingPathElement.tag.name;

  const isolate = const IsolateRefMock();
  const object = const InstanceMock();
  final reachableSizes = new ReachableSizeRepositoryMock();
  final retainedSizes = new RetainedSizeRepositoryMock();
  final inbounds = new InboundReferencesRepositoryMock();
  final paths = new RetainingPathRepositoryMock();
  final objects = new ObjectRepositoryMock();
  test('instantiation', () {
    final e = new ObjectCommonElement(isolate, object, retainedSizes,
        reachableSizes, inbounds, paths, objects);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.object, equals(object));
  });
  group('elements', () {
    test('created after attachment', () async {
      final e = new ObjectCommonElement(isolate, object, retainedSizes,
          reachableSizes, inbounds, paths, objects);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(cTag).length, equals(1));
      expect(e.querySelectorAll(iTag).length, equals(1));
      expect(e.querySelectorAll(rTag).length, equals(1));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('created after attachment', () async {
      const value = const GuardedMock<InstanceMock>.fromValue(
          const InstanceMock(valueAsString: '10'));
      bool invoked = false;
      final reachableSizes = new ReachableSizeRepositoryMock(
          getter: expectAsync((i, id) async {
        expect(i, equals(isolate));
        expect(id, equals(object.id));
        invoked = true;
        return value;
      }, count: 1));
      final e = new ObjectCommonElement(isolate, object, retainedSizes,
          reachableSizes, inbounds, paths, objects);
      document.body.append(e);
      await e.onRendered.first;
      expect(invoked, isFalse);
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(cTag).length, equals(1));
      expect(e.querySelectorAll(iTag).length, equals(1));
      expect(e.querySelectorAll(rTag).length, equals(1));
      e.querySelector('.reachable_size').click();
      await e.onRendered.first;
      expect(invoked, isTrue);
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('created after attachment', () async {
      const value = const GuardedMock<InstanceMock>.fromValue(
          const InstanceMock(valueAsString: '10'));
      bool invoked = false;
      final retainedSizes = new RetainedSizeRepositoryMock(
          getter: expectAsync((i, id) async {
        expect(i, equals(isolate));
        expect(id, equals(object.id));
        invoked = true;
        return value;
      }, count: 1));
      final e = new ObjectCommonElement(isolate, object, retainedSizes,
          reachableSizes, inbounds, paths, objects);
      document.body.append(e);
      await e.onRendered.first;
      expect(invoked, isFalse);
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(cTag).length, equals(1));
      expect(e.querySelectorAll(iTag).length, equals(1));
      expect(e.querySelectorAll(rTag).length, equals(1));
      e.querySelector('.retained_size').click();
      await e.onRendered.first;
      expect(invoked, isTrue);
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
}
