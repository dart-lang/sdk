// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class D {
  E v;

  D(this.v);

  static late E staticE;
}

class E {
  G operator +(int i) => new I();
  G operator -(int i) => new I();
}

class F {}

class G extends E implements F {}

class H {}

class I extends G implements H {}

method() {
  F? f = D?.staticE++; // Error
  H? h = ++D?.staticE; // Error
}
