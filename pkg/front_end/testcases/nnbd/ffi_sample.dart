// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test was adapted from samples/ffi/coordinate.dart

import 'dart:ffi';

import "package:ffi/ffi.dart";

/// Sample struct for dart:ffi library.
final class Coordinate extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  external Pointer<Coordinate> next;

  factory Coordinate.allocate(
      Allocator allocator, double x, double y, Pointer<Coordinate> next) {
    return allocator<Coordinate>().ref
      ..x = x
      ..y = y
      ..next = next;
  }
}

main() {}
