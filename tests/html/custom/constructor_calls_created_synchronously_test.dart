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
  A.created() : super.created() {
    ncallbacks++;
  }

  static int ncallbacks = 0;
}

main() {
  useHtmlConfiguration();

  // Adapted from Blink's
  // fast/dom/custom/constructor-calls-created-synchronously test.

  var registered = false;
  setUp(() {
    return customElementsReady.then((_) {
      if (!registered) {
        registered = true;
        document.registerElement(A.tag, A);
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

  test("can extend elements that don't have special prototypes", () {
    document.registerElement('fancy-section', FancySection,
        extendsTag: 'section');
    var fancy = document.createElement('section', 'fancy-section');
    expect(fancy is FancySection, true, reason: 'fancy-section was registered');
    expect(fancy.wasCreated, true, reason: 'FancySection ctor was called');
  });
}

class FancySection extends HtmlElement {
  bool wasCreated = false;
  FancySection.created() : super.created() {
    wasCreated = true;
  }
}
