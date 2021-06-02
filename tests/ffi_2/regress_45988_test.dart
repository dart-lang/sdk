// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

class DartValueFields extends Union {
  Pointer p1;
  Pointer p2;
  Pointer p3;
  Pointer p4;
}

void main() {
  final p = calloc<DartValueFields>();
  Expect.equals(0, p.ref.p4.address);
  calloc.free(p);
}
