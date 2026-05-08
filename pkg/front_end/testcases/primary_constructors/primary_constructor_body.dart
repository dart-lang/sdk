// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const a = 1;

class C1() {
  this;
}

class C2() {
  this : assert(true);
}

class C3() {
  this {
    print(0);
  }
}

class C4() {
  this : assert(true) {
    print(0);
  }
}

class C5() {
  @a
  this;
}

class C6() {
  @a
  this : assert(true);
}

class C7() {
  @a
  this {
    print(0);
  }
}

class C8() {
  @a
  this : assert(true) {
    print(0);
  }
}