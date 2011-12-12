// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Emulates the browser's Float32Array (so Matrix4 can be used outside
 * the browser.
 * (Note this stores entries as 64-bit doubles, since there is no
 * 32-bit float type on the vm.)
 */
class Float32Array {
  final List<double> buf;

  Float32Array(int size) : buf = new List<double>(size) {
    for (int i = 0; i < size; i++) {
      buf[i] = 0.0;
    }
  }

  double operator [](int i) {
    return buf[i];
  }

  void operator []=(int i, num value) {
    buf[i] = (value != null) ? value.toDouble() : 0.0;
  }
}
