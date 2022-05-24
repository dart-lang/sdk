// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on int {
  int get instanceProperty => 42;
  void set instanceProperty(int value) {}
  void instanceMethod() {}

  static int staticField = 42;
  static final int staticFinalField = 42;
  static const int staticConstField = 42;
  static int get staticProperty => 42;
  static void set staticProperty(int value) {}
  static void staticMethod() {}
}
