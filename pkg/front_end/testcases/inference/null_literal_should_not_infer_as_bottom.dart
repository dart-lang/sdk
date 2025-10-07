// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

var h = null;
void foo(int f(Object _)) {}

test() {
  var f = (Object x) => null;
  String? y = f(42);

  f = (x) => 'hello';

  var g = null;
  g = 'hello';
  ( /*info:DYNAMIC_INVOKE*/ g.foo());

  h = 'hello';
  ( /*info:DYNAMIC_INVOKE*/ h.foo());

  foo((x) => 0);
  foo((x) => throw "not implemented");
}

main() {}
