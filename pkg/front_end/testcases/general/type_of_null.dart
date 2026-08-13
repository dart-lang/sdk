// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T map<T>(T Function() f1, T Function() f2) => throw '';

id<T>(T t) => t;

Null foo() => null;

test() {
  map(() {}, () => throw "hello");
  map(() => throw "hello", () {});
  Null Function() f = () {};
  map(foo, () => throw "hello");
  map(() => throw "hello", foo);
  map(() {
    return null;
  }, () => throw "hello");

  map(() => throw "hello", () {
    return null;
  });
  id(() {});
}

main() {}
