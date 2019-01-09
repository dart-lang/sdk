// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

FutureOr<dynamic> x = 'abc';
dynamic y = 'abc';

void smi() {
  x = 42;
  y = 42;
}

void mint() {
  x = 0x7fffffff00000000;
  y = 0x7fffffff00000000;
}

void dbl() {
  x = 1.0;
  y = 1.0;
}

void main() {
  smi();
  Expect.isTrue(identical(x, y));
  mint();
  Expect.isTrue(identical(x, y));
  dbl();
  Expect.isTrue(identical(x, y));
}
