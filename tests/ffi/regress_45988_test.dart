// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

class DartValueFields extends Union {
  external Pointer p1;
  external Pointer p2;
  external Pointer p3;
  external Pointer p4;
}

void main() {
  final p = calloc<DartValueFields>();
  Expect.equals(0, p.ref.p4.address);
  calloc.free(p);
}
