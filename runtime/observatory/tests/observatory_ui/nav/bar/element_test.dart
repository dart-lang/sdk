// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/bar.dart';

main() {
  NavBarElement.tag.ensureRegistration();

  test('instantiation', () {
    final NavBarElement e = new NavBarElement();
    expect(e, isNotNull, reason: 'element correctly created');
  });
  test('elements created', () async {
    final NavBarElement e = new NavBarElement();
    document.body.append(e);
    await e.onRendered.first;
    expect(e.shadowRoot.children.length, isNonZero, reason: 'has elements');
    expect(e.shadowRoot.querySelector('content'), isNotNull,
                                               reason: 'has content elements');
    e.remove();
    await e.onRendered.first;
    expect(e.shadowRoot.children.length, isZero, reason: 'is empty');
  });
}
