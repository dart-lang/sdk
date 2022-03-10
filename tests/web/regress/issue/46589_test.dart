// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

typedef MyVoid = void;

bool isVoid<X>() {
  return X == MyVoid;
}

void main() {
  Expect.isFalse(isVoid<int>());
  Expect.isTrue(isVoid<void>());
}
