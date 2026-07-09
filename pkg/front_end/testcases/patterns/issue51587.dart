// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1() {
  num b = 0;
  b as int;
  b.isEven;
  (b,) = (3.14,);
  return b;
}

test2() {
  num b = 0;
  b as int;
  b.isEven;
  (b, foo: _) = (3.14, foo: "foo");
  return b;
}

test3() {
  num b = 0;
  b as int;
  b.isEven;
  (foo: b) = (foo: 3.14);
  return b;
}
