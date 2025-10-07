// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

var h = null;
void foo(int? f(Object _)) {}

test() {
  var f = (Object x) {
    return null;
  };
  String? y = f(42);

  // error:INVALID_CAST_FUNCTION_EXPR
  f = (x) => 'hello';

  foo((x) {
    return null;
  });
  foo((x) {
    throw "not implemented";
  });
}

main() {}
