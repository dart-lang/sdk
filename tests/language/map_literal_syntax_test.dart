// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  var x;
  var y;
  var z;
  var v;
  Foo() : x = {}, y = <int>{}, z = const {}, v = const <int>{};
}

main() {
  Expect.equals("{}", new Foo().x.toString());
  Expect.equals("{}", new Foo().y.toString());
  Expect.equals("{}", new Foo().z.toString());
  Expect.equals("{}", new Foo().v.toString());
}
