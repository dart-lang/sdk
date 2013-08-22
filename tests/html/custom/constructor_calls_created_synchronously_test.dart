// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library constructor_calls_created_synchronously_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);

  static int ncallbacks = 0;

  void onCreated() {
    ncallbacks++;
  }
}

main() {
  useHtmlConfiguration();

  // Adapted from Blink's
  // fast/dom/custom/constructor-calls-created-synchronously test.

  test('createdCallback', () {
    document.register(A.tag, A);
    var x = new A();
    expect(A.ncallbacks, 1);
  });
}
