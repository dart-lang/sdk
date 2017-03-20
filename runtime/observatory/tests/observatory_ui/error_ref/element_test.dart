// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/error_ref.dart';
import '../mocks.dart';

main() {
  ErrorRefElement.tag.ensureRegistration();

  final ref = new ErrorRefMock(id: 'id', message: 'fixed-error-m');
  test('instantiation', () {
    final ErrorRefElement e = new ErrorRefElement(ref);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.error, equals(ref));
  });
  test('elements created after attachment', () async {
    final ErrorRefElement e = new ErrorRefElement(ref);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.innerHtml.contains(ref.message), isTrue,
      reason: 'no message in the component');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero,
      reason: 'is empty');
  });
}
