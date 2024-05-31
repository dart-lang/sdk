// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that dart2wasm disallows these interop libraries from being imported.

/**/ import 'dart:js';
//   ^
// [web] JS interop library 'dart:js' can't be imported when compiling to Wasm.

/**/ import 'dart:js_util';
//   ^
// [web] JS interop library 'dart:js_util' can't be imported when compiling to Wasm.

/**/ import 'package:js/js.dart';
//   ^
// [web] JS interop library 'package:js/js.dart' can't be imported when compiling to Wasm.

/**/ import 'package:js/js_util.dart';
//   ^
// [web] JS interop library 'package:js/js_util.dart' can't be imported when compiling to Wasm.

/**/ import 'dart:ffi';
//   ^
// [web] 'dart:ffi' can't be imported when compiling to Wasm.

void main() {}
