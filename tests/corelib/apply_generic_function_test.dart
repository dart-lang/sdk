// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "symbol_map_helper.dart";

// Testing Function.apply calls correctly with generic type arguments.
// This test is not testing error handling, only that correct parameters
// cause a correct call.

test0<T extends num>(T i, T j, {required T a}) => i + j + a;

main() {
  test(res, func, list, map) {
    map = symbolToStringMap(map);
    Expect.equals(res, Function.apply(func, list, map));
  }

  test(42, test0, [10, 15], {"a": 17});
}
