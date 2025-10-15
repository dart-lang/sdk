// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that dart2wasm disallows these interop libraries from being imported.

import 'dart:js';
//     ^
// [web] Dart library 'dart:js' is not available on this platform.

import 'dart:js_util';
//     ^
// [web] Dart library 'dart:js_util' is not available on this platform.

import 'dart:ffi';
// [error column 1]
// [web] 'dart:ffi' can't be imported when compiling to Wasm.

void main() {}
