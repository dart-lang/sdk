// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/unsorted/external_test.dart

class Foo {
  var x = -1;
  Foo() : x = 0; // OK
  external Foo.n24(this.x); // Error
}

