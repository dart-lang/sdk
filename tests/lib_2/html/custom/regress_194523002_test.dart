// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for CL 194523002.
import 'dart:html';

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);
  A.created() : super.created();
}

main() async {
  // Adapted from Blink's
  // fast/dom/custom/constructor-calls-created-synchronously test.

  await customElementsReady;
  document.registerElement2(A.tag, {'prototype': A});
}
