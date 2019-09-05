// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing that FFI callbacks report an appropriate
// runtime error for unsupported snapshot formats.

import 'dart:ffi';

import 'package:expect/expect.dart';

bool checkError(UnsupportedError err) {
  return "$err".contains("callbacks are not yet supported in blobs");
}

void main() {
  Expect.throws<UnsupportedError>(
      () => Pointer.fromFunction<Void Function()>(main), checkError);
}
