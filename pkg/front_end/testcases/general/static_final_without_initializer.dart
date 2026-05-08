// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final v1; // Error
final int v2; // Error

class Class {
  static final v3; // Error
  static final int v4; // Error
}

extension Extension on Class {
  static final v5; // Error
  static final int v6; // Error
}

extension type ExtensionType(Class c) {
  static final v7; // Error
  static final int v8; // Error
}

mixin Mixin {
  static final v9; // Error
  static final int v10; // Error
}

enum Enum {
  a;

  static final v11; // Error
  static final int v12; // Error
}
