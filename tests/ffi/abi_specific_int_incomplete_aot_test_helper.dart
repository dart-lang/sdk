// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Helper for abi_specific_int_incomplete_aot_test.dart.
// This file has an AbiSpecificInteger with an incomplete mapping.
// During AOT compilation for any ABI other than fuchsiaArm64, gen_snapshot
// should fail with an error about the missing mapping.

import 'dart:ffi';

// We want at least 1 mapping to satisfy the static checks.
const notTestingOn = Abi.fuchsiaArm64;

@AbiSpecificIntegerMapping({notTestingOn: Int8()})
final class Incomplete extends AbiSpecificInteger {
  const Incomplete();
}

void main() {
  // Any use that causes the class to be used, causes a compile-time error
  // during loading of the class.
  nullptr.cast<Incomplete>();
}
