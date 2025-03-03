// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests a compile time error that should not crash the analyzer or CFE.

// Formatting can break multitests, so don't format them.
// dart format off

import "dart:ffi";

final class C extends Struct {
  dynamic [cfe] unspecified x; 

  external Pointer notEmpty;
}

main() {}
