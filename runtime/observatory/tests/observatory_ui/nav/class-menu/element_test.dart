// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/class_menu.dart';
import '../../mocks.dart';

main() {
  NavClassMenuElement.tag.ensureRegistration();

  final i_ref = const IsolateRefMock(id: 'i-id', name: 'i-name');
  final c_ref = const ClassRefMock(id: 'c-id', name: 'c-name');
  test('instantiation', () {
    final e = new NavClassMenuElement(i_ref, c_ref);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(i_ref));
    expect(e.cls, equals(c_ref));
  });
  test('elements created after attachment', () async {
    final e = new NavClassMenuElement(i_ref, c_ref);
    e.content = [document.createElement('content')];
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
