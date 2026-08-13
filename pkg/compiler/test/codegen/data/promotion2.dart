// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Examples where null checks should be removed.

/*member: test1:function(a) {
  var b, b0, i;
  for (b = a != null, b0 = false, i = 0; ++i, i < 3; b0 = b)
    if (b0)
      B.JSArray_methods.get$first(a);
}*/
void test1(List<Object>? a) {
  bool b = false;
  int i = 0;
  // The null check is guarded by `b = false;` in the initial iteration.
  while (++i < 3) {
    if (b) sink = a!.first;
    b = a != null;
  }
}

Object? sink;

/*member: main:ignore*/
main() {
  test1(null);
  test1([1, 2]);
  test1(['x']);
}
