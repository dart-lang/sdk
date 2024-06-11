// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that importing `dart:ffi` and using `wasm:import` and export pragmas
// are not allowed.

import 'dart:ffi'; //# 01: compile-time error

@pragma('wasm:export', 'f') //# 02: compile-time error
void f() {}

@pragma('wasm:import', 'g') //# 03: compile-time error
external double g(double x);

void main() {}
