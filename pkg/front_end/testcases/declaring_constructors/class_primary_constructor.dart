// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1() {}

class const C2() {}

class C3() {
  final int? i; // Error
}

class const C4() { // Error
  int? i;
}
