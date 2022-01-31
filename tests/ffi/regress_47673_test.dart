// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

typedef T = Int64;

class A extends Struct {
  @Array.multi([16])
  external Array<T> b;
}

main() {}
