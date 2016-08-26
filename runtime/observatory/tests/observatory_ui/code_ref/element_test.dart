// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/code_ref.dart';
import '../mocks.dart';

main() {
  CodeRefElement.tag.ensureRegistration();

  final isolate = new IsolateRefMock(id: 'i-id', name: 'i-name');
  final code = new CodeRefMock(id: 'c-id', name: 'c-name');
  test('instantiation', () {
    final e = new CodeRefElement(isolate, code);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.code, equals(code));
  });
  test('elements created after attachment', () async {
    final e = new CodeRefElement(isolate, code);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
