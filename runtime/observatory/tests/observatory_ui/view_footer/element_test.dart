// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/view_footer.dart';

main() {
  ViewFooterElement.tag.ensureRegistration();

  test('instantiation', () {
    final e = new ViewFooterElement();
    expect(e, isNotNull, reason: 'element correctly created');
  });
  test('elements created', () async {
    final e = new ViewFooterElement();
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
