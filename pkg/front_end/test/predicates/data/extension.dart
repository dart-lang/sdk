// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on int {
  int /*extensionThis*/ instanceMethod() => this;

  int get /*extensionThis*/ instanceGetter => this;

  void set /*extensionThis*/ instanceSetter(int value) {}

  static int staticMethod() => 42;

  static int get staticGetter => 42;

  static void set staticSetter(int value) {}
}
