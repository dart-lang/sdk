// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.native_class_test;

import 'dart:html';

@MirrorsUsed(targets: 'dart.dom.html.Element')
import 'dart:mirrors';

import 'stringify.dart';

main() {
  expect('s(dart.dom.html.Element)', reflectClass(Element).qualifiedName);
  expect(
      's(dart.dom.html.Node)', reflectClass(Element).superclass.qualifiedName);
  window.postMessage('unittest-suite-success', '*');
}
