// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library FfiTestCoordinateManual;

import 'dart:ffi' as ffi;

/// Sample struct for dart:ffi library without use of ffi annotations.
class Coordinate extends ffi.Pointer<ffi.Void> {
  ffi.Pointer<ffi.Double> get _xPtr => cast();
  set x(double v) => _xPtr.store(v);
  double get x => _xPtr.load();

  ffi.Pointer<ffi.Double> get _yPtr =>
      offsetBy(ffi.sizeOf<ffi.Double>() * 1).cast();
  set y(double v) => _yPtr.store(v);
  double get y => _yPtr.load();

  ffi.Pointer<Coordinate> get _nextPtr =>
      offsetBy(ffi.sizeOf<ffi.Double>() * 2).cast();
  set next(Coordinate v) => _nextPtr.store(v);
  Coordinate get next => _nextPtr.load();

  static int sizeOf() =>
      ffi.sizeOf<ffi.Double>() * 2 + ffi.sizeOf<ffi.IntPtr>();

  Coordinate offsetBy(int offsetInBytes) =>
      super.offsetBy(offsetInBytes).cast();

  Coordinate elementAt(int index) => offsetBy(sizeOf() * index);

  static Coordinate allocate({int count: 1}) =>
      ffi.allocate<ffi.Uint8>(count: count * sizeOf()).cast();

  /// Allocate a new [Coordinate] in C memory and populate its fields.
  factory Coordinate(double x, double y, Coordinate next) {
    Coordinate result = Coordinate.allocate()
      ..x = x
      ..y = y
      ..next = next;
    return result;
  }
}
