// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<X> {
  C(void Function(X) x);
}

T check<T>(C<List<T>> f) {
  return null as T;
}

void test() {
  var x = check(C((List<int> x) {})); // Should infer `int` for `T`
  String s = x; // Should be an error, `T` should be int.
}

main() {}
