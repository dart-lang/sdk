// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that duplicate initialization of a final field is a runtime error.


class Class {
  final f = 10;

  Class(v) : f = v;  /// 01: runtime error, static type warning

  Class(this.f);  /// 02: runtime error, static type warning

  // If a field is initialized multiple times in the initializer
  // list, it's a compile time error.
  Class(this.f) : f = 0;  /// 03: compile-time error
}

main() {
  new Class(5);  /// 01: continued
  new Class(5);  /// 02: continued
  new Class(5);  /// 03: continued
}
