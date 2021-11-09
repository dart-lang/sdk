// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that extension member annotations can access other extension static
// members from the same extension by simple name.

extension E on int {
  @constField
  static const int constField = 1;

  @constField2
  static const int constField1 = 2;

  @constField1
  static const int constField2 = 3;

  @constField
  static void staticMethod() {}

  @constField
  void instanceMethod() {}
}

main() {}
