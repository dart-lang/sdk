// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that late constant folding passes don't violate
// representation requirements for uses of a definition that is being
// folded away.

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

class X {
  int field;
  X(this.field);
}

@pragma('vm:never-inline')
int loadFrom(Pointer<Int32> p) {
  final x = X(0);
  x.field = 1;
  if ((x.field + 1) == 2) {
    x.field = 0;
  }

  // The code above tries to delay folding of x.field into a constant
  // until later passes. Inside p[...] there will be an unboxed Int64
  // arithmetic used to compute an index which will get constant folded
  // as soon as x.field is constant folded. CP should insert unboxed constant
  // or an unbox of a constant as a result of constant folding. If it does
  // not - then we will get an incorrect graph where a tagged value is flowing
  // into a LoadIndexed instruction without a deopt-id.
  return p[x.field];
}

void main() {
  final p = allocate<Int32>(count: 128);
  p[0] = 42;
  Expect.equals(42, loadFrom(p));
  free(p);
}
