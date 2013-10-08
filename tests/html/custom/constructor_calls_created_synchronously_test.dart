// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library constructor_calls_created_synchronously_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import '../utils.dart';
import 'dart:mirrors';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);
  A.created() : super.created();

  static int ncallbacks = 0;

  void createdCallback() {
    ncallbacks++;
  }
}

main() {
  useHtmlConfiguration();

  // Adapted from Blink's
  // fast/dom/custom/constructor-calls-created-synchronously test.

  var registered = false;
  setUp(() {
    return loadPolyfills().then((_) {
      if (!registered) {
        registered = true;
        document.register(A.tag, A);
      }
    });
  });

  test('createdCallback', () {
    var x = new A();
    expect(A.ncallbacks, 1);
  });

  test('clone node', () {
    A.ncallbacks = 0;

    var a = new A();
    expect(A.ncallbacks, 1);
    var b = a.clone(false);
    expect(A.ncallbacks, 2);
    expect(b is A, isTrue);
  });
}
