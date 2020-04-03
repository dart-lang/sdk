// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

int f({required int i}) => i + 1;

class C {
  m(int a, {required int i}) => a + i;
}

main() {
  Expect.equals(f(i: 2), 3);
  Expect.equals(C().m(4, i: 5), 9);
}
