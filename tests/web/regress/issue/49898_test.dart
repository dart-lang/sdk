// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a regression test for https://github.com/dart-lang/sdk/issues/49898,
/// but ideally we should have a better test that is more general. For example,
/// a test that ensures all patch files also have the same static errors
/// provided as regular sources (the source of the regression is statically
/// detectable).

import 'dart:typed_data';

void main() {
  final a = A(ByteData(10)..setUint16(0, 42));
  print('Number in ByteData: ${a.getUint16()}');
}

class A {
  final ByteData bytes;
  A(ByteData bytes) : bytes = bytes.asUnmodifiableView();

  int getUint16() {
    return bytes.getUint16(0);
  }
}
