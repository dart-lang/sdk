// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  // Not OK.
  set Foo() {}
  // Not OK.
  set Foo() : initializer = true {}
  // Not OK.
  set Foo.x() {}
  // Not OK.
  set Foo.x() : initializer = true {}
}