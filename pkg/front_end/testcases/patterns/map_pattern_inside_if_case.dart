// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class MyMap implements Map<String, int> {}

test1(dynamic x) {
  if (x case {'a': 1, 'b': 2}) {}
}

test2(dynamic x) {
  if (x case {1: 2, "foo": "bar"}) {
    return 0;
  } else {
    return 1;
  }
}

test3(Map<bool, double> x) {
  if (x case {true: 3.14}) {}
  if (x case {false: 2.71}) {}
}

test4(MyMap x) {
  if (x case {"one": 1, "two": 2}) {}
}

test5(dynamic x) {
  if (x case {"one": var y1, "two": String y2!}) {
    return 0;
  } else {
    return 1;
  }
}
