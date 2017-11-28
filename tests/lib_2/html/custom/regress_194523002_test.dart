// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for CL 194523002.

library js_custom_test;

import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';
import 'dart:html';
import '../utils.dart';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);
  A.created() : super.created();
}

main() {
  useHtmlIndividualConfiguration();

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
}
