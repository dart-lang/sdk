// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

X bar<X>(Function(X) f) => throw 0;

foo(Function(Function(int, int, [int])) f, Function(Function(int, [int])) g) {
  var x = [f, g];
  var h = x.first;
  var u = bar(h);
  Function(int, [int, int]) v = u;
  return v;
}

main() {}
