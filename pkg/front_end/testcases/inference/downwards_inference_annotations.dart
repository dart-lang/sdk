// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class Foo {
  const Foo(List<String> l);
  const Foo.named(List<String> l);
}

@Foo(const [])
class Bar {}

@Foo.named(const [])
class Baz {}

main() {}
