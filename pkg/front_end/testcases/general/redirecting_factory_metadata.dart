// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that annotations on redirecting factories and their formals
// aren't skipped by the compiler and are observable in its output.

const forParameter = 1;
const forFactoryItself = 2;
const anotherForParameter = 3;

class Foo {
  @forFactoryItself
  factory Foo(@forParameter @anotherForParameter p) = Foo.named;
  Foo.named(p);
}

main() {}
