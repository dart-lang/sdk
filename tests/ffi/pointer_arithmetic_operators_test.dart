// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

void main() {
  Pointer<Int32> p = calloc<Int32>(3);
  final p1 = p;
  p.value = 1;
  (p + 1).value = 2;
  (p + 2).value = 3;
  Expect.equals(1, p.value);
  p += 2;
  Expect.equals(3, p.value);
  p -= 1;
  Expect.equals(2, p.value);
  calloc.free(p1);
}
