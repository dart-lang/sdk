// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// Tests that class members are listed in the normal order.

class Foo {
  a() {}
  b() {}
  c() {}
  var field1;
  var field2;
  var field3;
  Foo.constructor1();
  Foo.constructor2();
  Foo.constructor3();
}
