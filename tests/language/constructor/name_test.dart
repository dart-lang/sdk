// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  Bar.Foo(); //# 01: compile-time error
  factory Bar(); //# 02: syntax error
  factory Bar.Baz(); //# 03: syntax error
}

void main() {
  new Foo();
  new Foo.Foo(); //# 01: continued
  new Foo.Baz(); //# 03: continued
}
