// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('scrollXY', () {
    expect(window.scrollX, 0);
    expect(window.scrollY, 0);
  });
  test('open', () {
    final valid = window.open('', 'blank');
    valid.closed;
    // A blank page with no access to the original window (noopener) should
    // result in null.
    final invalid = window.open('', 'invalid', 'noopener=true');
    try {
      // Should result in an exception since the underlying window is null.
      invalid.closed;
      fail('Expected invalid.closed to throw.');
    } on NullWindowException {}
  });
}
