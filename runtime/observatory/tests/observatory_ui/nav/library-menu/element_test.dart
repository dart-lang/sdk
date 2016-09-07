// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/library_menu.dart';
import '../../mocks.dart';

main() {
  NavLibraryMenuElement.tag.ensureRegistration();

  final i_ref = const IsolateRefMock(id: 'i-id', name: 'i-name');
  final l_ref = const LibraryRefMock(id: 'l-id', name: 'l-name');
  test('instantiation', () {
    final e = new NavLibraryMenuElement(i_ref, l_ref);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(i_ref));
    expect(e.library, equals(l_ref));
  });
  test('elements created after attachment', () async {
    final e = new NavLibraryMenuElement(i_ref, l_ref);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
