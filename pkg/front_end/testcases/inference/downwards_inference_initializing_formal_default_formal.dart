// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef T Function2<S, T>([S x]);

class Foo {
  List<int> x;
  Foo([this.x = const [1]]);
  Foo.named([List<int> x = const [1]]) : this.x = x;
}

void f([List<int> l = const [1]]) {}
// We do this inference in an early task but don't preserve the infos.
Function2<List<int>, String> g = ([llll = const [1]]) => "hello";

main() {}
