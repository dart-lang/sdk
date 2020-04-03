// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd

import 'dart:_runtime' as dart;

import 'package:expect/expect.dart';

import 'runtime_utils_nnbd.dart';

class A {}

void main() {
  // A?? == A?
  Expect.identical(nullable(nullable(A)), nullable(A));
  // A?* == A?
  Expect.identical(legacy(nullable(A)), nullable(A));
  // A*? == A?
  Expect.identical(nullable(legacy(A)), nullable(A));
  // A** == A*
  Expect.identical(legacy(legacy(A)), legacy(A));
  // Null? == Null
  Expect.identical(nullable(Null), Null);
  // Never? == Null
  Expect.identical(nullable(Never), Null);
  // dynamic? == dynamic
  Expect.identical(nullable(dynamic), dynamic);
  // void? == void
  Expect.identical(
      nullable(dart.wrapType(dart.void_)), dart.wrapType(dart.void_));
  // dynamic* == dynamic
  Expect.identical(legacy(dynamic), dynamic);
  // void* == void
  Expect.identical(
      legacy(dart.wrapType(dart.void_)), dart.wrapType(dart.void_));
}
