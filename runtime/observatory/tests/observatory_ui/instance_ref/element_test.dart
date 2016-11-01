// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/icdata_ref.dart';
import '../mocks.dart';

main() {
  ICDataRefElement.tag.ensureRegistration();

  const isolate = const IsolateRefMock();
  const icdata = const ICDataRefMock();
  test('instantiation', () {
    final e = new ICDataRefElement(isolate, icdata);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.icdata, equals(icdata));
  });
  test('elements created after attachment', () async {
    final e = new ICDataRefElement(isolate, icdata);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
