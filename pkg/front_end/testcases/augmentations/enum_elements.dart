// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum1; // Error
augment enum Enum1; // Ok

enum Enum2 { // Ok
  a, // Ok
}
augment enum Enum2; // Ok

enum Enum3; // Ok
augment enum Enum3 { // Ok
  a, // Ok
}

enum Enum4 { // Ok
  a, // Ok
}
augment enum Enum4 { // Ok
  b, // Ok
}

enum Enum5 { // Ok
  a, // Error
}
augment enum Enum5 { // Ok
  a, // Error
}