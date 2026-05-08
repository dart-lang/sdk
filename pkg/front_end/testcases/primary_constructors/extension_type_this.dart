// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET1(int a) {
  this {
    print(a);
  }
}

extension type ET2<T>(T a) {
  this {
    print(a);
    print(T);
  }
}