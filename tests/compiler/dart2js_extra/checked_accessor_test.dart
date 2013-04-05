// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class E {
  missingType field;
}

class WithGetter {
  String field;
}

void main() {
  f(x) {
    x.field = true;
  }
  Expect.throws(() {
    [new E(), new WithGetter()].forEach(f);
    new missingType();
    new E().field = 'a string';
  });
}
