// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

void main() {
  // Does nothing, Native's aren't resolved.
}

@Native<Int Function(Pointer<Int>, Int)>()
external int subtract(Pointer<Int> a, int b);

@Native<Pointer<Double> Function(Pointer<Float>, Pointer<Float>)>()
external Pointer<Double> dividePrecision(Pointer<Float> a, Pointer<Float> b);

@Native<Void Function(Pointer)>(symbol: 'free')
external void posixFree(Pointer pointer);

@Native<Void Function(Pointer)>(symbol: 'CoTaskMemFree')
external void winCoTaskMemFree(Pointer pv);
