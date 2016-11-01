// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/inbound_references.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import '../mocks.dart';

main() {
  InboundReferencesElement.tag.ensureRegistration();

  final cTag = CurlyBlockElement.tag.name;
  final iTag = InstanceRefElement.tag.name;
  final rTag = InboundReferencesElement.tag.name;

  const isolate = const IsolateRefMock();
  const object = const InstanceRefMock();
  final inbounds = new InboundReferencesRepositoryMock();
  final instances = new InstanceRepositoryMock();
  test('instantiation', () {
    final e = new InboundReferencesElement(isolate, object, inbounds,
                                           instances);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.object, equals(object));
  });
  test('elements created after attachment', () async {
    const source = const InstanceRefMock(id: 'source-id', name: 'source_name');
    const references = const InboundReferencesMock(elements: const [
      const InboundReferenceMock(source: source)
    ]);
    bool invoked = false;
    final inbounds = new InboundReferencesRepositoryMock(
      getter: expectAsync((i, id) async {
        expect(i, equals(isolate));
        expect(id, equals(object.id));
        invoked = true;
        return references;
      }, count: 1)
    );
    final instances = new InstanceRepositoryMock();
    final e = new InboundReferencesElement(isolate, object, inbounds,
                                           instances);
    document.body.append(e);
    await e.onRendered.first;
    expect(invoked, isFalse);
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll(iTag).length, isZero);
    (e.querySelector(cTag) as CurlyBlockElement).toggle();
    await e.onRendered.first;
    expect(invoked, isTrue);
    expect(e.querySelectorAll(iTag).length, equals(1));
    expect(e.querySelectorAll(rTag).length, equals(1));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
