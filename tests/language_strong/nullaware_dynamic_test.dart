// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  dynamic l;
  var val = l?.first?.abs();
  Expect.equals(null, val);
  l = [null, -2, -3];
  val = l?.first?.abs();
  Expect.equals(null, val);
  l = [-1, -2, -3];
  val = l?.first?.abs();
  Expect.equals(1, val);
}
