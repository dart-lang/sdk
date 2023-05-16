// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that you can't use 'dart:ffi' with a JS interop library.

import 'dart:ffi';
// The following imports have empty comments so that the formatting works for
// static error tests.
/**/ import 'dart:js';
//   ^
// [web] The same library can not use both JS interop library 'dart:js' and 'dart:ffi'.
/**/ import 'dart:js_interop';
//   ^
// [web] The same library can not use both JS interop library 'dart:js_interop' and 'dart:ffi'.
/**/ import 'dart:js_interop_unsafe';
//   ^
// [web] The same library can not use both JS interop library 'dart:js_interop_unsafe' and 'dart:ffi'.
/**/ import 'dart:js_util';
//   ^
// [web] The same library can not use both JS interop library 'dart:js_util' and 'dart:ffi'.
/**/ import 'package:js/js.dart' as pkgJs;
//   ^
// [web] The same library can not use both JS interop library 'package:js/js.dart' and 'dart:ffi'.
/**/ import 'package:js/js_util.dart';
//   ^
// [web] The same library can not use both JS interop library 'package:js/js_util.dart' and 'dart:ffi'.

void main() {}
