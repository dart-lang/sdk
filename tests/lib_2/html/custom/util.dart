// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.html.util;

import 'dart:html';

import 'package:unittest/unittest.dart';

void expectUnsupported(f) => expect(f, throwsUnsupportedError);

void expectEmptyRect(ClientRect rect) {
  expect(rect.bottom, isZero);
  expect(rect.top, isZero);
  expect(rect.left, isZero);
  expect(rect.right, isZero);
  expect(rect.height, isZero);
  expect(rect.width, isZero);
}
