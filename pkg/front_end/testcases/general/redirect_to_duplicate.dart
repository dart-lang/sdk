// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1 {
  C1();
  C1();
  C1.named() : this();
}

class C2 {
  C2.named();
  C2.named();
  C2() : this.named();
}

extension type ET1(int i) {
  ET1(this.i);
  ET1.named(int i) : this(i);
}

extension type ET2.named(int i) {
  ET2.named(this.i);
  ET2(int i) : this.named(i);
}
