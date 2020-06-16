// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'static_extension_constant_lib.dart' hide b, i, d, s;
import 'static_extension_constant_lib.dart' as lib show b, i, d, s;

// Ensure that all expressions in runtimeExtensionCalls invoke
// an extension method rather than an instance method, such that
// static_extension_constant_error_test gets an error for them all.

const dynamic b = lib.b;
const dynamic i = lib.i;
const dynamic d = lib.d;
const dynamic s = lib.s;

// These expressions should be identical to those in
// `lib.runtimeExtensionCalls`.
var dynamicInstanceCalls = <Object>[
  ~i,
  b & b,
  b | b,
  b ^ b,
  i ~/ i,
  i >> i,
  // i >>> i, // Requries triple-shift.
  i << i,
  i + i,
  -i,
  d - d,
  d * d,
  d / d,
  d % d,
  d < i,
  i <= d,
  d > i,
  i >= i,
  s.length,
];

void main() {
  for (int i = 0; i < dynamicInstanceCalls.length; ++i) {
    Expect.notEquals(dynamicInstanceCalls[i], runtimeExtensionCalls[i]);
  }
}
