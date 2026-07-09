// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  int? test({int? a = 123}) {
    return a;
  }
}

void main() {
  dynamic x = A();
  Expect.equals(null, x.test(a: null));
  Expect.equals(123, x.test());
  Expect.equals(456, x.test(a: 456));
}
