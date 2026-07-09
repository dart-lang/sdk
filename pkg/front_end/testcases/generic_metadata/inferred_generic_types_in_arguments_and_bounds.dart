// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {}

A<Y> foo<Y>(Y y) => throw 42;

test() {
  var x = foo(<Z>(Z) => throw 42);
  var y = [foo];
  var z = {y.first};
}

main() {}
