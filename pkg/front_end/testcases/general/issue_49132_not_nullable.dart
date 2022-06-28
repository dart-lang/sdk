// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  dynamic x;

  Foo.foo1(dynamic a) : x = a is int ? {} : [] {
    // body.
  }

  Foo.foo2(dynamic a) : x = a is int ? {"a": "b"} : ["a", "b"] {
    // body.
  }

  Foo.foo3(dynamic a) : x = a as bool ? {} : [] {
    // body.
  }

  Foo.foo4(dynamic a) : x = a as bool ? {"a": "b"} : ["a", "b"] {
    // body.
  }
}
