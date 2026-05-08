// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0 {
  this;
}

class C1 {
  this : assert(true);
}

class C2 {
  this {
    print('foo');
  }
}

class C3() {
  this;
  this {
    print('foo');
  }
}

class C4 {
  this;
  this {
    print('foo');
  }
}

enum E0 {
  a;
  this;
}

enum E1 {
  a;
  this : assert(true);
}

enum E2() {
  a;
  this;
  this : assert(true);
}

enum E3() {
  a;
  this;
  this : assert(true);
}

enum E4 {
  a;
  this;
  this : assert(true);
}

extension type ET1(int i) {
  this : assert(i > 0);
  this {
    print('foo');
  }
}
