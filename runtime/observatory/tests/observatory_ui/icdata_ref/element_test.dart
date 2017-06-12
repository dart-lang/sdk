// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import '../mocks.dart';

main() {
  InstanceRefElement.tag.ensureRegistration();

  const isolate = const IsolateRefMock();
  const instance = const InstanceRefMock();
  final objects = new ObjectRepositoryMock();
  test('instantiation', () {
    final e = new InstanceRefElement(isolate, instance, objects);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.instance, equals(instance));
  });
  test('elements created after attachment', () async {
    final e = new InstanceRefElement(isolate, instance, objects);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
