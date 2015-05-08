// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:expect/expect.dart';

class Point {
  int x, y;
  Point(this.x, this.y);
}

void main() {
  var p_in = new Point(3, 4);
  var p_out = inspect(p_in);
  Expect.isTrue(identical(p_in, p_out));
}
