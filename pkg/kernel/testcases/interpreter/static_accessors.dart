// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

main(arguments) {
  test1(f1);
  test2(f2);

  if (37 != v1) throw "Unexpected value: v1 = $v1, expected value: 37";
  v1 = 42;
  if (42 != v1) throw "Unexpected value: v1 = $v1, expected value: 42";
  if (v2 != null) throw "Unexpected value: v2 = $v2, expected value: null";
  v2 = 42;
  if (42 != v2) throw "Unexpected value: v2 = $v2, expected value: 42";
  setter = 37;
  if (37 != v1) throw "Unexpected value: v1 = $v1, expected value: 37";
  if (37 != getter)
    throw "Unexpected getter value: v1 = ${getter}, expected value: 37";
}

f1(a, [b = 10]) => a + b;
f2(a, {b = 10}) => a + b;

var v1 = 37;
var v2;

int get getter => v1;

void set setter(int v) {
  v1 = v;
}

test1(Function f) {
  var result = f(40, 2);
  if (42 != result) throw "Unexpected result: $result";
}

test2(Function f) {
  var result = f(40, b: 2);
  if (42 != result) throw "Unexpected result: $result";
}
