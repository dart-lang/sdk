// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/retaining_path.dart';
import '../mocks.dart';

main() {
  RetainingPathElement.tag.ensureRegistration();

  final cTag = CurlyBlockElement.tag.name;
  final iTag = InstanceRefElement.tag.name;

  const isolate = const IsolateRefMock();
  const object = const InstanceRefMock();
  final paths = new RetainingPathRepositoryMock();
  final objects = new ObjectRepositoryMock();
  test('instantiation', () {
    final e = new RetainingPathElement(isolate, object, paths, objects);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.object, equals(object));
  });
  test('elements created after attachment', () async {
    const source = const InstanceRefMock(id: 'source-id', name: 'source_name');
    const path = const RetainingPathMock(
        elements: const [const RetainingPathItemMock(source: source)]);
    bool invoked = false;
    final paths = new RetainingPathRepositoryMock(
        getter: expectAsync((i, id) async {
      expect(i, equals(isolate));
      expect(id, equals(object.id));
      invoked = true;
      return path;
    }, count: 1));
    final objects = new ObjectRepositoryMock();
    final e = new RetainingPathElement(isolate, object, paths, objects);
    document.body.append(e);
    await e.onRendered.first;
    expect(invoked, isFalse);
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll(iTag).length, isZero);
    (e.querySelector(cTag) as CurlyBlockElement).toggle();
    await e.onRendered.first;
    expect(invoked, isTrue);
    expect(e.querySelectorAll(iTag).length, equals(1));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
