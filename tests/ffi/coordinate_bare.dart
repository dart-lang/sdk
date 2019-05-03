// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library FfiTestCoordinateBare;

import 'dart:ffi' as ffi;

/// Stripped down sample struct for dart:ffi library.
@ffi.struct
class Coordinate extends ffi.Pointer<ffi.Void> {
  @ffi.Double()
  double x;

  @ffi.Double()
  double y;

  @ffi.Pointer()
  Coordinate next;
}
