// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

class Mock {
  noSuchMethod(Invocation i) => document;
}

@proxy
class MockWindow extends Mock implements Window {}

main() {
  test('is', () {
    var win = new MockWindow();
    expect(win is Window, isTrue);
  });

  test('getter', () {
    var win = new MockWindow();
    expect(win.document, equals(document));
  });
}
