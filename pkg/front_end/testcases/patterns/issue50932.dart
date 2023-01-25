// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './issue50932.dart' as self;

abstract class A {
  int get foo;
}

test(dynamic x) {
  if (x case self.A(foo: 0)) {
    return 0;
  } else {
    return 1;
  }
}
