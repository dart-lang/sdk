// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';

main() {
  NavTopMenuElement.tag.ensureRegistration();

  test('instantiation', () {
    final e = new NavTopMenuElement();
    expect(e, isNotNull, reason: 'element correctly created');
  });
  group('elements', () {
    test('created', () async {
      final e = new NavTopMenuElement();
      e.content = [document.createElement('content')];
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelector('content'), isNotNull,
                                                 reason: 'has content elements');
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
}
