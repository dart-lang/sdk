// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library c;

import 'b.dart';

void bar() {
  f3(f4(3));
  f1(f4);
  f2(f3);
}
