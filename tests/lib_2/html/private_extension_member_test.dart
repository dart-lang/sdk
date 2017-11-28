// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'dart:html';

main() {
  // Regression test for: https://github.com/dart-lang/dev_compiler/issues/508.
  // "dart:html" defines some private members on native DOM types and we need
  // to ensure those can be accessed correctly.
  //
  // The createFragment() method sets `_innerHtml` on the element, so we use it
  // as a test case.
  Expect.equals("[object DocumentFragment]",
      new BRElement().createFragment("Hi").toString());
}
