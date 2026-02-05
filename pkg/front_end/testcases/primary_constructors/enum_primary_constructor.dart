// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1() {
  a
}

enum const E2() {
  a
}

enum const E3() {
  a;
  final int? b; // Error
}

enum const E4() { // Error
  a;
  int? b;
}
