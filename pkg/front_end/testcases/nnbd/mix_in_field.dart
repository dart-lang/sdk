// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

class Mixin {
  FutureOr<Null> m;
}

class Class extends Object with Mixin {
  test(dynamic t1) {
    m = t1;
  }
}

main() {}
