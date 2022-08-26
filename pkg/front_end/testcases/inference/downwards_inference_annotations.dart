// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Foo {
  const Foo(List<String> l);
  const Foo.named(List<String> l);
}

@Foo(/*@typeArgs=String*/ const [])
class Bar {}

@Foo.named(/*@typeArgs=String*/ const [])
class Baz {}

main() {}
