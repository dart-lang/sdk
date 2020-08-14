// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library FfiTest;

import 'dart:ffi';
import "package:ffi/ffi.dart";

/// Sample struct for dart:ffi library.
class Coordinate extends Struct {
  @Double()
  external double get x;
  external set x(double v);

  @Double()
  external double get y;
  external set y(double v);

  external Pointer<Coordinate> get next;
  external set next(Pointer<Coordinate> v);

  factory Coordinate.allocate(double x, double y, Pointer<Coordinate> next) {
    return allocate<Coordinate>().ref
      ..x = x
      ..y = y
      ..next = next;
  }
}
