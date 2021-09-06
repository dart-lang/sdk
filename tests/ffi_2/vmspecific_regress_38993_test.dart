// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests a compile time error that should not crash the analyzer or CFE.

// @dart = 2.9

import "dart:ffi";

class C extends Struct {
  dynamic x; //# 1: compile-time error

  Pointer notEmpty;
}

main() {}
