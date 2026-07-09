// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int get foo => 0;
}

List<T> foo<T>(void Function(T) f) => throw 0;

test1() {
  var <A>[var x] = foo((a) => a.foo);
}

test2() {
  var [var x, ...y] = foo((e) => e);
}
