// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.html.util;

import 'dart:html';
import 'package:expect/minitest.dart';

void expectEmptyRect(Rectangle rect) {
  expect(rect.bottom, 0);
  expect(rect.top, 0);
  expect(rect.left, 0);
  expect(rect.right, 0);
  expect(rect.height, 0);
  expect(rect.width, 0);
}
