// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void f0(List<int> a) {}
void f1({required List<int> a}) {}
void f2(Iterable<int> a) {}
void f3(Iterable<Iterable<int>> a) {}
void f4({required Iterable<Iterable<int>> a}) {}
void test() {
  f0([]);
  f0([3]);
  f0([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  f0([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  f1(a: []);
  f1(a: [3]);
  f1(a: [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  f1(a: [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  f2([]);
  f2([3]);
  f2([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  f2([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  f3([]);
  f3([
    [3],
  ]);
  f3([
    [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
  ]);
  f3([
    [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    [3],
  ]);

  f4(a: []);
  f4(
    a: [
      [3],
    ],
  );
  f4(
    a: [
      [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    ],
  );
  f4(
    a: [
      [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
      [3],
    ],
  );
}

main() {}
