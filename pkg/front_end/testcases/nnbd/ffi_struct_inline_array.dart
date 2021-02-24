// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import "package:ffi/ffi.dart";

class StructInlineArray extends Struct {
  @Array(8)
  external Array<Uint8> a0;
}

main() {}
