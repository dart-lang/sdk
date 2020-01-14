// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that metadata refer to the annotated declaration.

@Foo()
class Foo {
  const Foo();
}

main() {
  Foo f = const Foo();
}
