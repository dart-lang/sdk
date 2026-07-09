// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  // Not OK.
  void Foo() {}
  // Not OK.
  void Foo() : initializer = true {}
  // Not OK.
  void Foo.x() {}
  // Not OK.
  void Foo.x() : initializer = true {}
}
