// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void topLevelMethod<T extends S, S extends T>() {} // Error

class Class {
  void instanceMethod<T extends S, S extends T>() {} // Error
  static void staticMethod<T extends S, S extends T>() {} // Error
}

extension Extension on int {
  void instanceMethod<T extends S, S extends T>() {} // Error
  static void staticMethod<T extends S, S extends T>() {} // Error
}

extension type ExtensionType(int i) {
  void instanceMethod<T extends S, S extends T>() {} // Error
  static void staticMethod<T extends S, S extends T>() {} // Error
}
