// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression check for https://dartbug.com/53968

extension type A(int a) {}

T returnA<T extends A?>() {
  return null as T;
}

void main() {
  returnA();
}
