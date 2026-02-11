// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart format off

import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class Foo extends Struct {
  @Int32()
  external int? x;
  //       ^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_FIELD_TYPE_IN_STRUCT
  //            ^
  // [cfe] Field 'x' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.
}

void main() {
  final ptr = calloc.allocate<Foo>(sizeOf<Foo>());
  print(ptr.ref.x);
  calloc.free(ptr);
}
