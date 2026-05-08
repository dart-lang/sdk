// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1 {
  factory C1() => throw '';
  C1.named() : this();
}

class C2 {
  factory C2.named() => throw '';
  C2() : this.named();
}

extension type ET1.named(int i) {
  factory ET1(int i) => throw '';
  ET1(int i) : this(i);
}

extension type ET2.other(int i) {
  factory ET2.named(int i) => throw '';
  ET2(int i) : this.named(i);
}
