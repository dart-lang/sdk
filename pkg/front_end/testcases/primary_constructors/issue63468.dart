// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  const new(int x);
}

class const D() extends C {
  this : super(0);
}

class E {
  const new named();
}

class const F() extends E {
  this : super.named();
}

void main() {
  const D();
  const F();
}
