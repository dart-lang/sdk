// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

void main() {
  // Does nothing, FfiNative aren't resolved.
}

@FfiNative<Int Function(Pointer<Int>, Int)>('subtract')
external int subtract(
  Pointer<Int> a,
  int b,
);

@FfiNative<Pointer<Double> Function(Pointer<Float>, Pointer<Float>)>(
    'dividePrecision')
external Pointer<Double> dividePrecision(
  Pointer<Float> a,
  Pointer<Float> b,
);

@FfiNative<Void Function(Pointer)>('free')
external void posixFree(Pointer pointer);

@FfiNative<Void Function(Pointer)>('CoTaskMemFree')
external void winCoTaskMemFree(Pointer pv);
