// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library WindowManglingTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html' as dom;

// Defined in dom.Window.
get navigator => "Dummy";

$eq(x, y) => false;
$eq$(x, y) => false;

main() {
  useHtmlConfiguration();
  var win = dom.window;

  test('windowMethod', () {
    final message = navigator;
    final x = win.navigator;
    expect(x, isNot(equals(message)));
  });

  test('windowEquals', () {
    expect($eq(win, win), isFalse);
    expect(win == win, isTrue);
  });

  test('windowEquals', () {
    expect($eq$(win, win), isFalse);
    expect(win == win, isTrue);
  });
}
