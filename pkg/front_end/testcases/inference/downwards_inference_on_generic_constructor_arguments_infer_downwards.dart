// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class F0<T> {
  F0(List<T> a) {}
}

class F1<T> {
  F1({required List<T> a}) {}
}

class F2<T> {
  F2(Iterable<T> a) {}
}

class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}

class F4<T> {
  F4({required Iterable<Iterable<T>> a}) {}
}

void test() {
  new F0<int>([]);
  new F0<int>([3]);
  new F0<int>([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F0<int>([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  new F1<int>(a: []);
  new F1<int>(a: [3]);
  new F1<int>(a: [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F1<int>(a: [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  new F2<int>([]);
  new F2<int>([3]);
  new F2<int>([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F2<int>([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  new F3<int>([]);
  new F3<int>([
    [3],
  ]);
  new F3<int>([
    [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
  ]);
  new F3<int>([
    [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    [3],
  ]);

  new F4<int>(a: []);
  new F4<int>(
    a: [
      [3],
    ],
  );
  new F4<int>(
    a: [
      [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    ],
  );
  new F4<int>(
    a: [
      [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
      [3],
    ],
  );

  new F3([]);
  var f31 = new F3([
    [3],
  ]);
  var f32 = new F3([
    ["hello"],
  ]);
  var f33 = new F3([
    ["hello"],
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
      ["hello"],
    ],
  );
  new F4(
    a: [
      ["hello"],
      [3],
    ],
  );
}

main() {}
