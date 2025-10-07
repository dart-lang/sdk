// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class F0 {
  F0(List<int> a) {}
}

class F1 {
  F1({required List<int> a}) {}
}

class F2 {
  F2(Iterable<int> a) {}
}

class F3 {
  F3(Iterable<Iterable<int>> a) {}
}

class F4 {
  F4({required Iterable<Iterable<int>> a}) {}
}

void test() {
  new F0([]);
  new F0([3]);
  new F0([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F0([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  new F1(a: []);
  new F1(a: [3]);
  new F1(a: [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F1(a: [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  new F2([]);
  new F2([3]);
  new F2([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F2([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  new F3([]);
  new F3([
    [3],
  ]);
  new F3([
    [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
  ]);
  new F3([
    [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    [3],
  ]);

  new F4(a: []);
  new F4(
    a: [
      [3],
    ],
  );
  new F4(
    a: [
      [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    ],
  );
  new F4(
    a: [
      [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
      [3],
    ],
  );
}

main() {}
